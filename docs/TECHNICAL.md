# XMouse Technical Documentation

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Daemon Implementation](#daemon-implementation)
3. [SAGA Hardware Interface](#saga-hardware-interface)
4. [Event Injection](#event-injection)
5. [Timer Implementation](#timer-implementation)
6. [VBCC Inline Pragmas](#vbcc-inline-pragmas)
7. [Daemon Message Port System](#daemon-message-port-system)

## Architecture Overview

### Design Philosophy

XMouse follows the principle of **ultra-light daemon** design:
- Background process with shell detachment
- No dynamic allocations during runtime
- Direct OS calls via VBCC inline pragmas
- Minimal dependencies (exec.library, dos.library, timer.device, input.device)
- Single-threaded event loop
- Singleton pattern via public port

### Execution Flow

```
_start() [launcher process]
  ├─ Initialize SysBase from abs 4
  ├─ Open dos.library
  ├─ Check for existing instance (FindPort)
  │   └─ If exists → Signal CTRL+C and exit
  ├─ CreateNewProcTags(daemon)
  ├─ Detach from shell (cli_Module = 0)
  ├─ Close dos.library
  └─ Return (shell prompt returns)

daemon() [background process]
  ├─ daemonInit()
  │   ├─ Open dos.library
  │   ├─ Create public port (singleton detection)
  │   ├─ Open input.device
  │   ├─ Open timer.device
  │   └─ Initialize lastCounter
  ├─ Start timer
  ├─ Main loop
  │   ├─ Wait(CTRL+C | timer)
  │   ├─ Handle CTRL+C → break
  │   └─ Handle timer
  │       ├─ processWheel()
  │       │   ├─ Read SAGA counter
  │       │   ├─ Calculate delta
  │       │   └─ injectEvent() x2 (NewMouse + RawKey)
  │       └─ Restart timer
  ├─ daemonCleanup()
  │   ├─ Cleanup timer.device
  │   ├─ Cleanup input.device
  │   ├─ Remove public port
  │   └─ Close dos.library
  └─ Process terminates
```

## Daemon Implementation

### Shell Detachment (WBM Pattern)

```c
/* After CreateNewProcTags succeeds */
proc = (struct Process *)FindTask(NULL);
if (proc->pr_CLI)
{
    cli = BADDR(proc->pr_CLI);
    cli->cli_Module = 0;  // Clear CLI module reference
}
// Shell can now terminate without waiting
```

This allows the shell prompt to return immediately while the daemon continues running.

### Singleton Detection

```c
Forbid();
existingPort = FindPort(XMOUSE_PORT_NAME);
if (existingPort)
{
    existingTask = existingPort->mp_SigTask;
    Permit();
    Signal(existingTask, SIGBREAKF_CTRL_C);  // Stop existing
    return RETURN_OK;
}
Permit();
```

Public port ensures only one instance runs. Running again stops the daemon.

## SAGA Hardware Interface

### Wheel Counter Register

**Address**: `$DFF212` (word register) + byte offset +1 = `$DFF213` (byte access)

The SAGA mouse register base is at `$DFF212`. In our code, we access both the wheel and buttons from this address:
```c
#define SAGA_MOUSE_BUTTONS      (*((volatile UWORD*)0xDFF212))        // Full word, bits 8-9 = buttons
#define SAGA_WHEELCOUNTER       (*((volatile BYTE*)0xDFF212 + 1))     // Byte at offset +1 (word address + 1)
```

The wheel counter is in the high byte of the word register (offset +1 in big-endian 68k addressing).

**Properties**:
- 8-bit signed counter (-128 to +127)
- Wraps on overflow (127 → -128, -128 → 127)
- Increments on wheel scroll up
- Decrements on wheel scroll down
- Persistent (driver must track delta manually)

**Reading Pattern**:
```c
BYTE current = SAGA_WHEELCOUNTER;
int delta = (int)(unsigned char)current - (int)(unsigned char)lastCounter;

// Handle wrap-around for signed 8-bit values
if (delta > 127) delta -= 256;
if (delta < -128) delta += 256;

lastCounter = current;  // Always update for next poll
```

### Extra Buttons Register (Bits 8-9)

**Address**: `$DFF212` (word access, bits 8-9)

```c
#define SAGA_MOUSE_BUTTONS (*((volatile UWORD*)0xDFF212))
#define SAGA_BUTTON4_MASK 0x0100  // Bit 8
#define SAGA_BUTTON5_MASK 0x0200  // Bit 9
```

**Properties**:
- Bit 8: Button 4 state (1=pressed, 0=released)
- Bit 9: Button 5 state
- Other bits: reserved

**Change Detection Pattern**:
```c
UWORD current = SAGA_MOUSE_BUTTONS & (SAGA_BUTTON4_MASK | SAGA_BUTTON5_MASK);
UWORD changed = current ^ s_lastButtons;

if (changed & SAGA_BUTTON4_MASK) {
    // Button 4 changed - inject press or release
}
if (changed & SAGA_BUTTON5_MASK) {
    // Button 5 changed - inject press or release
}
s_lastButtons = current;
```

### Hardware Note: Button Register - Official SAGA Specification

✓ **Official SAGA Specification** (from `saga_mousewheel.txt`):

```
Register Address 212    Read/Write   Function: Wheel events
BIT 15-10: unused
BIT 9:     Mouse Button 5
BIT 8:     Mouse Button 4
BIT 7-0:   signed 8-bit wheel counter
```

**XMouse implementation is CORRECT** per official SAGA chipset documentation. The button bits are:
- **Bit 8**: Button 4 state (1=pressed, 0=released)
- **Bit 9**: Button 5 state (1=pressed, 0=released)

⚠️ **Note**: Some reference implementations (e.g., ApolloWheel) use different bit positions (bits 0-1 mapped to horizontal wheel). These implementations may be using non-standard hardware variants or older design documents. XMouse follows the official SAGA specification.

## Event Injection

### Event Buffer and Reuse

To minimize allocations during runtime, XMouse maintains a single static event buffer that is initialized once and reused for all event injections:

```c
static struct InputEvent s_eventBuf;  // Global reusable buffer

// In daemon_Init(): initialize once
s_eventBuf.ie_NextEvent = NULL;
s_eventBuf.ie_SubClass = 0;
s_eventBuf.ie_Qualifier = PeekQualifier();  // Current qualifier state
s_eventBuf.ie_X = 0;
s_eventBuf.ie_Y = 0;
s_eventBuf.ie_TimeStamp.tv_secs = 0;
s_eventBuf.ie_TimeStamp.tv_micro = 0;

// In daemon_processWheel() and daemon_processButtons(): only change ie_Code and ie_Class
s_eventBuf.ie_Code = code;
s_eventBuf.ie_Class = IECLASS_NEWMOUSE;
injectEvent(&s_eventBuf);
```
```

### NewMouse Standard

XMouse injects **both** event types for maximum compatibility:

1. **IECLASS_NEWMOUSE** - NewMouse standard (modern apps: browsers, scrollable widgets)
2. **IECLASS_RAWKEY** - RawKey fallback (legacy apps: Miami, MultiView 37+)

Codes used:
- Wheel: `NM_WHEEL_UP` (0x7A) / `NM_WHEEL_DOWN` (0x7B)
- Button 4: `NM_BUTTON_FOURTH` (0x7E) / release with `IECODE_UP_PREFIX` (0x80)
- Button 5: `NM_BUTTON_FIFTH` (0x7F) / release with `IECODE_UP_PREFIX`

## Timer Implementation

### Timer Interval (Configurable)

Default poll interval is **10ms** (10,000 microseconds), but configurable via config byte to 5ms, 20ms, or 40ms. See README config byte bits 4-5 for details.

### Timer Setup

In `daemonInit()`, timer.device is opened with UNIT_VBLANK for accurate frame-sync timing:

```c
if (OpenDevice(TIMERNAME, UNIT_VBLANK, 
               (struct IORequest *)s_TimerReq, 0)) {
    return FALSE;  // Failed
}
```

### Timer Start (Macro)

```c
#define TIMER_START(micros) \
    s_TimerReq->tr_node.io_Command = TR_ADDREQUEST;  \
    s_TimerReq->tr_time.tv_secs = micros / 1000000;  \
    s_TimerReq->tr_time.tv_micro = micros % 1000000; \
    SendIO((struct IORequest *)s_TimerReq);
```

**Key point**: `SendIO()` is non-blocking - request queued, signal delivered when complete. The main loop sleeps in `Wait()` until timer fires.

## VBCC Inline Pragmas

### How It Works

VBCC generates inline assembly for library calls using offsets defined in proto headers:

```c
CreateMsgPort();  // Becomes: move.l _SysBase,a6; jsr -654(a6)
```

No external libraries needed - direct JSR to library base + offset.

### Requirements

1. Global base pointers initialized:
   ```c
   struct ExecBase *SysBase;
   struct DosLibrary *DOSBase;
   ```

2. Proto headers included:
   ```c
   #include <proto/exec.h>
   #include <proto/dos.h>
   #include <proto/timer.h>
   #include <proto/input.h>
   ```

3. No `-lamiga` linking required
4. -nostdlib required

## Daemon Message Port System

### Public Port (Singleton & IPC)

The daemon creates a public port named `XMOUSE_PORT_NAME` ("XMouse_Port") for inter-process communication:

```c
s_PublicPort = CreateMsgPort();
s_PublicPort->mp_Node.ln_Name = XMOUSE_PORT_NAME;
s_PublicPort->mp_Node.ln_Pri = 0;
AddPort(s_PublicPort);  // Register globally
```

**Dual purpose**:
1. **Singleton detection**: External processes check `FindPort(XMOUSE_PORT_NAME)` to detect running daemon
2. **Runtime control**: Send messages to hot-update configuration without restarting

### Message Protocol

```c
struct XMouseMsg {
    struct Message msg;      // Amiga message header
    UBYTE command;           // Command code (XMSG_CMD_*)
    ULONG value;             // Command parameter
    ULONG result;            // Result/status response
};
```

### Supported Commands

| Command | Purpose | Value Parameter | Response |
|---------|---------|-----------------|----------|
| `XMSG_CMD_QUIT` (0) | Stop daemon | (unused) | 0 = success |
| `XMSG_CMD_SET_CONFIG` (1) | Update config byte | New config byte (0xBYTE) | Updated config byte |
| `XMSG_CMD_SET_INTERVAL` (2) | Change poll interval | Microseconds | New interval value |
| `XMSG_CMD_GET_STATUS` (3) | Query daemon status | (unused) | (config << 16) \| (ms) |

### Example: Runtime Config Update

```c
// From launcher process:
sendDaemonMessage(existingPort, XMSG_CMD_SET_CONFIG, 0x23);  // Wheel ON, buttons ON, 5ms, debug OFF
// Daemon applies new config immediately in next timer tick
// No restart needed
```

### Message Loop in Daemon
- No need to restart daemon for config changes
- Non-blocking: messages processed between timer ticks
- Response-based: caller waits for confirmation

## Debug Mode

### Enabling Debug Console

Set **Bit 7 (0x80)** in config byte to enable debug mode. XMouse will open a CON: window and log all events.

```bash
xmouse 0x93         # Enable: Wheel ON + Buttons ON + 10ms + Debug ON
xmouse 0x13         # Disable: Debug OFF (closes CON: window)
```

### Debug Output

When enabled, the debug console displays:
- Daemon startup messages
- Wheel movement events (delta, direction, count)
- Button press/release events
- Config changes (interval updates, debug mode toggles)
- Timer tick counter (logged every 1000 ticks)

Example output:
```
daemon started
Mode: IECLASS_RAWKEY/NEWMOUSE
Poll interval: 10ms
---
Press Ctrl+C to quit
Wheel: delta=5 dir=UP count=5
Button 4 pressed
Button 4 released
Config updated: interval changed to 20ms
Timer polls: 1000 (interval: 10ms)
```

### Implementation Details

- Debug mode is compile-time controlled via `#ifndef RELEASE`
- `DebugLog()` and `DebugLogF()` macros check `CONFIG_DEBUG_MODE` bit before output
- Debug console opened in `daemon_Init()` when bit 7 is set
- Console closed in `daemon_Cleanup()` or when debug disabled via message

### Development Builds vs Release

- **Development builds** (`make`): Debug macros enabled, small performance impact
- **Release builds** (`make MODE=release`): Debug code compiled out, faster execution

## Future Enhancements



---

**Document Version**: 2.1  
**Last Updated**: December 10, 2025  
**Author**: Vincent Buzzano (ReddoC)
