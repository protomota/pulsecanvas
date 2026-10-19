#!/usr/bin/env python3
"""Fail closed on malformed store bundles; --local accepts the Apple Development sandbox test."""
import argparse, datetime, hashlib, json, pathlib, plistlib, re, subprocess
p=argparse.ArgumentParser();m=p.add_mutually_exclusive_group();m.add_argument('--local',action='store_true');m.add_argument('--archive',action='store_true',help='Validate a signed archive before distribution export; its development signature may have no profile.');p.add_argument('app',type=pathlib.Path);a=p.parse_args()
root=a.app.resolve();info=plistlib.loads((root/'Contents/Info.plist').read_bytes())
exe=root/'Contents/MacOS'/info['CFBundleExecutable']
assert info['LSMinimumSystemVersion']=='14.0'
config_root=pathlib.Path(__file__).resolve().parent.parent
release_config=(config_root/'Version.xcconfig').read_text()+'\n'+(config_root/'macOS/Release.xcconfig').read_text()
expected_version=re.search(r'^MARKETING_VERSION\s*=\s*(\S+)',release_config,re.M).group(1)
expected_build=re.search(r'^CURRENT_PROJECT_VERSION\s*=\s*(\S+)',release_config,re.M).group(1)
assert info['CFBundleShortVersionString']==expected_version
assert info['CFBundleVersion']==expected_build
assert info['CFBundleIdentifier']==('com.protomota.pulsecanvas.storevalidation' if a.local else 'com.protomota.pulsecanvas')
for binary in [exe]:
    arch=subprocess.check_output(['lipo','-archs',str(binary)],text=True).strip()
    assert arch=='arm64', (binary,arch)
subprocess.run(['codesign','--verify','--deep','--strict',str(root)],check=True)
raw=subprocess.check_output(['codesign','-d','--entitlements',':-',str(root)],stderr=subprocess.DEVNULL)
ent=plistlib.loads(raw[raw.index(b'<?xml'):])
for key in ['com.apple.security.app-sandbox','com.apple.security.files.user-selected.read-write','com.apple.security.files.bookmarks.app-scope']:
    assert ent.get(key) is True,key
assert not ent.get('com.apple.security.get-task-allow',False)
# Radio downloads the public catalog and tracks; incoming connections remain disabled.
assert ent.get('com.apple.security.network.client') is True
assert not any(ent.get(k) for k in ['com.apple.security.network.server','com.apple.security.device.audio-input','com.apple.security.cs.disable-library-validation'])
assert not any('temporary-exception' in k for k in ent)
for binary in [root]:
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
# Every visual is compiled from PulseCanvas Metal sources; no prebuilt shader modules ship.
assert not list(res.rglob('*.ll')) and not list(res.rglob('VisualShaders*')),'Retired shader modules must not be bundled'
for f in ['AppIcon.icns','Legal/Edition.txt','Legal/PulseCanvas-LICENSE.txt']:
    assert (res/f).is_file(),f
assert (res/'Legal/PulseCanvas-LICENSE.txt').read_bytes() == (pathlib.Path(__file__).resolve().parent.parent/'LICENSE').read_bytes(),'Bundled application license must match the release source'
assert not (res/'Legal/PulseCanvas-MIT-LICENSE.txt').exists(),'Obsolete application-license copy must not be bundled'
# Inspect the actual app, including nested resources and executable imports.
assert not list(root.rglob('*.milk')), 'OpenGL presets must not be bundled'
assert not any('projectm' in path.name.lower() or path.name == 'Sparkle.framework' for path in root.rglob('*')), 'Excluded engine/updater resource found'
assert not any(key.startswith(('SU', 'SPU')) for key in info), 'Sparkle settings must not enter store builds'
imports=subprocess.check_output(['otool','-L',str(exe)],text=True)
assert 'OpenGL.framework' not in imports and 'Sparkle' not in imports and 'libprojectM' not in imports, imports
symbols=subprocess.check_output(['nm','-u',str(exe)],text=True)
assert 'CGLCreateContext' not in symbols and '_projectm_' not in symbols, 'OpenGL engine symbols found'
native_catalog = res/'Resources/NativeVisualizers.json'
if native_catalog.is_file():
    catalog = json.loads(native_catalog.read_text())
    slots = catalog['nativeCount']
    assert catalog['schema'] == 1 and slots == len(catalog['effects'])
    assert [e['id'] for e in catalog['effects']] == [f'native:{i}' for i in range(slots)]
    assert [e['scene'] for e in catalog['effects']] == list(range(slots))
    # Retired designs keep their IDs for migration; the edition counts offered designs.
    offered = [e for e in catalog['effects'] if not e.get('retired')]
    count = catalog.get('activeCount', slots)
    assert count == len(offered) and len({e['name'] for e in offered}) == count
    for shader, digest in catalog['shaders'].items():
        assert pathlib.Path(shader).name == shader
        assert hashlib.sha256((res/'Resources'/shader).read_bytes()).hexdigest() == digest, shader
else:
    # Historical 1.0.2 (10) predates native catalog expansion; inspect its own
    # edition receipt rather than claiming it contains newly developed effects.
    count = 31
assert f'{count} native Metal visualizers' in (res/'Legal/Edition.txt').read_text()
print(json.dumps({'bundle':info['CFBundleIdentifier'],'version':info['CFBundleShortVersionString'],'build':info['CFBundleVersion'],'architecture':'arm64','sandbox':True,'presets':0,'nativeVisualizers':count,'edition':'metal','sparkle':False,'openGL':False,'signing': 'Apple Development local test' if a.local else ('team-signed archive; distribution export required' if a.archive else 'App Store distribution signature; Apple processing status checked separately')},indent=2))
