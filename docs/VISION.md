# XMouse Vision & Architecture

## Vision

Create the **simplest possible** mouse wheel driver for Vampire/Apollo SAGA:
- Ultra-light (~7KB)
- Transparent to the user
- Rock-solid reliable
- Easy to understand and maintain

**Philosophy**: Do one thing well - read the SAGA wheel counter and inject events.

## Hardware Requirements

### SAGA Chipset Required

XMouse reads SAGA-specific hardware registers (`$DFF212-$DFF213`) that **only exist** on hardware with the SAGA chipset.

**Supported**:
- Vampire V4 Standalone (Apollo 68080 + SAGA)
- Vampire V4 Firebird (Apollo 68080 + SAGA)
- Vampire V4 Icedrake (Apollo 68080 + SAGA)
- Vampire V2 with SAGA (A500/A600/A1200/A2000 accelerators)
- Any future hardware with SAGA chipset and 68080-compatible CPU

**NOT Compatible**:
- Classic Amiga without Vampire (no SAGA registers)
- UAE/WinUAE/FS-UAE emulators (SAGA not emulated)
- Non-SAGA accelerators (Blizzard, PiStorm, etc.)

### What SAGA Already Provides (Hardware)

The SAGA chipset handles basic mouse functions **natively in hardware**:
- Mouse movement (X/Y position)
- Buttons 1, 2, 3 (left, right, middle)

### What XMouse Adds (Software)

XMouse is a **complementary driver** that adds:
- **Wheel support** (scroll up/down) - reads counter at `$DFF213`
- **Buttons 4 & 5** (extra buttons) - reads bits 8-9 at `$DFF212`

> **Note**: XMouse is **optional**. Your mouse works without it - you just won't have wheel or extra buttons.

## How xmouse.c Works

### Program Flow

```
_start()
  ↓
Initialize (SysBase, DOSBase)
  ↓
Parse arguments (config byte)
  ↓
Check singleton (FindPort)
  ↓
CreateNewProcTags(daemon)  → Detach from shell
  ↓
┌─────────────────────────────────────┐
│ DAEMON LOOP (10ms default)          │
│                                     │
│ Wait(CTRL+C | timer | port)         │
│   ↓                                 │
│ CTRL+C? → Exit                      │
│   ↓                                 │
│ Port msg? → Handle command          │
│   ↓                                 │
│ Timer? → processWheel()             │
│        → processButtons()           │
│        → Restart timer              │
└─────────────────────────────────────┘
  ↓
daemonCleanup() (abort timer, close devices, remove port)
  ↓
Exit
```

> **Note**: This flow shows the actual implementation. Timer interval is configurable (5-40ms, default 10ms) via config byte. See [TECHNICAL.md](TECHNICAL.md) for details.

## Architecture Philosophy

XMouse follows these design principles:

### Why Timer-Based Polling?

**Considered**: Interrupt-driven (VBL, hardware IRQ)  
**Chosen**: Timer polling (10ms default, configurable 5-40ms)

**Rationale**:
- Simpler code (no IRQ handler)
- Safer (no race conditions)
- Sufficient for wheel/buttons (not realtime critical)
- Lower system impact
- Configurable responsiveness vs CPU trade-off

### Why VBCC Inline Pragmas?

**Alternative**: Link with `-lamiga` stubs  
**Chosen**: Inline pragmas from VBCC headers

**Benefits**:
- Smaller executable (~200 bytes saved)
- Direct JSR calls via library base
- No external stub overhead
- Fully optimizable
