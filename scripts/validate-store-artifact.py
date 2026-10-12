#!/usr/bin/env python3
"""Fail closed on malformed store bundles; --local accepts the Apple Development sandbox test."""
import argparse, datetime, json, pathlib, plistlib, re, subprocess
p=argparse.ArgumentParser();m=p.add_mutually_exclusive_group();m.add_argument('--local',action='store_true');m.add_argument('--archive',action='store_true',help='Validate a signed archive before distribution export; its development signature may have no profile.');p.add_argument('app',type=pathlib.Path);a=p.parse_args()
root=a.app.resolve();info=plistlib.loads((root/'Contents/Info.plist').read_bytes())
exe=root/'Contents/MacOS'/info['CFBundleExecutable'];lib=root/'Contents/Frameworks/libprojectM.dylib'
assert info['LSMinimumSystemVersion']=='14.0'
release_config=(pathlib.Path(__file__).resolve().parent.parent/'macOS/Release.xcconfig').read_text()
expected_version=re.search(r'^MARKETING_VERSION\s*=\s*(\S+)',release_config,re.M).group(1)
expected_build=re.search(r'^CURRENT_PROJECT_VERSION\s*=\s*(\S+)',release_config,re.M).group(1)
assert info['CFBundleShortVersionString']==expected_version
assert info['CFBundleVersion']==expected_build
assert info['CFBundleIdentifier']==('com.protomota.pulsecanvas.storevalidation' if a.local else 'com.protomota.pulsecanvas')
for binary in [exe,lib]:
    arch=subprocess.check_output(['lipo','-archs',str(binary)],text=True).strip()
    assert arch=='arm64', (binary,arch)
subprocess.run(['codesign','--verify','--deep','--strict',str(root)],check=True)
raw=subprocess.check_output(['codesign','-d','--entitlements',':-',str(root)],stderr=subprocess.DEVNULL)
ent=plistlib.loads(raw[raw.index(b'<?xml'):])
for key in ['com.apple.security.app-sandbox','com.apple.security.files.user-selected.read-write','com.apple.security.files.bookmarks.app-scope']:
    assert ent.get(key) is True,key
assert not ent.get('com.apple.security.get-task-allow',False)
assert not any(ent.get(k) for k in ['com.apple.security.network.client','com.apple.security.network.server','com.apple.security.device.audio-input','com.apple.security.cs.disable-library-validation'])
assert not any('temporary-exception' in k for k in ent)
for binary in [root,lib]:
    sig=subprocess.check_output(['codesign','-dv','--verbose=4',str(binary)],stderr=subprocess.STDOUT,text=True)
    assert 'TeamIdentifier=22HV69L32T' in sig and 'runtime' in sig,sig
if not a.local and not a.archive:
    assert (root/'Contents/embedded.provisionprofile').exists(),'Provisioning profile missing'
    assert any(s in subprocess.check_output(['codesign','-dv','--verbose=4',str(root)],stderr=subprocess.STDOUT,text=True) for s in ['Authority=Apple Distribution:', 'Authority=3rd Party Mac Developer Application:']),'App Store distribution signature required'
    profile=plistlib.loads(subprocess.check_output(['security','cms','-D','-i',str(root/'Contents/embedded.provisionprofile')]))
    assert profile['TeamIdentifier']==['22HV69L32T']
    assert profile['Entitlements']['com.apple.application-identifier']=='22HV69L32T.com.protomota.pulsecanvas'
    assert not profile['Entitlements'].get('com.apple.security.get-task-allow',False)
    assert not profile.get('ProvisionedDevices') and not profile.get('ProvisionsAllDevices',False),'App Store profile required'
    assert profile['ExpirationDate'] > datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None),'Provisioning profile expired'
res=root/'Contents/Resources';privacy=plistlib.loads((res/'PrivacyInfo.xcprivacy').read_bytes())
assert not privacy['NSPrivacyTracking'] and not privacy['NSPrivacyCollectedDataTypes']
source_resources=pathlib.Path(__file__).resolve().parent.parent/'Sources/PulseCanvas/Resources'
active_shaders={p.name for p in (source_resources/'VisualShaders').glob('*.ll')}
bundled_shaders={p.name for p in (res/'Resources/VisualShaders').glob('*.ll')}
assert len(active_shaders)==13 and bundled_shaders==active_shaders,'Retired shader modules must not be bundled'
for f in ['AppIcon.icns','Legal/ProjectM-LGPL-2.1.txt','Legal/PulseCanvas-LICENSE.txt']:
    assert (res/f).is_file(),f
assert (res/'Legal/PulseCanvas-LICENSE.txt').read_bytes() == (pathlib.Path(__file__).resolve().parent.parent/'LICENSE').read_bytes(),'Bundled application license must match the release source'
assert not (res/'Legal/PulseCanvas-MIT-LICENSE.txt').exists(),'Obsolete application-license copy must not be bundled'
catalog=json.loads((res/'Resources/ProjectM/catalog.json').read_text())
assert len(catalog)==7838
assert all((res/'Resources/ProjectM/Presets'/item['path']).is_file() for item in catalog)
subprocess.run(['python3', str(pathlib.Path(__file__).resolve().parent/'preset-provenance.py'), '--app', str(root)], check=True)
print(json.dumps({'bundle':info['CFBundleIdentifier'],'version':info['CFBundleShortVersionString'],'build':info['CFBundleVersion'],'architecture':'arm64','sandbox':True,'presets':len(catalog),'nativeVisualizers':31,'signing': 'Apple Development local test' if a.local else ('team-signed archive; distribution export required' if a.archive else 'App Store distribution signature; Apple processing status checked separately')},indent=2))
