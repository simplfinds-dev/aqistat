"""Generates the Aqistat app icon at multiple resolutions.
Design: rounded-square gradient (indigo -> teal) with stylized
air/wind currents and a subtle AQI dot, evoking 'air quality + weather'.
"""
import math
import os
from PIL import Image, ImageDraw, ImageFilter

BASE = 1024


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def make_icon(size=BASE, rounded=True):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # --- diagonal gradient background ---
    c1 = (108, 99, 255)   # indigo  #6C63FF
    c2 = (0, 212, 170)    # teal    #00D4AA
    c_dark = (26, 31, 56) # deep navy for depth
    for y in range(size):
        for_band = y / size
        # blend navy at top-left to gradient
        row = lerp(c1, c2, for_band)
        draw.line([(0, y), (size, y)], fill=row + (255,))

    # add a soft diagonal indigo glow (top-left)
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([-size*0.3, -size*0.3, size*0.6, size*0.6],
               fill=(108, 99, 255, 150))
    glow = glow.filter(ImageFilter.GaussianBlur(size*0.18))
    img = Image.alpha_composite(img, glow)
    draw = ImageDraw.Draw(img)

    # --- wind / air current strokes (white, rounded) ---
    sw = int(size * 0.055)  # stroke width
    white = (255, 255, 255, 235)

    def wind_line(cx, cy, length, curl):
        # a curved current ending in a little curl
        pts = []
        for i in range(0, 101):
            t = i / 100
            x = cx + t * length
            y = cy + math.sin(t * math.pi) * (size * 0.04)
            pts.append((x, y))
        draw.line(pts, fill=white, width=sw, joint="curve")
        # curl at the end
        ex, ey = pts[-1]
        r = curl
        draw.arc([ex - r, ey - r*2, ex + r, ey],
                 start=270, end=170, fill=white, width=sw)

    cx = size * 0.20
    wind_line(cx, size * 0.40, size * 0.42, size * 0.085)
    wind_line(cx, size * 0.56, size * 0.52, size * 0.10)
    wind_line(cx, size * 0.72, size * 0.36, size * 0.075)

    # --- AQI status dot (teal-green) top right ---
    dr = size * 0.075
    dx, dy = size * 0.76, size * 0.26
    # glow behind dot
    dot_glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    dgd = ImageDraw.Draw(dot_glow)
    dgd.ellipse([dx - dr*2, dy - dr*2, dx + dr*2, dy + dr*2],
                fill=(0, 255, 190, 180))
    dot_glow = dot_glow.filter(ImageFilter.GaussianBlur(size*0.03))
    img = Image.alpha_composite(img, dot_glow)
    draw = ImageDraw.Draw(img)
    draw.ellipse([dx - dr, dy - dr, dx + dr, dy + dr],
                 fill=(180, 255, 230, 255))

    # --- rounded corners mask ---
    if rounded:
        radius = int(size * 0.22)
        mask = Image.new("L", (size, size), 0)
        md = ImageDraw.Draw(mask)
        md.rounded_rectangle([0, 0, size, size], radius=radius, fill=255)
        img.putalpha(mask)

    return img


def main():
    out_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "icon")
    os.makedirs(out_dir, exist_ok=True)

    master = make_icon(BASE, rounded=True)
    master.save(os.path.join(out_dir, "icon.png"))

    # also a non-rounded full-bleed version for adaptive foreground
    full = make_icon(BASE, rounded=False)
    full.save(os.path.join(out_dir, "icon_foreground.png"))

    print("Icons written to", os.path.abspath(out_dir))


if __name__ == "__main__":
    main()
