#!/usr/bin/env python3
"""Verify actual flat tvOS/visionOS native-only distribution bundles."""
import argparse,hashlib,json,plistlib,re,subprocess
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__);p.add_argument('platform',choices=['tv','vision']);p.add_argument('app',type=Path);args=p.parse_args()
root=Path(__file__).resolve().parents[1];app=args.app;info=plistlib.loads((app/'Info.plist').read_bytes())
assert info['CFBundleIdentifier']=='com.protomota.pulsecanvas'
assert info['UIDeviceFamily']==([3] if args.platform=='tv' else [7])
config=(root/('tvOS' if args.platform=='tv' else 'visionOS')/'Release.xcconfig').read_text()
def setting(name):
 match=re.search(r'^'+re.escape(name)+r'\s*=\s*(\S+)',config,re.MULTILINE)
 assert match, name
 return match.group(1)
assert info['CFBundleShortVersionString']==setting('MARKETING_VERSION')
assert info['CFBundleVersion']==setting('CURRENT_PROJECT_VERSION')
assert info['ITSAppUsesNonExemptEncryption'] is False
assert (app/'Assets.car').is_file() and info.get('CFBundleIcons'), 'Compiled icon required'
payload=app/'NativeAssets';source=root/'Sources/PulseCanvas/Resources'
expected={x.name for x in source.glob('*.metal')}|{'Audio/PulseCanvas.mp3','NativeVisualizers.json'}
assert {x.relative_to(payload).as_posix() for x in payload.rglob('*') if x.is_file()}==expected
for relative in expected-{'NativeVisualizers.json'}: assert (payload/relative).read_bytes()==(source/relative).read_bytes(),relative
assert json.loads((payload/'NativeVisualizers.json').read_text())['activeCount']==336
assert (app/'Legal/PulseCanvas-LICENSE.txt').read_bytes()==(root/'LICENSE').read_bytes()
assert (app/'PrivacyInfo.xcprivacy').read_bytes()==(root/'macOS/PrivacyInfo.xcprivacy').read_bytes()
for x in app.rglob('*'):
 assert not (x.suffix.lower()=='.milk' or 'projectm' in x.name.lower() or 'sparkle' in x.name.lower()),x
 if x.suffix=='.json':
  d=json.loads(x.read_text());assert not (isinstance(d,dict) and ('stations' in d or 'tracks' in d)), 'Radio must remain server driven'
exe=app/info['CFBundleExecutable'];links=subprocess.check_output(['otool','-L',str(exe)],text=True).lower()
assert not any(x in links for x in ['projectm','sparkle','opengl'])
subprocess.run(['codesign','--verify','--deep','--strict',str(app)],check=True)
signature=subprocess.check_output(['codesign','-dv','--verbose=4',str(app)],stderr=subprocess.STDOUT,text=True)
assert 'Authority=Apple Distribution: Protomota, LLC (22HV69L32T)' in signature
profile=plistlib.loads(subprocess.check_output(['security','cms','-D','-i',str(app/'embedded.mobileprovision')]))
assert profile['TeamIdentifier']==['22HV69L32T'] and not profile['Entitlements']['get-task-allow']
assert profile['Entitlements']['application-identifier']=='22HV69L32T.com.protomota.pulsecanvas'
print(json.dumps({'platform':args.platform,'version':info['CFBundleShortVersionString'],'build':int(info['CFBundleVersion']),'nativeEffects':336,'exactNativeResources':True,'icons':True,'signedDistribution':True,'noExternalEngineOrCatalogs':True,'executableSHA256':hashlib.sha256(exe.read_bytes()).hexdigest()},indent=2))
