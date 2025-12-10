# Saga eXtended Mouse (XMouse)

Ultra-light mouse wheel daemon for Vampire/Apollo SAGA chipset.

> ⚠️ **SAGA Chipset Only**: XMouse works **exclusively** on Apollo accelerators with SAGA chipset and 68080 processor. Not compatible with classic Amiga, other accelerators, or emulators.

## What It Does

XMouse is a background daemon that monitors the SAGA USB mouse wheel counter and injects NewMouse-standard wheel events into the Amiga input system.

## Compatibility

### ✅ Works On (SAGA Chipset with Apollo 68080)
- **A6000 Unicorn** 
- **Vampire V4+ Standalone Firebird**
- **Vampire V4 Icedrake**
- **Vampire V4 Manticore**
- **Vampire V4 Salamander**
- **Vampire V4 Phoenix**
- **USB mouse with scroll wheel (and extras button 4 & 5)**


### ❌ Does NOT Work On
- **Vampire V2** (different chipset, no SAGA support)
- **Classic Amiga** (A500, A1200, A4000, etc.)
- **Emulators** (UAE, WinUAE, FS-UAE)
- **Other accelerators** (Blizzard, Apollo 1260, PiStorm)
- **AmigaOS 4.x, MorphOS, AROS x86**

## Quick Start (30 Seconds)

### Installation
1. Download `xmouse` from [Releases](https://github.com/your-repo/releases)
2. Copy to `C:` or `SYS:C/`

### Start Using
```bash
xmouse              # Start XMouse (that's it!)
```
Your mouse wheel now works. Press CTRL+C to stop, or just reboot.

### Auto-Start on Boot
Add to `S:User-Startup`:
```
xmouse
```

---

## Usage & Configuration

```bash
xmouse              # Toggle (start if stopped, stop if running)
xmouse START        # Start with default config
xmouse STOP         # Stop daemon
```

### Adjusting Scroll Speed

If scrolling is too slow/fast, try these without restarting XMouse:

```bash
xmouse 0x13         # Default (normal - recommended)
xmouse 0x21         # Slower/smoother (20ms)
xmouse 0x31         # Even slower (40ms - better on slow CPU)
xmouse 0x01         # Faster (5ms - may feel jittery)
```

### Debug Mode (Advanced)

To see technical info:
```bash
xmouse 0x93         # Opens debug window with scroll info
```

### Config Byte Reference (Technical)

For developers/advanced users:
- **Bit 0** (0x01): Wheel on/off
- **Bit 1** (0x02): Buttons 4 & 5 on/off
- **Bits 4-5**: Poll speed
  - `00` = 5ms (fast)
  - `01` = 10ms (default)
  - `10` = 20ms (smooth)
  - `11` = 40ms (energy saving)
- **Bit 7** (0x80): Debug mode

## Usage

```bash
xmouse              # Toggle (start if stopped, stop if running)
xmouse START        # Start daemon with default config
xmouse STOP         # Stop daemon
xmouse 0x13         # Start with custom config byte (see below)
```

**Hot config update**: If XMouse is already running, launching with a new config byte will update the settings without restarting:

```bash
xmouse 0x13         # Start with 10ms polling
xmouse 0x21         # Update to 20ms polling (daemon keeps running!)
xmouse 0x93         # Enable debug mode (opens CON: window)
xmouse 0x13         # Disable debug mode (closes CON: window)
```

**Note**: XMouse automatically detaches and runs in background. Use same command to toggle on/off.

### Config Byte (0xBYTE)

You can start XMouse with a custom configuration byte in hexadecimal:

```bash
xmouse 0x13         # Wheel+Buttons, 10ms (default)
xmouse 0x93         # Debug mode + Wheel+Buttons, 10ms
xmouse 0x01         # Wheel only, 5ms (fast)
xmouse 0x21         # Wheel only, 20ms (balanced)
xmouse 0x31         # Wheel only, 40ms (power save)
```

**Config byte format:**
- **Bit 0** (0x01): Wheel enabled (RawKey + NewMouse events)
- **Bit 1** (0x02): Extra buttons 4 & 5 enabled
- **Bits 2-3**: Reserved
- **Bits 4-5**: Poll interval
  - `00` (0x00) = 5ms - Very fast
  - `01` (0x10) = 10ms - Responsive (default)
  - `10` (0x20) = 20ms - Balanced
  - `11` (0x30) = 40ms - Power saving
- **Bit 6**: Reserved
- **Bit 7** (0x80): Debug mode (opens CON: window)

## How It Works (Simple)

```
1. XMouse reads USB wheel counter from SAGA hardware
2. Calculates movement since last check (~10ms)
3. Sends standard scroll commands to Amiga
4. Apps recognize wheel and scroll normally
```

No special software needed in apps - wheel "just works" everywhere.

---

## Comparison: XMouse vs ApolloWheel

| Feature | XMouse | ApolloWheel |
|---------|--------|-------------|
| **Size** | ~7 KB | ~40 KB |
| **CPU Usage** | Ultra-minimal (~0.5%) | Low (~2-3%) |
| **Startup Time** | Instant | Few seconds |
| **Config Changes** | Live update (no restart) | Requires restart |
| **Extra Buttons (4/5)** | ✅ Native support | ✅ Mapped to H-scroll |
| **Scroll Modes** | Wheel only | 3 mode system (cursor/page/wheel) |
| **Code Complexity** | Ultra-simple (dev-friendly) | More complex (powerful) |
| **Memory Leaks** | None | Known memory loss on restart |
| **Approach** | Minimal daemon | Commodity + features |

**Choose XMouse if**: You want lightweight, simple scroll wheel (most users)  
**Choose ApolloWheel if**: You need advanced modes, scroll modes per app (power users)

---

## How It Works (Technical)

1. **Daemon Process**: Creates background process that detaches from shell
2. **Poll Hardware**: Reads SAGA wheel counter at `$DFF213` every 10ms
3. **Calculate Delta**: Computes movement since last read (handles 8-bit wrap-around)
4. **Inject Events**: Sends IECLASS_NEWMOUSE + IECLASS_RAWKEY to input.device

```
Hardware Counter (8-bit) → Delta Calculation → Event Injection
     $DFF213                  processWheel()      injectEvent()
                                                  ↓
                                            input.device
```

**Architecture**:
- Singleton pattern (prevents multiple instances)
- Background daemon (detaches from shell using WBM pattern)
- Direct hardware read (SAGA register $DFF212-$DFF213)
- Event injection (input.device IND_WRITEEVENT)
- Timer-based polling (UNIT_VBLANK, configurable 5-40ms)

**Optimization**:
- Compiled for Apollo 68080 dual-pipe with instruction scheduling
- No stdlib dependency (pure OS calls via VBCC inline pragmas)
- Minimal memory footprint (~7KB)
- No resource leaks on exit

**See [TECHNICAL.md](TECHNICAL.md)** for architecture deep-dive, message port system, and hardware details.

## Building From Source (For Developers)

See [BUILDING.md](BUILDING.md) for compilation instructions.

Quick start:
```bash
./setup.ps1     # One-time: install VBCC + NDK
make            # Compile
```

## License

**MIT License** - Free and open source. Use, modify, and distribute freely.

See [LICENSE](LICENSE) for full legal text.

## Roadmap

See [ROADMAP.md](ROADMAP.md) for detailed timeline.

**Current focus**: v1.0 release (documentation, testing, distribution)
