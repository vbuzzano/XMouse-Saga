# Saga eXtended Mouse (XMouse)

Minimal, efficient mouse wheel daemon (7.4 KB) for Vampire/Apollo SAGA chipset.

XMouse is a lightweight background daemon that monitors USB mouse wheel and button movements from the SAGA chipset hardware, then injects standard NewMouse-compatible scroll events into the Amiga input system. This allows any Amiga application to scroll using your mouse wheel without special drivers or modifications.

## Compatibility

### ✅ Works On (SAGA Chipset with Apollo 68080)

- **A6000 Unicorn**
- **Vampire V4+ Standalone Firebird**
- **Vampire V4 Icedrake**
- **Vampire V4 Manticore**
- **Vampire V4 Salamander**
- **Vampire V4 Phoenix**

Requires USB mouse with scroll wheel (and extra buttons 4 & 5) connected to the mouse USB port.


### ✅ Compatible & Recommended OS
- **ApolloOS 9.x** (AROS-based, fully compatible)
- **AmigaOS 3.2** (recommended)
- **AmigaOS 3.9** (with NDK 3.9 libraries)
- **AROS** (should work, ApolloOS is AROS-based)


### ❌ Does NOT Work On
- **Vampire V2** (SAGA exists but no USB port for mouse hardware support)
- **Classic Amiga** (A500, A1200, A4000, etc.)
- **Emulators** (UAE, WinUAE, FS-UAE)
- **Other accelerators** (Blizzard, Apollo 1260, PiStorm)
- **AmigaOS 4.x, MorphOS, AROS x86**

> **SAGA Chipset Only**: XMouse works exclusively on Apollo accelerators with SAGA chipset and 68080 processor. Not compatible with classic Amiga, other accelerators, or emulators. 


## Installation

[FAIRE UN PETIT TEXTE: installation très simple en utilisant Install ou en manuellement]

1. Download `xmouse` from [Releases](https://github.com/your-repo/releases)
2. Copy to `C:` (or `SYS:C/`)
3. Add to `S:User-Startup`:
   ```
   xmouse
   ```
4. Restart or run `xmouse` manually

Your mouse wheel now works in all applications. Press CTRL+C to stop, or just reboot.

**Note**: Future versions will include an Installer script. For now, manual setup via User-Startup.

---

## Usage & Configuration

### Basic Commands

```bash
xmouse              # Toggle (start if stopped, stop if running)
xmouse START        # Start with default config (wheel+buttons, 10ms)
xmouse STOP         # Stop daemon gracefully
xmouse 0xBYTE       # Start with custom config byte
```

### Adjusting Scroll Speed

If scrolling is too slow or too fast, adjust polling interval without restarting:

```bash
xmouse 0x13         # Default speed (10ms - recommended)
xmouse 0x21         # Slower/smoother (20ms)
xmouse 0x31         # Even slower (40ms - better on slow CPU)
xmouse 0x01         # Faster (5ms - may feel jittery)
```

### Hot Config Update

If XMouse is already running, launch with a new config byte to update settings instantly:

```bash
xmouse 0x13         # Start daemon or update config
xmouse 0x21         # Update to 20ms (no restart needed!)
xmouse 0x93         # Enable debug mode
xmouse 0x13         # Disable debug mode
xmouse 0x00         # Stop daemon
```

### Command Arguments

| Argument | Effect |
|----------|--------|
| *(none)* | Toggle: start if stopped, stop if running |
| `START` | Start daemon with default config (0x13) |
| `STOP` | Stop daemon gracefully |
| `0xBYTE` | Start with custom config (hex format) |

### Config Byte Reference

Advanced users can customize behavior with a 2-digit hex byte:

```
Bit 0 (0x01)     - Wheel enabled (sends scroll events)
Bit 1 (0x02)     - Extra buttons 4 & 5 enabled
Bits 2-3         - Reserved
Bits 4-5         - Poll speed:
                   00 = 5ms   (fast, may use more CPU)
                   01 = 10ms  (default, balanced)
                   10 = 20ms  (smooth, efficient)
                   11 = 40ms  (power saving)
Bit 6            - Reserved
Bit 7 (0x80)     - Debug mode (opens debug console)
```

**Examples:**
- `0x13` = Wheel ON, Buttons ON, 10ms (default)
- `0x93` = Same but with debug console
- `0x01` = Wheel only, 5ms (no buttons)
- `0x21` = Wheel only, 20ms polling


## How It Works (Simple)

```
1. XMouse reads USB wheel counter from SAGA hardware
2. Calculates movement delta (~10ms per poll)
3. Sends standard scroll commands to Amiga
4. Apps recognize wheel and scroll normally
```

No special software in apps needed - wheel "just works" everywhere.


## Roadmap & Future Plans

See [ROADMAP.md](ROADMAP.md) for detailed timeline.


## Building From Source

See [BUILDING.md](BUILDING.md) for detailed compilation instructions.

**Quick start:**
```bash
./setup.ps1               # One-time: install VBCC + NDK + Thirds
make build MODE=release   # Build release (debug code removed)
```

For architecture details and debug console information, see [TECHNICAL.md](docs/TECHNICAL.md).


## License

**MIT License** - Free and open source. Use, modify, and distribute freely.

See [LICENSE](LICENSE) for full legal text.

---

## Support & Feedback

Found a bug? Have a feature request? Open an issue on GitHub or reach out to the Apollo community Discord.

**Author:** Vincent Buzzano (ReddoC)  
**Version:** 1.0-beta1  
**Updated:** December 10, 2025

