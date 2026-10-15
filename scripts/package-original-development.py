#!/usr/bin/env python3
"""Package the current original-Metal working tree as an explicitly unreleased snapshot."""
from pathlib import Path
import hashlib,json,shutil,subprocess,tarfile
root=Path(__file__).resolve().parent.parent
out=root/'.build/original188-development-package';out.mkdir(parents=True,exist_ok=True)
stage=out/'PulseCanvas-original188-source'
if stage.exists():shutil.rmtree(stage)
stage.mkdir()
def copy(path):
 source=root/path;target=stage/path;target.parent.mkdir(parents=True,exist_ok=True)
 if source.is_dir():shutil.copytree(source,target,ignore=shutil.ignore_patterns('__pycache__','.DS_Store'))
 else:shutil.copy2(source,target)
for path in ['Sources','scripts','macOS','PulseCanvas.xcodeproj','Package.swift','LICENSE','README.md','assets/app-icon','assets/readme','assets/marketing','assets/app-store/screenshots','third_party/historical-projectm-notices']:
 copy(path)
for path in ['docs/ORIGINAL-VISUALS-EXPANSION.md','docs/original-additions.json','docs/RENDERING.md','docs/USER_GUIDE.md','docs/DISTRIBUTION.md','docs/licensing.md','docs/shader-provenance.json','docs/app-store/RIGHTS-RESOLUTION.md','third_party/PROJECTM.md']:
 copy(path)
for p in stage.rglob('*'):
 assert p.suffix.lower() not in ('.milk','.ll'),p
 assert p.name!='VisualShaders.metallib',p
(stage/'BUILD.txt').write_text('''PulseCanvas Studio ORIGINAL METAL DEVELOPMENT SNAPSHOT — not a signed release.
188 active visualizers: 88 retained + 100 original additions; 12 reserved retired IDs.
The version/build in macOS/Release.xcconfig is retained from the prior release setup.
This snapshot does NOT represent that uploaded App Store build. Sources are uncommitted.
No production app, user session or distribution channel was changed.

Rebuild on macOS 14+ with Xcode and Python 3:
python3 scripts/generate-store-project.py
xcodebuild -project PulseCanvas.xcodeproj -scheme PulseCanvas -configuration Release -derivedDataPath .build/original-preview CODE_SIGNING_ALLOWED=NO build
python3 scripts/verify-original-resources.py ".build/original-preview/Build/Products/Release/PulseCanvas Studio.app"
./scripts/test-original-bundle.sh ".build/original-preview/Build/Products/Release/PulseCanvas Studio.app"

The app source includes an excluded historical engine adapter for file/API compatibility.
Current builds do not link the engine or bundle external presets/textures/recovered shaders.
Historical notices/manifests are retained separately and are not current app resources.
Engine-source/rebuild archives for historical distributions remain preserved in the checkout;
they are not dependencies of this original-Metal snapshot and are not included here.
The application license is source-available noncommercial. Read LICENSE and docs/licensing.md.
Only the current native checks in docs/ORIGINAL-VISUALS-EXPANSION.md apply to this edition.
Legacy external-engine and removed-geometry test scripts are historical and are not run.
''')
manifest={str(p.relative_to(stage)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(stage.rglob('*')) if p.is_file()}
revision=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
(stage/'SNAPSHOT.json').write_text(json.dumps({'schema':1,'revisionBeforeChanges':revision,'uncommitted':True,'activeEffects':188,'newEffects':100,'retiredNativeIDs':[0,1,2,3,5,6,7,8,9,11,13,14],'files':manifest},indent=2)+'\n')
archive=out/'PulseCanvas-original188-development-source.tar.gz'
with tarfile.open(archive,'w:gz') as t:t.add(stage,arcname=stage.name)
with tarfile.open(archive,'r:gz') as t:
 for name,digest in manifest.items():
  data=t.extractfile(stage.name+'/'+name).read();assert hashlib.sha256(data).hexdigest()==digest,name
receipt={'archive':str(archive),'sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'filesVerified':len(manifest),'activeEffects':188,'newEffects':100,'recoveredShaders':0,'externalPresetFiles':0,'uncommittedDevelopmentSnapshot':True,'rebuiltFromArchive':False}
(out/'source-package-receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps(receipt,indent=2))
