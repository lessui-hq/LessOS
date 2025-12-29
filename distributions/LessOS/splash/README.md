# LessOS Boot Splash Images

Add PNG splash images at these resolutions:

| File | Resolution | Aspect |
|------|------------|--------|
| `splash-720.png` | 1280x720 | 16:9 |
| `splash-768.png` | 1024x768 | 4:3 |
| `splash-1080.png` | 1920x1080 | 16:9 |
| `splash-1200.png` | 1920x1200 | 16:10 |
| `splash-2160.png` | 3840x2160 | 16:9 (4K) |

Optional:
- `boot-logo.bmp.gz` - U-boot splash (gzip-compressed BMP)

The `rocknix-splash` tool will pick the appropriate image based on display resolution.
