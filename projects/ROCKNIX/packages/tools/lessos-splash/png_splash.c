#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include "fbsplash.h"
#include "dt_rotation.h"

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

int main(void) {
    const char *fb_device = "/dev/fb0";
    const char *logo_path = "/usr/share/lessos/lessos.png";

    // Check framebuffer device accessibility
    if (access(fb_device, R_OK | W_OK) != 0) {
        fprintf(stderr, "Cannot access %s: %s\n", fb_device, strerror(errno));
        return 1;
    }

    // Initialize framebuffer
    Framebuffer *fb = fb_init(fb_device);
    if (!fb) {
        fprintf(stderr, "Failed to initialize framebuffer\n");
        return 1;
    }

    // Load PNG image
    int width, height, channels;
    unsigned char *img = stbi_load(logo_path, &width, &height, &channels, 3);
    if (!img) {
        fprintf(stderr, "Failed to load PNG: %s\n", stbi_failure_reason());
        fb_cleanup(fb);
        return 1;
    }

    // Clear screen to black
    for (uint32_t y = 0; y < fb->vinfo.yres; y++) {
        for (uint32_t x = 0; x < fb->vinfo.xres; x++) {
            set_pixel(fb, x, y, 0x00000000);
        }
    }

    // Calculate scaling to use max 30% screen width
    float max_width = fb->vinfo.xres * 0.3f;
    float scale = max_width / width;

    // Don't scale up, only down
    if (scale > 1.0f) scale = 1.0f;

    int scaled_width = (int)(width * scale);
    int scaled_height = (int)(height * scale);

    // Calculate centering offsets
    int offset_x = (fb->vinfo.xres - scaled_width) / 2;
    int offset_y = (fb->vinfo.yres - scaled_height) / 2;

    // Draw scaled PNG to framebuffer using nearest-neighbor
    for (int y = 0; y < scaled_height; y++) {
        int src_y = (int)((float)y / scale);
        if (src_y >= height) src_y = height - 1;

        for (int x = 0; x < scaled_width; x++) {
            int src_x = (int)((float)x / scale);
            if (src_x >= width) src_x = width - 1;

            unsigned char *pixel = img + (src_y * width + src_x) * 3;
            uint32_t color = (pixel[0] << 16) | (pixel[1] << 8) | pixel[2];

            int dst_x = x + offset_x;
            int dst_y = y + offset_y;
            if (dst_x < (int)fb->vinfo.xres && dst_y < (int)fb->vinfo.yres) {
                set_pixel(fb, dst_x, dst_y, color);
            }
        }
    }

    // Clean up
    stbi_image_free(img);
    fb_flush(fb);
    fb_cleanup(fb);

    return 0;
}
