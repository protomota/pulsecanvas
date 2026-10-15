"""Render original installer artwork at 1x/2x. Requires Pillow, not used in CI."""
from pathlib import Path
import math
import subprocess

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
FONT = Path("/System/Library/Fonts/SFNS.ttf")


def render(scale: int) -> None:
    width, height = 720 * scale, 460 * scale
    canvas = Image.new("RGB", (width, height))
    pixels = canvas.load()
    # PulseCanvas brand base #17121b with light concentrated behind the installation path.
    for y in range(height):
        for x in range(width):
            glow = math.exp(-(((x / scale - 360) / 410) ** 2
                              + ((y / scale - 240) / 300) ** 2))
            pixels[x, y] = tuple(round(base + glow * lift)
                                 for base, lift in zip((23, 18, 27), (24, 17, 29)))
    draw = ImageDraw.Draw(canvas)

    def box(bounds: tuple) -> tuple:
        return tuple(round(value * scale) for value in bounds)

    def text(value: str, y: int, size: int, color: str, weight: int = 400) -> None:
        font = ImageFont.truetype(str(FONT), size * scale)
        # SF's weight axis uses its own range. Select named instances when present.
        names = font.get_variation_names()
        desired = b"Bold" if weight >= 600 else b"Regular"
        if desired in names:
            font.set_variation_by_name(desired)
        if draw.textlength(value, font=font) > 632 * scale:
            raise ValueError(f"Installer instruction exceeds safe width: {value}")
        draw.text((360 * scale, y * scale), value, font=font,
                  fill=color, anchor="mt")

    draw.rounded_rectangle(box((18, 18, 702, 442)), radius=22 * scale,
                           outline="#67566F", width=scale)
    text("Install PulseCanvas Studio", 48, 30, "#FFFFFF", 700)
    text("Drag PulseCanvas Studio to Applications to get started.", 95, 16, "#E5DCEC")

    # The real draggable Finder icons are placed over these two quiet wells.
    draw.rounded_rectangle(box((117, 154, 273, 316)), radius=22 * scale,
                           fill="#DED1EB")
    draw.rounded_rectangle(box((447, 154, 603, 316)), radius=22 * scale,
                           fill="#DED1EB", outline="#B5A1CD", width=scale)
    # Rounded dotted outline: evenly spaced dots along four sides and corner arcs.
    left, top, right, bottom, radius = 110, 147, 280, 323, 29
    dots = []
    for start, stop, fixed, horizontal in (
        (left + radius, right - radius, top, True),
        (left + radius, right - radius, bottom, True),
        (top + radius, bottom - radius, left, False),
        (top + radius, bottom - radius, right, False),
    ):
        count = round((stop - start) / 9)
        for index in range(count + 1):
            value = start + (stop - start) * index / count
            dots.append((value, fixed) if horizontal else (fixed, value))
    for cx, cy, begin in ((left + radius, top + radius, 180),
                          (right - radius, top + radius, 270),
                          (right - radius, bottom - radius, 0),
                          (left + radius, bottom - radius, 90)):
        for angle in range(begin + 15, begin + 90, 20):
            dots.append((cx + radius * math.cos(math.radians(angle)),
                         cy + radius * math.sin(math.radians(angle))))
    for x, y in dots:
        draw.ellipse(box((x - 1.15, y - 1.15, x + 1.15, y + 1.15)), fill="#F2B394")

    # Rounded arrow pointing from the app to the actual Applications shortcut.
    draw.line(box((321, 230, 396, 230)), fill="#C5B3DF", width=3 * scale)
    draw.line(box((381, 215, 397, 230, 381, 245)), fill="#C5B3DF", width=3 * scale)
    draw.line(box((88, 355, 632, 355)), fill="#67566F", width=scale)
    text("Eject this disk image when copying is complete.", 378, 15, "#F7F1ED")
    text("Open PulseCanvas Studio from your Applications folder.", 410, 14, "#C5B3DF")
    target = ROOT / ("background.png" if scale == 1 else "background@2x.png")
    canvas.save(target, dpi=(72 * scale, 72 * scale))
    print(target.name, canvas.size)


if __name__ == "__main__":
    render(1)
    render(2)
    subprocess.run(["tiffutil", "-cathidpicheck", str(ROOT / "background.png"),
                    str(ROOT / "background@2x.png"), "-out", str(ROOT / "background.tiff")],
                   check=True)
