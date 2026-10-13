#!/usr/bin/env python3
"""Compose labeled contact sheets from gallery stills (NNN.png) or motion strips.

  scripts/native-contact-sheet.py --input .build/gallery/wide --output sheet.png
  scripts/native-contact-sheet.py --strip .build/gallery/frames/040 --frames 6 --output strip.png
"""
import argparse
import json
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parents[1]


def effect_names():
    catalog = subprocess.check_output([sys.executable, str(root / 'scripts/native-visualizer-catalog.py')], text=True)
    return {effect['scene']: effect['name'] for effect in json.loads(catalog)['effects'] if not effect.get('retired')}


def font(size):
    for candidate in ['/System/Library/Fonts/SFNS.ttf', '/System/Library/Fonts/Helvetica.ttc']:
        try:
            return ImageFont.truetype(candidate, size)
        except OSError:
            continue
    return ImageFont.load_default()


def label(image, text, size):
    draw = ImageDraw.Draw(image, 'RGBA')
    face = font(size)
    box = draw.textbbox((0, 0), text, font=face)
    draw.rectangle((0, image.height - (box[3] - box[1]) - size, box[2] - box[0] + size, image.height), fill=(0, 0, 0, 170))
    draw.text((size // 2, image.height - (box[3] - box[1]) - size // 2 - box[1]), text, font=face, fill=(255, 255, 255, 255))


def sheet(paths, captions, columns, output, scale):
    tiles = [Image.open(p).convert('RGB') for p in paths]
    width, height = int(tiles[0].width * scale), int(tiles[0].height * scale)
    rows = (len(tiles) + columns - 1) // columns
    gap = 6
    canvas = Image.new('RGB', (columns * width + (columns + 1) * gap, rows * height + (rows + 1) * gap), (12, 12, 16))
    for index, (tile, caption) in enumerate(zip(tiles, captions)):
        tile = tile.resize((width, height), Image.LANCZOS)
        label(tile, caption, max(11, height // 14))
        x, y = index % columns, index // columns
        canvas.paste(tile, (gap + x * (width + gap), gap + y * (height + gap)))
    canvas.save(output)
    print(f'Wrote {output} ({len(tiles)} tiles)')


parser = argparse.ArgumentParser()
parser.add_argument('--input', type=Path)
parser.add_argument('--strip', type=Path)
parser.add_argument('--frames', type=int, default=6)
parser.add_argument('--columns', type=int, default=6)
parser.add_argument('--scale', type=float, default=1.0)
parser.add_argument('--fps', type=float, default=30)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
names = effect_names()
if args.input:
    paths = sorted(p for p in args.input.glob('[0-9][0-9][0-9].png') if int(p.stem) in names)
    captions = [f'{int(p.stem)}  {names.get(int(p.stem), "?")}' for p in paths]
    sheet(paths, captions, args.columns, args.output, args.scale)
elif args.strip:
    frames = sorted(args.strip.glob('*.png'))
    picks = [frames[round(i * (len(frames) - 1) / max(1, args.frames - 1))] for i in range(args.frames)]
    scene = int(args.strip.name)
    captions = [f'{names.get(scene, "?")}  t+{int(p.stem) / args.fps:.2f}s' for p in picks]
    sheet(picks, captions, args.frames if args.columns >= args.frames else args.columns, args.output, args.scale)
