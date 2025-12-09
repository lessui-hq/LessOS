# LessOS Development Files

This directory contains all LessOS-specific code, documentation, and configuration.

## Structure

```
lessos/
├── README.md                    # This file
├── INVESTIGATION.md             # Detailed ROCKNIX build system analysis
├── README-LessOS.md             # LessOS project overview
├── build-lessos.sh              # Build script (applies patches and builds)
│
├── lessui/                      # Bootstrap launcher package
│   ├── package.mk               # Package definition
│   ├── scripts/
│   │   └── start_lessui.sh      # LessOS bootstrap launcher
│   ├── system.d/
│   │   └── lessui.service       # SystemD service
│   └── autostart/
│       └── 099-lessui           # Autostart hook
│
├── examples/
│   └── lessui-bootstrap/
│       ├── boot.sh              # Example LessUI bootstrap for LessOS
│       └── README.md
│
└── patches/
    ├── README.md
    └── packages/virtual/image/
        └── add-lessui-support.patch
```

## Installation

The `lessui` package needs to be symlinked into the ROCKNIX package tree:

```bash
ln -s lessos/lessui projects/ROCKNIX/packages/ui/lessui
```

## Patches

Patches in `patches/` need to be applied before building. See `patches/README.md` for details.

Currently we have one patch that needs to be applied manually:
- `packages/virtual/image/add-lessui-support.patch` - Adds LESSUI_SUPPORT option

## Distribution

The LessOS distribution config is at:
```
distributions/LessOS/
```

This is kept in the standard distributions directory (not in lessos/) because that's where ROCKNIX expects it.
