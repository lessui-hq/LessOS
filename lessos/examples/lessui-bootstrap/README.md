# LessUI Bootstrap for LessOS

This is an example bootstrap script that LessUI would include in its release package.

## How It Works

1. User extracts LessUI to SD card, creating:
   ```
   /storage/
   ├── .lessui/
   │   └── boot.sh          ← This script
   ├── .system/
   │   ├── rg35xxplus/
   │   │   └── bin/minui.elf
   │   ├── rgb30/
   │   └── ...
   ├── Roms/
   └── Bios/
   ```

2. LessOS boots and runs its launcher script
3. LessOS finds `.lessui/boot.sh` and executes it
4. This script maps the device to a LessUI platform and launches minui.elf

## Environment Variables from LessOS

| Variable | Description | Example |
|----------|-------------|---------|
| `LESSOS_VERSION` | LessOS version | `1.0.0` |
| `LESSOS_HW_DEVICE` | Hardware platform | `H700`, `RK3566` |
| `LESSOS_HW_ARCH` | CPU architecture | `aarch64`, `arm` |
| `LESSOS_DEVICE_MODEL` | Device model from DT | `Anbernic RG35XX Plus` |
| `LESSOS_STORAGE` | Storage mount point | `/storage` |
| `LESSOS_EXTERNAL` | External SD mount | `/storage/games-external` |
| `LESSOS_BOOT_SOURCE` | Where bootstrap found | `internal`, `external` |

## Integration with LessUI

This `boot.sh` would be included in LessUI releases at `.lessui/boot.sh`. The LessUI build process would need to:

1. Create the `.lessui/` directory in the release
2. Include this `boot.sh` script
3. Ensure it's executable

Then LessUI works on LessOS with no additional setup.
