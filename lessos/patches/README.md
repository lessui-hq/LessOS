# LessOS Patches

This directory contains patch files that modify upstream ROCKNIX code.

## Why Patches?

We don't modify ROCKNIX files directly. Instead, we create `.patch` files that are applied at build time. This ensures:

1. Clean separation between upstream and our changes
2. Easy merges when ROCKNIX updates
3. Clear visibility into what we've changed

## Patch Organization

```
patches/
├── scripts/
│   └── mkimage-exfat.patch       # exFAT storage partition
└── projects/ROCKNIX/packages/
    └── sysutils/busybox/
        ├── fs-resize-exfat.patch # exFAT resize handling
        └── init-exfat.patch      # exFAT mount options
```

## Applying Patches

Before building:

```bash
# Apply all patches
for patch in patches/**/*.patch; do
  echo "Applying: $patch"
  git apply "$patch"
done
```

Or use the build script:

```bash
./lessos/build.sh H700
```

## Creating New Patches

1. Make your change to the upstream file
2. Generate a patch:
   ```bash
   git diff path/to/file > patches/path/to/file.patch
   ```
3. Reset the file:
   ```bash
   git checkout path/to/file
   ```

## Current Patches

| Patch | Purpose | Status |
|-------|---------|--------|
| `packages/virtual/image/add-lessui-support.patch` | Add LESSUI_SUPPORT option to include lessui package | DONE |
| `scripts/mkimage-exfat.patch` | Use exFAT for storage partition | TODO |
| `busybox/fs-resize-exfat.patch` | Handle exFAT resize on first boot | TODO |
| `busybox/init-exfat.patch` | Mount storage as exFAT | TODO |
