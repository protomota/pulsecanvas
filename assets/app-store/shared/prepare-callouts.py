"""Crop complete, real controls; marketing frames supply equal padding on all sides.

Usage: python3 prepare-callouts.py /absolute/native-capture-folder
Never modifies source screenshots. Crops remain alongside captures, outside Git.
"""
from pathlib import Path
from PIL import Image, ImageChops
import json, sys
root = Path(sys.argv[1])
# Bounds encompass whole controls; trim only surrounding flat panel background.
regions = {
    'iphone': {
        'studio': (30, 2136, 822, 2604),
        'style': (72, 866, 1134, 1296),
        'radio': (48, 1480, 1158, 2210),
        'export': (72, 661, 1134, 925),
    },
    'ipad': {
        'studio': (24, 1738, 2176, 2055),
        'style': (844, 810, 1908, 1306),
        'radio': (24, 1790, 2728, 1986),
        'export': (844, 640, 1908, 866),
    },
    'duo-inner': {
        'studio': (40, 1520, 2456, 1992),
        'style': (518, 710, 2337, 1415),
        'radio': (36, 1595, 2817, 1895),
        'export': (518, 510, 2337, 775),
    },
}
manifest = []
for prefix, entries in regions.items():
    for kind, bounds in entries.items():
        source = root / f'{prefix}-{kind}.png'
        if not source.exists(): continue
        im = Image.open(source).convert('RGB')
        color = (31, 25, 36) # Native MobileTheme panel background, including all padding.
        crop = im.crop(bounds)
        # Native timeline cards include borders, whereas other content can be tightly trimmed.
        diff = ImageChops.difference(crop, Image.new('RGB', crop.size, color))
        mask = diff.convert('L').point(lambda p: 255 if p > 8 else 0)
        tight = mask.getbbox()
        assert tight, f'Blank callout: {source.name}'
        crop = crop.crop(tight)
        path = root / f'{prefix}-callout-{kind}.png'
        crop.save(path)
        manifest.append({'prefix': prefix, 'kind': kind, 'file': path.name,
                         'background': '#%02x%02x%02x' % color,
                         'width': crop.width, 'height': crop.height,
                         'sourceBounds': bounds, 'trim': tight})
(root/'callout-manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
print(json.dumps(manifest, indent=2))
