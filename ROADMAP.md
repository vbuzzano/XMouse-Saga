# []($PROGRAM_NAME)XMouseD[]()

- **Current Version**: v[]($PROGRAM_VERSION)1.0-rc1[]()-RC1
- **Status**: Feature-complete, ready for testing
- **CPU Optimization**: 68080 SAGA chipset with instruction scheduling

---

## ✅ Completed (v1.0)

### Core Functionality
- [x] Wheel UP/DOWN detection from SAGA register (0xDFF213)
- [x] 8-bit signed counter delta calculation with wrap-around handling
- [x] Event injection to input.device (IECLASS_RAWKEY + IECLASS_NEWMOUSE)
- [x] Adaptive polling system (4 modes: COMFORT, BALANCED, REACTIVE, ECO)
- [x] Normal/fixed polling mode (bit 6: MODERATE 20ms, ACTIVE 10ms, INTENSIVE 5ms, PASSIVE 40ms)
- [x] Background daemon with proper detachment (WBM pattern)
- [x] Singleton detection via public port
- [x] Toggle start/stop mechanism
- [x] Extra buttons 4 & 5 implementation (bits 8-9 at 0xDFF212)

### Configuration System
- [x] Config byte format (0xBYTE)
  - [x] Bit 0: Wheel enable/disable
  - [x] Bit 1: Extra buttons 4 & 5 enable/disable
  - [x] Bits 4-5: Mode selection (4 modes)
  - [x] Bit 6: Adaptive (0) vs Normal (1) mode
  - [x] Bit 7: Debug mode (DEV builds only)
- [x] Hot config update via message port (no restart needed)
- [x] Command line parsing (START, STOP, STATUS, 0xBYTE)
- [x] Message port infrastructure with timeout (2s)
- [x] STATUS command (returns config byte, WARN if not running)
- [x] Debug mode with CON: window (closes immediately on toggle off)

### Code Quality
- [x] Compact executable (~6KB release, ~7.5KB dev)
- [x] No stdlib dependency
- [x] Proper resource cleanup
- [x] VBCC inline pragmas for direct OS calls
- [x] Message constants for all user output
- [x] 68080-optimized with instruction scheduling
- [x] Debug bit filtering in RELEASE builds

---

## 🚧 Next Steps (Before v1.0 Final)

### Hardware Testing (Critical)
- [x] Test on real Vampire V4 hardware
- [x] Verify wheel detection and event injection
- [ ] Test buttons 4 & 5 functionality  
- [x] Test all 8 modes (4 adaptive + 4 normal)
- [x] Test hot config changes (especially debug mode toggle)
- [x] Verify adaptive polling behavior under load
- [ ] Long-running stability test (24h+)

**Priority**: CRITICAL - Required before release  
**Status**: 85% complete - buttons 4/5 and stability test pending  
**Effort**: 2-4 hours remaining

### Documentation
- [ ] **AmigaGuide manual** (`XMouseD.guide`)
  - [ ] Update with adaptive polling documentation
  - [ ] Document all 8 modes with use cases
  - [ ] Hot config examples
  - [ ] STATUS command documentation
  - [ ] Debug mode usage (DEV builds)
- [x] **README.md updates**
- [ ] **CHANGELOG.md**
  - [ ] Document all v1.0 features
  - [ ] List breaking changes if any

**Priority**: HIGH - Required for release  
**Effort**: 4-6 hours

---

## 📋 Distribution (v1.0 Final)

### Package Contents
- [ ] **Installer script** (AmigaOS Installer)
  - [ ] Copy `XMouseD` to C:
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
  - [ ] XMouseD.guide
  - [ ] Installer script
  - [ ] Binary (XMouseD)
  - [ ] Source code
  - [ ] LICENSE

**Priority**: HIGH - Required for release  
**Effort**: 6-8 hours

---

## 🎯 Future Enhancements (v1.1+)

### CLI Control Utility (v1.1)
- [ ] **XMouseCtrl** companion tool
  - [ ] Query daemon status with formatted output
  - [ ] Change config on the fly
  - [ ] Show current mode name
  - [ ] Display adaptive state (if in adaptive mode)
  - [ ] Enable/disable features individually

**Rationale**: User-friendly interface for advanced configuration  
**Priority**: MEDIUM - Nice to have  
**Effort**: 4-6 hours

### Additional Features
- [ ] Configurable qualifier support (shift/ctrl/alt + wheel)
- [ ] Horizontal wheel support (if SAGA adds register)
- [ ] Preferences editor (MUI/Reaction GUI)

---

## 🚀 Release Checklist

### Version 1.0 Requirements

#### Must Have ✓
- [x] Wheel UP/DOWN working
- [x] Buttons 4 & 5 implemented
- [x] Adaptive polling system
- [x] Hot config update
- [x] STATUS command
- [ ] Tested on real hardware
- [ ] AmigaGuide documentation updated
- [ ] Installer script
- [ ] LhA archive ready for distribution

#### Should Have
- [ ] WBStartup auto-start support
- [ ] Config byte examples in guide
- [ ] Troubleshooting section
- [ ] FAQ with common issues

#### Nice to Have
- [ ] CLI control utility (XMouseCtrl)
- [ ] Video demo/tutorial
- [ ] Aminet README (.readme file)

---

## 📊 Progress Summary

| Component | Status | Notes |
|-----------|--------|-------|
| Core wheel detection | ✅ Done | Tested on V4 hardware |
| Extra buttons 4 & 5 | 🔶 Partial | Code done, hardware test pending |
| Adaptive polling | ✅ Done | All 4 modes verified on V4 |
| Normal/fixed mode | ✅ Done | All 4 intervals verified |
| Hot config update | ✅ Done | Tested on V4, no restart needed |
| STATUS command | ✅ Done | Returns WARN if not running |
| Debug mode | ✅ Done | Console toggle tested on V4 |
| Message constants | ✅ Done | Clean code organization |
| Hardware testing | 🔶 85% | Wheel/modes OK, buttons pending |
| Documentation | ⏳ Pending | 4-6 hours work |
| Distribution | ⏳ Pending | 6-8 hours work |

**Overall Progress**: ~90% complete for v1.0 Final

---

## 🎉 Version 1.0 Ready When

1. ✅ Wheel working perfectly (verified on V4)
2. 🔶 Buttons 4 & 5 implemented (code done, test pending)
3. ✅ Adaptive polling system (verified on V4)
4. ✅ Hot config update (verified on V4)
5. 🔶 Tested on real Vampire V4 (85% complete)
6. ⬜ AmigaGuide documentation updated
7. ⬜ Installer script working
8. ⬜ LhA archive ready for Aminet

**Estimated completion**: 1 week (documentation + distribution packaging)
