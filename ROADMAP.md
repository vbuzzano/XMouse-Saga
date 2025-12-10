# XMouse Roadmap

**Current Version**: v0.1 (~5.5KB, 75% toward v1.0)  
**Target**: Production-ready release for Vampire/Apollo users  
**CPU Optimization**: 68080 SAGA chipset with instruction scheduling

---

## ✅ Completed (Current: v0.1)

### Core Functionality
- [x] Wheel UP/DOWN detection from SAGA register (0xDFF212)
- [x] 8-bit counter delta calculation with wrap-around handling
- [x] Event injection to input.device (IECLASS_RAWKEY + IECLASS_NEWMOUSE)
- [x] Timer-based polling (configurable: 5/10/20/40ms via UNIT_VBLANK)
- [x] Background daemon with proper detachment (WBM pattern)
- [x] Singleton detection via public port
- [x] Toggle start/stop mechanism

### Configuration System
- [x] Config byte format (0xBYTE)
  - [x] Bit 0: Wheel enable/disable
  - [x] Bit 1: Extra buttons enable/disable
  - [x] Bits 4-5: Poll interval (4 levels)
  - [x] Bit 7: Debug mode
- [x] Command line parsing (START, STOP, 0xBYTE)
- [x] Message port infrastructure for daemon control
- [x] Debug mode with CON: window output

### Code Quality
- [x] Compact executable (~5.5KB with -size optimization)
- [x] No stdlib dependency
- [x] Proper resource cleanup
- [x] VBCC inline pragmas for direct OS calls
- [x] Comment style standardization (`//` for active code)
- [x] 68080-optimized with instruction scheduling

---

## 🚧 In Progress (v0.2)

### Extra Buttons Implementation
- [ ] Read bits 8-9 from 0xDFF212 (buttons 4 & 5 state)
- [ ] Track button state changes (press/release)
- [ ] Inject IECLASS_RAWMOUSE button events
- [ ] Add `processButtons()` function in daemon loop
- [ ] Test button events with applications

**Status**: Hardware ready, needs code implementation  
**Priority**: HIGH - Advertised feature  
**Effort**: 2-4 hours

---

## 📋 TODO for v1.0 Release

### Documentation (v0.3)
- [ ] **AmigaGuide manual** (`XMouse.guide`)
  - [ ] Installation instructions
  - [ ] Usage examples (command line options)
  - [ ] Config byte reference table
  - [ ] Troubleshooting section
  - [ ] Technical details (SAGA register, event codes)
  - [ ] FAQ
- [ ] **README.md updates**
  - [ ] Installation section
  - [ ] Config byte examples
  - [ ] Extra buttons documentation
- [ ] **History file** (plain text changelog for Aminet)

**Priority**: HIGH - Required for distribution  
**Effort**: 4-6 hours

### Distribution (v0.4)
- [ ] **Installer script** (AmigaOS Installer)
  - [ ] Copy `xmouse` to C:
  - [ ] Create WBStartup drawer
  - [ ] Install icon with ToolTypes
  - [ ] Copy documentation
  - [ ] Optional: Add to User-Startup
- [ ] **Icons**
  - [ ] Program icon (Workbench launch)
  - [ ] Documentation icon (.guide)
  - [ ] ToolTypes for config byte
- [ ] **LhA archive** for Aminet
  - [ ] README
  - [ ] XMouse.guide
  - [ ] Installer script
  - [ ] Binary (xmouse)
  - [ ] Source code
  - [ ] LICENSE

**Priority**: HIGH - Required for release  
**Effort**: 6-8 hours

### Testing (v0.5)
- [ ] Test on real Vampire V4 hardware
- [ ] Test wheel in various applications (Workbench, browsers, editors)
- [ ] Test buttons 4 & 5 functionality
- [ ] Test all config byte combinations
- [ ] Test debug mode output
- [ ] Test WBStartup auto-start
- [ ] Stress test (long running daemon stability)

**Priority**: HIGH - Quality assurance  
**Effort**: 4-6 hours

---

## 🎯 Future Enhancements (v1.1+)

### Idle Mode (v1.1)
- [ ] **Progressive interval increase on inactivity**
  - [ ] Config byte bit 2 (mask 0x04) to enable/disable idle mode
  - [ ] Gradually increase poll interval when no wheel/button activity detected
  - [ ] Return to configured interval when activity resumes
  - [ ] Default behavior: 2x-4x multiplier with configurable enable / disable via config bit
  - [ ] Benefits: Reduce CPU usage during idle periods
  - [ ] Transparent to user: interval change imperceptible (< 100ms variance)

**Rationale**: Save CPU when mouse not in use, restore responsiveness instantly on activity  
**Status**: Design phase  
**Priority**: MEDIUM - Nice optimization  
**Effort**: 4-6 hours



---

## 🚀 Release Checklist

### Version 1.0 Requirements

#### Must Have ✓
- [x] Wheel UP/DOWN working
- [ ] Buttons 4 & 5 working
- [ ] AmigaGuide documentation
- [ ] Installer script
- [ ] Workbench icons with ToolTypes
- [ ] Tested on real hardware
- [ ] LhA archive ready for distribution

#### Should Have
- [ ] WBStartup auto-start
- [ ] Config byte examples in guide
- [ ] Troubleshooting section
- [ ] FAQ with common issues

#### Nice to Have
- [ ] CLI control utility (XMouseCtrl)
- [ ] Video demo/tutorial
- [ ] Aminet README (.readme file)

---

## 📊 Effort Summary

| Phase | Description | Hours | Status |
|-------|-------------|-------|--------|
| v0.1 | Core wheel functionality | 20 | ✅ Done |
| v0.2 | Extra buttons | 2-4 | 🚧 In progress |
| v0.3 | Documentation | 4-6 | ⏳ Pending |
| v0.4 | Distribution | 6-8 | ⏳ Pending |
| v0.5 | Testing | 4-6 | ⏳ Pending |
| **Total v1.0** | **Production release** | **36-44** | **75% complete** |

---

## 🎉 Version 1.0 Ready When

1. ✅ Wheel working perfectly
2. ⬜ Buttons 4 & 5 implemented
3. ⬜ AmigaGuide documentation complete
4. ⬜ Installer script working
5. ⬜ Icons with proper ToolTypes
6. ⬜ Tested on real Vampire V4
7. ⬜ LhA archive ready for Aminet

**Estimated completion**: 2-3 weeks of part-time work
