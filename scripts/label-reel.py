#!/usr/bin/env python3
"""Label a native reel with one subtitle renderer; retain its existing soundtrack."""
import json
import subprocess
import sys
import uuid
from pathlib import Path

video = Path(sys.argv[1])
meta = json.loads(video.with_suffix('.json').read_text())
# Display-only renames do not change pixels or permanent IDs. Use the current registry.
registry = json.loads(subprocess.check_output([sys.executable, str(Path(__file__).with_name('native-visualizer-catalog.py'))], text=True))
meta['names'] = [effect['name'] for effect in registry['effects']]
video.with_suffix('.json').write_text(json.dumps(meta, indent=2) + '\n')
probe = json.loads(subprocess.check_output(['ffprobe', '-v', 'error', '-select_streams', 'v:0',
    '-show_entries', 'stream=width,height', '-of', 'json', str(video)], text=True))['streams'][0]
width, height = probe['width'], probe['height']

def timestamp(seconds):
    ticks = round(seconds * 100)
    return f'{ticks // 360000}:{ticks // 6000 % 60:02d}:{ticks // 100 % 60:02d}.{ticks % 100:02d}'

script = video.with_suffix('.ass')
margin = max(24, height // 30)
header = f'''[Script Info]
ScriptType: v4.00+
PlayResX: {width}
PlayResY: {height}
WrapStyle: 2

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Helvetica,{height // 27},&H00FFFFFF,&H00FFFFFF,&H88000000,&H88000000,0,0,0,0,100,100,0,0,3,12,0,1,{margin},{margin},{margin},1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
'''
rows = []
for segment in meta['segments']:
    scene = int(segment['scene'])
    name = meta['names'][scene].replace('\\', '').replace('{', '').replace('}', '').replace('\n', ' ')
    text = f'{scene}  {name}'
    rows.append(f"Dialogue: 0,{timestamp(segment['start'])},{timestamp(segment['end'])},Default,,0,0,0,,{text}")
script.write_text(header + '\n'.join(rows) + '\n')
labeled = video.with_name(video.stem + '-labeled.mp4')
render_target = video.with_name(video.stem + '-labels-' + uuid.uuid4().hex + '.mp4')
# One libass filter avoids evaluating hundreds of drawtext filters on every 4K frame.
subprocess.run(['ffmpeg', '-y', '-loglevel', 'warning', '-i', str(video),
    '-vf', f"ass=filename='{script}'", '-c:v', 'h264_videotoolbox', '-b:v', '24M' if max(width, height) >= 3840 else '8M',
    '-pix_fmt', 'yuv420p', '-c:a', 'copy', '-movflags', '+faststart', str(render_target)], check=True)
render_target.replace(labeled)
labeled.with_suffix('.json').write_text(json.dumps(meta, indent=2) + '\n')
print(f'Labeled {labeled}')
