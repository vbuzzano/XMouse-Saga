# Next - Post v1.0 Release Tasks

## ✅ Completed for v1.0
- [x] Wheel scrolling (UP/DOWN)
- [x] Extra buttons 4 & 5 support
- [x] Adaptive polling system (8 modes)
- [x] Hot config update (no restart)
- [x] Debug mode toggle
- [x] Message timeout fix (2s)
- [x] Button-hold reactive fix
- [x] Full documentation (README, .guide, .readme)
- [x] Installer script
- [x] CHANGELOG.md

---

## 📋 TODO Before v1.0 Release

### Critical - Documentation Placeholders
- [ ] **Run `.\scripts\env-replace.ps1`** on all files before release
  - [ ] README.md
  - [ ] XMouseD.guide
  - [ ] XMouseD.readme
  - [ ] CHANGELOG.md
  - [ ] Install
  - [ ] docs/TECHNICAL.md
  - [ ] docs/VISION.md
  
  Format: `~ VALUE [VAR_ENV_NAME]~` → actual values

### Critical - Version Consistency
- [ ] **Verify all version strings match `1.0`**:
  - [ ] src/xmoused.c: `PROGRAM_VERSION "1.0"`
  - [ ] src/xmoused.c: `PROGRAM_DATE "2025-12-17"` (update to release date)
  - [ ] CHANGELOG.md: move `[Unreleased]` to `[1.0.0]` with date
  - [ ] All docs using placeholders (will be updated by env-replace)

### Critical - Build & Test
- [ ] **Clean build**: `make clean && make MODE=release`
- [ ] **Size check**: executable should be ~6KB
- [ ] **Test on real Vampire V4**: All modes, wheel, buttons 4/5
- [ ] **Test hot config**: mode switching without restart
- [ ] **Test Installer script**: Full install path

### Critical - Release Package
- [ ] **Run `.\scripts\build-release.ps1`** to create LHA archive
- [ ] **Verify archive structure**:
  ```
  XMouseD-1.0.lha
    + XMouseD-1.0/
       - Install
       - Install.info
       - XMouseD (executable, no .exe extension!)
       - XMouseD.guide
       - XMouseD.guide.info
    - XMouseD-1.0.info
    - XMouseD-1.0.readme
    - XMouseD-1.0.readme.info
  ```
- [ ] **Test extraction and install from archive**

### Optional - Cleanup
- [ ] **Archive or delete ROADMAP.md** (obsolete now)
- [ ] **Move Next.md tasks to GitHub Issues** (for v1.1+ tracking)

---

## 🚀 Future Ideas (v1.1+)

### Dynamic Wheel Acceleration (Branch: `test_dynamic_scroll`)
Use bit 2 or bit 3 for dynamic multiplier feature:
- Detect scroll burst (fast consecutive wheel events)
- Auto-increase multiplier (1x → 2x → 4x) during burst
- Auto-decrease on slow scroll
- Timeout reset after 300ms idle

**Use case**: Long file lists in DirectoryOpus/editors - scroll faster to reach bottom quickly

**Status**: Experimental branch created, needs refinement and testing

### Button Hold Issue Investigation
When button 4/5 is held down:
- Adaptive polling may consider it "inactive" after threshold
- Transitions to TO_IDLE state
- Release detection might be delayed

**Solution options**:
- Keep polling active while any button pressed
- Add button state to activity detection
- Test real-world impact first

---

## 📝 Release Checklist Summary

1. ✅ Code complete and tested
2. ⚠️ **Run env-replace.ps1** on all docs
3. ⚠️ **Update PROGRAM_DATE** to release date
4. ⚠️ **Move CHANGELOG [Unreleased] → [1.0.0]**
5. ⚠️ **Clean build MODE=release**
6. ⚠️ **Test on real hardware**
7. ⚠️ **Run build-release.ps1**
8. ⚠️ **Verify LHA structure**
9. ✅ Git tag `v1.0.0`
10. ✅ GitHub release with LHA attachment



