"""Generates the Aqistat app icon — clean, modern, anti-aliased.

Design: rounded-square indigo->teal gradient with three smooth tapering
'air current' swooshes and a soft glowing sun/AQI dot. Rendered at 4x and
downscaled with LANCZOS for crisp, smooth edges.
"""
import math
import os
from PIL import Image, ImageDraw, ImageFilter

OUT = 1024
SS = 4               # supersample factor
S = OUT * SS         # render size


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def smooth_swoosh(draw, cx, cy, length, width, color):
    """Draw one smooth tapering air-current curve with rounded ends."""
    pts = []
    steps = 220
    for i in range(steps + 1):
        t = i / steps
        x = cx + t * length
        # gentle S-curve
        y = cy - math.sin(t * math.pi) * (S * 0.045)
        pts.append((x, y))
    # taper: thick in middle, thin at ends -> draw overlapping circles
    for i, (x, y) in enumerate(pts):
        t = i / len(pts)
        taper = math.sin(t * math.pi)          # 0..1..0
        r = max(1, width * (0.25 + 0.75 * taper))
        draw.ellipse([x - r, y - r, x + r, y + r], fill=color)


def make_icon(rounded=True):
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # --- diagonal gradient background (indigo -> teal) ---
    c_top = (108, 99, 255)    # indigo  #6C63FF
    c_bot = (0, 212, 170)     # teal    #00D4AA
    for y in range(S):
        d.line([(0, y), (S, y)], fill=lerp(c_top, c_bot, y / S) + (255,))

    # soft indigo glow top-left for depth
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([-S * 0.25, -S * 0.25, S * 0.55, S * 0.55], fill=(124, 110, 255, 130))
    glow = glow.filter(ImageFilter.GaussianBlur(S * 0.16))
    img = Image.alpha_composite(img, glow)
    d = ImageDraw.Draw(img)

    # --- three smooth air-current swooshes ---
    white = (255, 255, 255, 240)
    base_w = S * 0.030
    smooth_swoosh(d, S * 0.20, S * 0.42, S * 0.46, base_w, white)
    smooth_swoosh(d, S * 0.18, S * 0.56, S * 0.54, base_w * 1.15, white)
    smooth_swoosh(d, S * 0.22, S * 0.70, S * 0.40, base_w * 0.9, white)

    # --- glowing sun / AQI dot (top-right) ---
    dx, dy, dr = S * 0.72, S * 0.30, S * 0.085
    dot_glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    dgd = ImageDraw.Draw(dot_glow)
    dgd.ellipse([dx - dr * 2.4, dy - dr * 2.4, dx + dr * 2.4, dy + dr * 2.4],
                fill=(180, 255, 230, 200))
    dot_glow = dot_glow.filter(ImageFilter.GaussianBlur(S * 0.035))
    img = Image.alpha_composite(img, dot_glow)
    d = ImageDraw.Draw(img)
    d.ellipse([dx - dr, dy - dr, dx + dr, dy + dr], fill=(255, 255, 255, 255))

    # --- rounded corners ---
    if rounded:
        radius = int(S * 0.235)
        mask = Image.new("L", (S, S), 0)
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, S, S], radius=radius, fill=255)
        img.putalpha(mask)

    # downscale for smooth anti-aliasing
    return img.resize((OUT, OUT), Image.LANCZOS)


def main():
    out_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "icon")
    os.makedirs(out_dir, exist_ok=True)
    make_icon(rounded=True).save(os.path.join(out_dir, "icon.png"))
    make_icon(rounded=False).save(os.path.join(out_dir, "icon_foreground.png"))
    print("Icons written to", os.path.abspath(out_dir))


if __name__ == "__main__":
    main()
