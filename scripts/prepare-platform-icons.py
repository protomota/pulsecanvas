#!/usr/bin/env python3
"""Package the existing PulseCanvas mark in Apple's layered visionOS icon format.
Requires Pillow. Does not generate a new brand image.
"""
import json
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[1]
mark=Image.open(root/'assets/app-icon/PulseCanvas-Octagon.png').convert('RGBA')
info={'author':'xcode','version':1}
def write(folder: Path, value: dict) -> None:
 folder.mkdir(parents=True,exist_ok=True);(folder/'Contents.json').write_text(json.dumps(value,indent=2)+'\n')
vision=root/'visionOS/Assets.xcassets';write(vision,{'info':info})
stack=vision/'AppIcon.solidimagestack';write(stack,{'info':info,'layers':[{'filename':n+'.solidimagestacklayer'} for n in ['Front','Back']]})
for name in ['Front','Back']:
 layer=stack/(name+'.solidimagestacklayer');write(layer,{'info':info});content=layer/'Content.imageset'
 write(content,{'info':info,'images':[{'idiom':'vision','scale':'2x','filename':'icon.png'}]})
 # Let visionOS apply its circular mask to a full-bleed brand image. Placing an
 # opaque square in the foreground creates a smaller black box inside that mask.
 canvas=Image.new('RGBA',(1024,1024),(0,0,0,0))
 if name=='Back':canvas=mark.resize((1024,1024),Image.Resampling.LANCZOS)
 canvas.save(content/'icon.png')
print('Packaged existing brand mark for visionOS')
