"""Generate the retro UI textures and placeholder photos for the Desktop mockup.

Run from the repository root:
    python tools/generate_ui_assets.py

The script is deterministic (fixed random seed) and only depends on Pillow.
All output paths are relative to the repository root.
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
UI_DIR = ROOT / "assets" / "ui"
PREVIEW_DIR = ROOT / "assets" / "previews"
UI_DIR.mkdir(parents=True, exist_ok=True)
PREVIEW_DIR.mkdir(parents=True, exist_ok=True)

FACE = (192, 192, 192, 255)
MID = (223, 223, 223, 255)
LIGHT = (255, 255, 255, 255)
SHADOW = (128, 128, 128, 255)
DARK = (0, 0, 0, 255)
NAVY = (0, 0, 128, 255)
TEAL = (0, 128, 128, 255)

FONT_CANDIDATES = [
    Path("C:/Windows/Fonts/arial.ttf"),
    Path("C:/Windows/Fonts/tahoma.ttf"),
    Path("C:/Windows/Fonts/segoeui.ttf"),
    Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
]
FONT_BOLD_CANDIDATES = [
    Path("C:/Windows/Fonts/arialbd.ttf"),
    Path("C:/Windows/Fonts/tahomabd.ttf"),
    Path("C:/Windows/Fonts/segoeuib.ttf"),
    Path("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"),
]


def _font(candidates: list[Path], size: int) -> ImageFont.FreeTypeFont:
    for path in candidates:
        if path.exists():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default(size=size)


def save(img: Image.Image, path: Path) -> None:
    img.save(path, optimize=True)
    print(f"  {path.relative_to(ROOT)}  {img.width}x{img.height}")


def make_raised(size: int = 16, fill: tuple[int, int, int, int] = FACE) -> Image.Image:
    img = Image.new("RGBA", (size, size), fill)
    d = ImageDraw.Draw(img)
    # Classic two-pixel raised bevel: light on top/left, dark on bottom/right.
    d.line([(0, 0), (size - 1, 0)], fill=MID)
    d.line([(0, 0), (0, size - 1)], fill=MID)
    d.line([(1, 1), (size - 2, 1)], fill=LIGHT)
    d.line([(1, 1), (1, size - 2)], fill=LIGHT)
    d.line([(0, size - 1), (size - 1, size - 1)], fill=DARK)
    d.line([(size - 1, 0), (size - 1, size - 1)], fill=DARK)
    d.line([(1, size - 2), (size - 2, size - 2)], fill=SHADOW)
    d.line([(size - 2, 1), (size - 2, size - 2)], fill=SHADOW)
    img.putpixel((size - 1, 0), DARK)
    img.putpixel((0, size - 1), DARK)
    return img


def make_pressed(size: int = 16) -> Image.Image:
    img = Image.new("RGBA", (size, size), FACE)
    d = ImageDraw.Draw(img)
    # Pressed bevel is the raised one turned inside out.
    d.line([(0, 0), (size - 1, 0)], fill=SHADOW)
    d.line([(0, 0), (0, size - 1)], fill=SHADOW)
    d.line([(1, 1), (size - 2, 1)], fill=DARK)
    d.line([(1, 1), (1, size - 2)], fill=DARK)
    d.line([(0, size - 1), (size - 1, size - 1)], fill=LIGHT)
    d.line([(size - 1, 0), (size - 1, size - 1)], fill=LIGHT)
    d.line([(1, size - 2), (size - 2, size - 2)], fill=MID)
    d.line([(size - 2, 1), (size - 2, size - 2)], fill=MID)
    img.putpixel((size - 1, 0), LIGHT)
    img.putpixel((0, size - 1), LIGHT)
    return img


def make_sunken(size: int = 8, fill: tuple[int, int, int, int] = FACE) -> Image.Image:
    img = Image.new("RGBA", (size, size), fill)
    d = ImageDraw.Draw(img)
    d.line([(0, 0), (size - 1, 0)], fill=SHADOW)
    d.line([(0, 0), (0, size - 1)], fill=SHADOW)
    d.line([(0, size - 1), (size - 1, size - 1)], fill=LIGHT)
    d.line([(size - 1, 0), (size - 1, size - 1)], fill=LIGHT)
    img.putpixel((size - 1, 0), LIGHT)
    img.putpixel((0, size - 1), LIGHT)
    return img


def make_sunken_white(size: int = 16) -> Image.Image:
    img = Image.new("RGBA", (size, size), (255, 255, 255, 255))
    d = ImageDraw.Draw(img)
    d.line([(0, 0), (size - 1, 0)], fill=SHADOW)
    d.line([(0, 0), (0, size - 1)], fill=SHADOW)
    d.line([(1, 1), (size - 2, 1)], fill=DARK)
    d.line([(1, 1), (1, size - 2)], fill=DARK)
    d.line([(0, size - 1), (size - 1, size - 1)], fill=LIGHT)
    d.line([(size - 1, 0), (size - 1, size - 1)], fill=LIGHT)
    d.line([(1, size - 2), (size - 2, size - 2)], fill=MID)
    d.line([(size - 2, 1), (size - 2, size - 2)], fill=MID)
    img.putpixel((size - 1, 0), LIGHT)
    img.putpixel((0, size - 1), LIGHT)
    return img


def make_gradient(width: int, height: int, stops: list[tuple[float, tuple[int, int, int]]]) -> Image.Image:
    img = Image.new("RGBA", (width, height))
    d = ImageDraw.Draw(img)
    for y in range(height):
        t = y / max(1, height - 1)
        color = _gradient_color(stops, t)
        d.line([(0, y), (width, y)], fill=color)
    return img


def _gradient_color(stops: list[tuple[float, tuple[int, int, int]]], t: float) -> tuple[int, int, int, int]:
    for i in range(len(stops) - 1):
        t0, c0 = stops[i]
        t1, c1 = stops[i + 1]
        if t0 <= t <= t1:
            f = 0.0 if t1 == t0 else (t - t0) / (t1 - t0)
            return (
                round(c0[0] + (c1[0] - c0[0]) * f),
                round(c0[1] + (c1[1] - c0[1]) * f),
                round(c0[2] + (c1[2] - c0[2]) * f),
                255,
            )
    _, last = stops[-1]
    return (*last, 255)


def make_horizontal_gradient(width: int, height: int, left: tuple[int, int, int], right: tuple[int, int, int]) -> Image.Image:
    img = Image.new("RGBA", (width, height))
    d = ImageDraw.Draw(img)
    for x in range(width):
        t = x / max(1, width - 1)
        color = (
            round(left[0] + (right[0] - left[0]) * t),
            round(left[1] + (right[1] - left[1]) * t),
            round(left[2] + (right[2] - left[2]) * t),
            255,
        )
        d.line([(x, 0), (x, height)], fill=color)
    # A soft CRT-like highlight across the upper part of the title bar.
    highlight = Image.new("RGBA", (width, height), (255, 255, 255, 0))
    hd = ImageDraw.Draw(highlight)
    hd.rectangle([0, 0, width, 2], fill=(255, 255, 255, 45))
    img.alpha_composite(highlight)
    return img


def make_vignette(width: int = 640, height: int = 360) -> Image.Image:
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    px = img.load()
    cx, cy = width / 2, height / 2
    max_dist = math.hypot(cx, cy)
    for y in range(height):
        for x in range(width):
            dist = math.hypot((x - cx) * 0.82, y - cy) / max_dist
            alpha = int(max(0.0, (dist - 0.42) / 0.58) ** 1.8 * 120)
            px[x, y] = (0, 0, 0, alpha)
    return img


def grain(img: Image.Image, amount: int = 9, seed: int = 0) -> Image.Image:
    rng = random.Random(seed)
    noise = Image.new("L", img.size)
    npix = noise.load()
    for y in range(img.height):
        for x in range(img.width):
            npix[x, y] = rng.randint(128 - amount, 128 + amount)
    # Overlay-like blend so the photo keeps its colours.
    result = Image.new("RGBA", img.size)
    src = img.convert("RGBA")
    npx = noise.load()
    rpx = result.load()
    spx = src.load()
    for y in range(img.height):
        for x in range(img.width):
            n = npx[x, y] / 255.0
            r, g, b, a = spx[x, y]
            rpx[x, y] = (
                max(0, min(255, int(r * (0.82 + n * 0.36)))),
                max(0, min(255, int(g * (0.82 + n * 0.36)))),
                max(0, min(255, int(b * (0.82 + n * 0.36)))),
                a,
            )
    return result


def photo_base(width: int = 360, height: int = 240, top=(28, 38, 54), bottom=(92, 108, 126)) -> Image.Image:
    img = make_gradient(width, height, [(0.0, top), (1.0, bottom)])
    return img


def draw_text(d: ImageDraw.ImageDraw, xy, text, font, fill, anchor="la", stroke=0, stroke_fill=None):
    d.text(xy, text, font=font, fill=fill, anchor=anchor, stroke_width=stroke, stroke_fill=stroke_fill)


def photo_truck() -> Image.Image:
    w, h = 360, 240
    img = photo_base(w, h, (31, 43, 55), (104, 112, 112))
    d = ImageDraw.Draw(img)
    # Industrial skyline and wet asphalt.
    d.rectangle([0, 156, w, h], fill=(58, 58, 60))
    d.rectangle([0, 176, w, h], fill=(43, 43, 46))
    for x in range(0, w, 34):
        d.rectangle([x, 132, x + 24, 176], fill=(54, 58, 64))
        d.rectangle([x + 5, 140, x + 12, 148], fill=(212, 186, 96))
    # Warehouse gate and sign.
    d.rectangle([20, 86, 152, 180], fill=(72, 78, 84))
    d.rectangle([20, 86, 152, 104], fill=(44, 48, 54))
    draw_text(d, (86, 95), "СКЛАД № 3", _font(FONT_BOLD_CANDIDATES, 13), (238, 238, 226), anchor="mm")
    for x in range(26, 152, 18):
        d.line([(x, 108), (x, 180)], fill=(58, 62, 68), width=2)
    # Truck trailer with the key number 6752.
    d.polygon([(168, 68), (330, 80), (330, 188), (168, 174)], fill=(219, 219, 208))
    d.polygon([(168, 68), (330, 80), (318, 92), (160, 80)], fill=(238, 238, 226))
    d.rectangle([176, 96, 322, 168], fill=(226, 226, 215))
    draw_text(d, (248, 130), "6752", _font(FONT_BOLD_CANDIDATES, 54), (39, 42, 47), anchor="mm", stroke=1, stroke_fill=(212, 212, 200))
    d.rectangle([160, 174, 340, 194], fill=(25, 25, 28))
    for x in (196, 268, 330):
        d.ellipse([x - 12, 178, x + 12, 202], fill=(18, 18, 20))
        d.ellipse([x - 6, 184, x + 6, 196], fill=(76, 76, 80))
    # Fence in front.
    for x in range(0, w, 12):
        d.line([(x, 196), (x, 218)], fill=(35, 35, 38), width=1)
    d.line([(0, 199), (w, 199)], fill=(35, 35, 38), width=2)
    d.line([(0, 212), (w, 212)], fill=(35, 35, 38), width=2)
    # Puddles reflecting the sign.
    d.ellipse([110, 216, 200, 232], fill=(88, 94, 98))
    d.ellipse([250, 214, 330, 228], fill=(82, 88, 92))
    img = grain(img, 10, 3)
    return img.filter(ImageFilter.GaussianBlur(0.25))


def photo_pickup() -> Image.Image:
    w, h = 360, 240
    img = photo_base(w, h, (103, 65, 44), (224, 164, 96))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 150, w, h], fill=(75, 62, 50))
    # Garage boxes.
    for i in range(4):
        x = i * 92
        d.rectangle([x + 6, 76, x + 88, 168], fill=(94, 78, 64))
        d.rectangle([x + 11, 82, x + 82, 163], fill=(70, 60, 52))
        for k in range(5):
            y = 88 + k * 14
            d.line([(x + 11, y), (x + 82, y)], fill=(58, 50, 44), width=2)
    # Rusty pickup silhouette.
    d.rectangle([84, 140, 248, 178], fill=(126, 72, 48))
    d.polygon([(112, 140), (140, 108), (196, 108), (218, 140)], fill=(139, 83, 54))
    d.rectangle([148, 116, 190, 138], fill=(56, 68, 79))
    for x in (118, 222):
        d.ellipse([x - 16, 168, x + 16, 200], fill=(28, 26, 26))
        d.ellipse([x - 8, 176, x + 8, 192], fill=(105, 105, 105))
    # Warm sunlight and long shadows.
    d.rectangle([0, 200, w, h], fill=(62, 52, 43))
    d.line([(0, 196), (w, 200)], fill=(197, 140, 84), width=2)
    img = grain(img, 9, 4)
    return img.filter(ImageFilter.GaussianBlur(0.2))


def photo_gas() -> Image.Image:
    w, h = 360, 240
    img = photo_base(w, h, (9, 14, 28), (24, 34, 55))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 174, w, h], fill=(28, 30, 37))
    d.rectangle([0, 186, w, h], fill=(20, 21, 26))
    # Canopy and lights.
    d.rectangle([40, 58, 320, 70], fill=(201, 201, 194))
    d.rectangle([52, 70, 62, 178], fill=(172, 172, 166))
    d.rectangle([298, 70, 308, 178], fill=(172, 172, 166))
    for x in range(70, 300, 44):
        d.rectangle([x, 66, x + 22, 71], fill=(255, 246, 190))
        glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow)
        gd.ellipse([x - 22, 44, x + 44, 96], fill=(255, 242, 171, 55))
        img = Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(9)))
        d = ImageDraw.Draw(img)
    # Pumps.
    for x in (104, 196):
        d.rectangle([x, 132, x + 34, 180], fill=(190, 190, 180))
        d.rectangle([x + 5, 138, x + 29, 154], fill=(44, 51, 49))
        d.rectangle([x + 12, 160, x + 22, 166], fill=(130, 40, 36))
    # Wet ground reflections.
    d.rectangle([60, 180, 300, 184], fill=(58, 54, 42))
    img = grain(img, 11, 5)
    return img.filter(ImageFilter.GaussianBlur(0.3))


def photo_cat() -> Image.Image:
    w, h = 360, 240
    img = photo_base(w, h, (10, 12, 19), (37, 30, 42))
    d = ImageDraw.Draw(img)
    # Window frame and night city.
    d.rectangle([52, 26, 308, 196], fill=(19, 26, 42))
    d.rectangle([52, 26, 308, 196], outline=(48, 37, 31), width=10)
    d.line([(180, 30), (180, 196)], fill=(48, 37, 31), width=6)
    d.line([(56, 112), (304, 112)], fill=(48, 37, 31), width=6)
    for x in range(62, 300, 22):
        d.rectangle([x, 132, x + 14, 188], fill=(23, 31, 48))
        if x % 44 == 18:
            d.rectangle([x + 4, 142, x + 8, 148], fill=(201, 172, 99))
    d.ellipse([248, 48, 280, 80], fill=(208, 209, 184))
    # Cat silhouette on the sill.
    d.ellipse([122, 118, 214, 198], fill=(161, 101, 51))
    d.ellipse([132, 74, 206, 154], fill=(173, 111, 56))
    d.polygon([(140, 88), (146, 52), (164, 80)], fill=(173, 111, 56))
    d.polygon([(176, 78), (194, 52), (198, 88)], fill=(173, 111, 56))
    d.ellipse([146, 102, 160, 116], fill=(223, 211, 126))
    d.ellipse([176, 102, 190, 116], fill=(223, 211, 126))
    d.ellipse([151, 107, 155, 114], fill=(20, 20, 24))
    d.ellipse([181, 107, 185, 114], fill=(20, 20, 24))
    d.polygon([(166, 120), (172, 120), (169, 125)], fill=(92, 55, 46))
    # Tail.
    d.arc([196, 150, 268, 218], 300, 90, fill=(161, 101, 51), width=12)
    img = grain(img, 12, 6)
    return img.filter(ImageFilter.GaussianBlur(0.45))


def photo_picnic() -> Image.Image:
    w, h = 360, 240
    img = photo_base(w, h, (104, 154, 191), (188, 216, 194))
    d = ImageDraw.Draw(img)
    # Distant trees.
    d.rectangle([0, 128, w, h], fill=(88, 124, 72))
    for x in range(0, w, 28):
        d.ellipse([x - 18, 92, x + 30, 154], fill=(52, 84, 54))
    # Checkered blanket.
    d.polygon([(48, 186), (306, 168), (330, 224), (24, 232)], fill=(196, 73, 64))
    for i in range(6):
        x = 52 + i * 46
        d.line([(x, 182), (x - 12, 230)], fill=(232, 231, 205), width=6)
    for i in range(3):
        y = 190 + i * 14
        d.line([(28, y), (326, y - 16)], fill=(232, 231, 205), width=5)
    d.rectangle([132, 168, 190, 192], fill=(139, 100, 58))
    d.arc([132, 150, 190, 186], 180, 360, fill=(139, 100, 58), width=7)
    d.ellipse([210, 176, 236, 194], fill=(222, 178, 71))
    d.ellipse([242, 178, 264, 194], fill=(141, 177, 82))
    # Sun flare.
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([270, 12, 354, 96], fill=(255, 240, 182, 80))
    img = Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(15)))
    img = grain(img, 8, 7)
    return img.filter(ImageFilter.GaussianBlur(0.2))


def photo_rain() -> Image.Image:
    w, h = 360, 240
    img = photo_base(w, h, (10, 18, 28), (31, 45, 57))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 166, w, h], fill=(19, 24, 31))
    # Buildings and lit windows.
    for i, (x, bw) in enumerate([(0, 90), (92, 76), (170, 106), (278, 82)]):
        bh = 80 + (i % 3) * 26
        d.rectangle([x, 166 - bh, x + bw, 166], fill=(27, 33, 41))
        for wy in range(166 - bh + 10, 158, 18):
            for wx in range(x + 8, x + bw - 8, 16):
                if (wx + wy) % 5 != 0:
                    d.rectangle([wx, wy, wx + 6, wy + 8], fill=(190, 165, 102))
    # Street lamps with sodium glow.
    for x in (74, 286):
        d.rectangle([x, 82, x + 4, 186], fill=(24, 26, 29))
        d.ellipse([x - 8, 74, x + 12, 92], fill=(242, 194, 108))
        glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow)
        gd.ellipse([x - 46, 52, x + 50, 142], fill=(245, 196, 105, 56))
        img = Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(18)))
        d = ImageDraw.Draw(img)
    # Wet road reflection.
    for x in (74, 286):
        d.line([(x, 192), (x - 18, 240)], fill=(191, 148, 77, 120), width=8)
    # Rain streaks.
    rng = random.Random(11)
    for _ in range(140):
        x = rng.randint(0, w)
        y = rng.randint(0, h)
        d.line([(x, y), (x - 2, y + rng.randint(6, 16))], fill=(180, 198, 208, 80), width=1)
    img = grain(img, 10, 8)
    return img.filter(ImageFilter.GaussianBlur(0.35))


def main() -> None:
    print("Generating 9-patch textures...")
    save(make_raised(), UI_DIR / "panel_raised.png")
    save(make_raised(fill=(206, 202, 196, 255)), UI_DIR / "panel_raised_hover.png")
    save(make_pressed(), UI_DIR / "panel_pressed.png")
    save(make_sunken(), UI_DIR / "panel_sunken.png")
    save(make_sunken_white(), UI_DIR / "panel_sunken_white.png")

    print("Generating title bar gradients...")
    save(make_horizontal_gradient(96, 28, (10, 36, 106), (74, 155, 224)), UI_DIR / "titlebar_active.png")
    save(make_horizontal_gradient(96, 28, (110, 110, 110), (181, 181, 181)), UI_DIR / "titlebar_inactive.png")
    save(make_gradient(64, 64, [(0.0, (0, 0, 128)), (1.0, (16, 132, 208))]), UI_DIR / "startmenu_header.png")

    print("Generating CRT vignette...")
    save(make_vignette(), UI_DIR / "vignette.png")

    print("Generating placeholder photos...")
    save(photo_truck(), PREVIEW_DIR / "photo_truck.png")
    save(photo_pickup(), PREVIEW_DIR / "photo_pickup.png")
    save(photo_gas(), PREVIEW_DIR / "photo_gas.png")
    save(photo_cat(), PREVIEW_DIR / "photo_cat.png")
    save(photo_picnic(), PREVIEW_DIR / "photo_picnic.png")
    save(photo_rain(), PREVIEW_DIR / "photo_rain.png")


if __name__ == "__main__":
    main()
