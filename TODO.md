# LessOS Build - RESOLVED

## Build Status: ✅ SUCCESS

Build command:
```bash
CONCURRENCY_MAKE_LEVEL=8 make docker-LessOS-RK3566
```

Output files in `target/`:
- `LessOS-RK3566.aarch64-YYYYMMDD-Generic.img.gz`
- `LessOS-RK3566.aarch64-YYYYMMDD-Specific.img.gz`

## Fixes Applied

### 1. Environment Variable Pollution (scripts/get_env)
**Problem:** Host env vars like `CLAUDECODE=1`, `DEFAULT_PYTHON_VERSION` were polluting Docker builds.

**Fix:** Created explicit `docker-LessOS-%` targets in Makefile that:
- Write an empty `.env` file (just a comment)
- Run Docker without any host environment variables
- Override the generic `docker-%` pattern which copies ALL host env vars

This keeps `scripts/get_env` unmodified (matching upstream ROCKNIX).

### 2. Clock Skew (WSL2 issue)
**Problem:** Docker container timestamps were "in the future" causing build failures.

**Fix:** Sync WSL2 clock before building. In WSL2:
```bash
sudo hwclock -s
# or restart WSL if that doesn't work
```

### 3. Parallel Build Race Conditions
**Problem:** High concurrency caused "Text file busy" errors.

**Fix:** Use `CONCURRENCY_MAKE_LEVEL=8` (or lower) instead of auto-detected 32 cores.

### 4. Missing exfatprogs:host
**Problem:** `mkfs.exfat` not found during image creation.

**Fix:** Added `PKG_DEPENDS_HOST="ccache:host"` to `packages/sysutils/exfatprogs/package.mk`
and added `exfatprogs:host` to LessOS image dependencies in `projects/ROCKNIX/packages/virtual/image/package.mk`.

### 5. losetup/mount Permission Denied
**Problem:** Docker container couldn't use losetup/mount for exFAT population.

**Fix:** Modified `scripts/mkimage` to create empty exFAT partition. LessUI files are staged in
`/usr/share/lessui` and copied to storage on first boot by `lessos-boot` service.

### 6. Empty lessui sources directory
**Problem:** `cp sources/*` failed on empty directory.

**Fix:** Added `README` placeholder file to `projects/ROCKNIX/packages/lessui/sources/`.

## Files Modified (ROCKNIX shared files)
- `Makefile` - 2 lines: `-include Makefile.lessos`
- `scripts/mkimage` - exFAT support for LessOS
- `packages/sysutils/exfatprogs/package.mk` - Add host build support
- `projects/ROCKNIX/packages/virtual/image/package.mk` - Include lessos package
- `projects/ROCKNIX/packages/virtual/initramfs/package.mk` - Use plymouth-lite for LessOS splash
- `projects/ROCKNIX/packages/sysutils/busybox/scripts/init` - Flexible splash binary (ply-image or rocknix-splash)

## Files Added (LessOS-specific)
- `Makefile.lessos` - All LessOS build targets (clean Docker env)
- `distributions/LessOS/*` - Distribution config
- `projects/ROCKNIX/packages/lessos/*` - Boot system package
- `projects/ROCKNIX/packages/lessui/*` - LessUI staging package

---

## TODO: Minimize ROCKNIX Modifications

**Goal:** Make it easier to stay up-to-date with upstream ROCKNIX by reducing direct file modifications. Use patches and overrides instead so changes are self-documenting.

### Current Modified ROCKNIX Files (6)

| File | Change Type | Proposed Approach |
|------|-------------|-------------------|
| `Makefile` | +2 lines (include Makefile.lessos) | **Keep as-is** - minimal, just an include |
| `scripts/mkimage` | +38/-18 (exFAT support) | **Patch** - create `distributions/LessOS/patches/mkimage.patch` |
| `packages/sysutils/exfatprogs/package.mk` | +1 line (host deps) | **Patch** |
| `projects/ROCKNIX/packages/virtual/image/package.mk` | +3 lines (lessos pkg) | **Patch** |
| `projects/ROCKNIX/packages/virtual/initramfs/package.mk` | +5 lines (plymouth-lite) | **Patch** |
| `projects/ROCKNIX/packages/sysutils/busybox/scripts/init` | +5 lines (flexible splash) | **Patch** - backwards compatible |

### Implementation Plan

1. **Create patches directory:**
   ```
   distributions/LessOS/patches/
   ├── mkimage.patch
   ├── image-package.patch
   └── exfatprogs.patch  (or try to upstream this fix)
   ```

2. **Add patch application mechanism:**
   - Option A: Script that applies patches before build
   - Option B: Hook into existing ROCKNIX patch system

3. **Revert direct modifications** to ROCKNIX files and apply patches instead

### Benefits
- `git diff next...lessos` will show mostly new files in `distributions/LessOS/`
- Easier to review what we've changed
- Merge conflicts with upstream become patch conflicts (easier to resolve)
- Self-documenting: patches explain exactly what we need and why

### Notes
- Wait until build is tested and stable before creating patches
