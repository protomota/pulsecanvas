#!/usr/bin/env python3
"""Package the existing PulseCanvas mark in Apple's layered TV/vision icon formats.
Requires Pillow. Does not generate a new brand image.
"""
import json
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[1]
mark=Image.open(root/'assets/app-icon/PulseCanvas-Octagon.png').convert('RGBA')
info={'author':'xcode','version':1}
def write(folder,value):
 folder.mkdir(parents=True,exist_ok=True);(folder/'Contents.json').write_text(json.dumps(value,indent=2)+'\n')
def image(folder,name,size,foreground=False):
 canvas=Image.new('RGBA',size,(0,0,0,0) if foreground else (23,17,30,255))
 if foreground:
  width=int(min(size)*0.78); icon=mark.copy();icon.thumbnail((width,width),Image.Resampling.LANCZOS)
  canvas.alpha_composite(icon,((size[0]-icon.width)//2,(size[1]-icon.height)//2))
 canvas.save(folder/name)
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
tv=root/'tvOS/Assets.xcassets';write(tv,{'info':info});brand=tv/'AppIcon.brandassets'
write(brand,{'info':info,'assets':[{'filename':'Small.imagestack','idiom':'tv','size':'400x240','role':'primary-app-icon'},{'filename':'Large.imagestack','idiom':'tv','size':'1280x768','role':'primary-app-icon'},{'filename':'TopShelf.imageset','idiom':'tv','size':'1920x720','role':'top-shelf-image'},{'filename':'TopShelfWide.imageset','idiom':'tv','size':'2320x720','role':'top-shelf-image-wide'}]})
for name,size,scales in [('Small',(400,240),[1,2]),('Large',(1280,768),[1])]:
 stack=brand/(name+'.imagestack');write(stack,{'info':info,'layers':[{'filename':n+'.imagestacklayer'} for n in ['Front','Back']]})
 for layername in ['Front','Back']:
  layer=stack/(layername+'.imagestacklayer');write(layer,{'info':info});content=layer/'Content.imageset'
  write(content,{'info':info,'images':[{'idiom':'tv','scale':str(scale)+'x','filename':f'icon-{scale}x.png'} for scale in scales]})
  for scale in scales:image(content,f'icon-{scale}x.png',(size[0]*scale,size[1]*scale),layername=='Front')
for name,width in [('TopShelf',1920),('TopShelfWide',2320)]:
 content=brand/(name+'.imageset');write(content,{'info':info,'images':[{'idiom':'tv','scale':str(scale)+'x','filename':f'image-{scale}x.png'} for scale in [1,2]]})
 for scale in [1,2]:
  size=(width*scale,720*scale);canvas=Image.new('RGB',size,(23,17,30));icon=mark.copy();icon.thumbnail((520*scale,520*scale),Image.Resampling.LANCZOS);canvas.paste(icon,((size[0]-icon.width)//2,(size[1]-icon.height)//2),icon);canvas.save(content/f'image-{scale}x.png')
print('Packaged existing brand mark for visionOS and tvOS')
