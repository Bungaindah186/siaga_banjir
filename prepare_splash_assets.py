from math import sqrt
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageFilter


source = Image.open(
    r"E:\Flutter project\docs\reference\1. Mobile-Logo.png"
).convert("RGB")
output = Path("assets/splash")
output.mkdir(parents=True, exist_ok=True)

navy = (24, 48, 87)
teal = (18, 128, 154)


def extract_foreground(box, colors, filename):
    crop = source.crop(box)
    result = Image.new("RGBA", crop.size, (0, 0, 0, 0))
    src = crop.load()
    dst = result.load()
    for y in range(crop.height):
        for x in range(crop.width):
            pixel = src[x, y]
            distance = min(
                sqrt(sum((pixel[channel] - color[channel]) ** 2 for channel in range(3)))
                for color in colors
            )
            if distance < 165:
                alpha = round(255 * max(0, min(1, 1 - distance / 190)))
                dst[x, y] = (*pixel, alpha)
    result.save(output / filename)
    return result


logo = extract_foreground((72, 282, 322, 512), [navy, teal], "home_water_logo.png")
title = extract_foreground((82, 518, 320, 550), [navy], "welcome_title.png")

# Use the same screenshot photo for the backdrop. Remove only the foreground
# brand pixels so the original logo and title can animate independently.
background = source.crop((0, 37, source.width, source.height))
foreground_mask = Image.new("L", source.size, 0)
for layer, box in ((logo, (72, 282, 322, 512)), (title, (82, 518, 320, 550))):
    alpha = layer.getchannel("A").point(lambda value: 255 if value > 12 else 0)
    foreground_mask.paste(alpha, box[:2])
mask = np.array(foreground_mask.crop((0, 37, source.width, source.height)))
mask = cv2.dilate(mask, np.ones((9, 9), np.uint8), iterations=1)
cleaned = cv2.inpaint(np.array(background), mask, 10, cv2.INPAINT_TELEA)
background = Image.fromarray(cleaned)
background.save(output / "flood_background.png", optimize=True)
