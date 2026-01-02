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

    // Get rotation from device tree
    int rotation = get_display_rotation();

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

    // Get framebuffer dimensions
    uint32_t fb_width = fb->vinfo.xres;
    uint32_t fb_height = fb->vinfo.yres;

    // For 90/270 degree rotation, swap the logical screen dimensions
    // when calculating image size and centering
    uint32_t screen_width = fb_width;
    uint32_t screen_height = fb_height;
    if (rotation == 90 || rotation == 270) {
        screen_width = fb_height;
        screen_height = fb_width;
    }

    // Calculate scaling to use max 30% screen width
    float max_width = screen_width * 0.3f;
    float scale = max_width / width;

    // Don't scale up, only down
    if (scale > 1.0f) scale = 1.0f;

    int scaled_width = (int)(width * scale);
    int scaled_height = (int)(height * scale);

    // Calculate centering offsets in logical screen space
    int offset_x = (screen_width - scaled_width) / 2;
    int offset_y = (screen_height - scaled_height) / 2;

    // Draw scaled PNG to framebuffer using nearest-neighbor
    for (int y = 0; y < scaled_height; y++) {
        int src_y = (int)((float)y / scale);
        if (src_y >= height) src_y = height - 1;

        for (int x = 0; x < scaled_width; x++) {
            int src_x = (int)((float)x / scale);
            if (src_x >= width) src_x = width - 1;

            unsigned char *pixel = img + (src_y * width + src_x) * 3;
            uint32_t color = (pixel[0] << 16) | (pixel[1] << 8) | pixel[2];

            // Calculate logical destination coordinates
            int logical_x = x + offset_x;
            int logical_y = y + offset_y;

            // Transform to framebuffer coordinates based on rotation
            int fb_x, fb_y;
            switch (rotation) {
                case 90:
                    fb_x = fb_width - 1 - logical_y;
                    fb_y = logical_x;
                    break;
                case 180:
                    fb_x = fb_width - 1 - logical_x;
                    fb_y = fb_height - 1 - logical_y;
                    break;
                case 270:
                    fb_x = logical_y;
                    fb_y = fb_height - 1 - logical_x;
                    break;
                default: // 0 degrees
                    fb_x = logical_x;
                    fb_y = logical_y;
                    break;
            }

            if (fb_x >= 0 && fb_x < (int)fb_width &&
                fb_y >= 0 && fb_y < (int)fb_height) {
                set_pixel(fb, fb_x, fb_y, color);
            }
        }
    }

    // Clean up
    stbi_image_free(img);
    fb_flush(fb);
    fb_cleanup(fb);

    return 0;
}
