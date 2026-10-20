#!/usr/bin/env python3
"""Generate an independent tvOS target without modifying the Mac project."""
from pathlib import Path
import hashlib
import json

root = Path(__file__).resolve().parents[1]
objects = {}
def obj(label, isa, **values):
    key = hashlib.sha256(label.encode()).hexdigest()[:24].upper()
    objects[key] = dict(isa=isa, **values)
    return key
def ref(path, kind):
    return obj('file:' + path, 'PBXFileReference', lastKnownFileType=kind, path=path, sourceTree='<group>')
def build(key): return obj('build:' + key, 'PBXBuildFile', fileRef=key)
shared = ['VisualPreset', 'VisualPalette', 'OriginalGeometry', 'NativeEffects', 'ProjectMPresets', 'StrobeDetector',
          'VisualizerRenderer', 'AudioAnalysis', 'StudioTimeline', 'SecurityScopedAccess']
sources = ['Sources/PulseCanvas/' + name + '.swift' for name in shared] + ['macOS/BundleResources.swift']
sources += ['visionOS/VisionLookPreset.swift', 'visionOS/VisionStudio.swift', 'visionOS/VisionProject.swift', 'Sources/PulseCanvas/RadioLibrary.swift']
sources += sorted(str(p.relative_to(root)) for p in (root / 'tvOS').glob('*.swift'))
source_refs = [ref(p, 'sourcecode.swift') for p in sources]
resources = [ref('tvOS/Assets.xcassets', 'folder.assetcatalog'), ref('.build/tv-resources/NativeAssets', 'folder'), ref('.build/tv-resources/Legal', 'folder'),
             ref('macOS/PrivacyInfo.xcprivacy', 'text.xml')]
config = ref('tvOS/Release.xcconfig', 'text.xcconfig')
info = ref('tvOS/Info.plist', 'text.plist.xml')
product = obj('product', 'PBXFileReference', explicitFileType='wrapper.application', path='PulseCanvas TV.app', sourceTree='BUILT_PRODUCTS_DIR')
products = obj('products', 'PBXGroup', children=[product], name='Products', sourceTree='<group>')
group = obj('main', 'PBXGroup', children=source_refs + resources + [config, info, products], sourceTree='<group>')
prepare = obj('prepare', 'PBXShellScriptBuildPhase', buildActionMask=2147483647, files=[], inputPaths=[], outputPaths=[],
    runOnlyForDeploymentPostprocessing=0, shellPath='/bin/bash', shellScript='"$SRCROOT/scripts/prepare-tv-resources.sh"\n',
    name='Prepare native Metal resources only', alwaysOutOfDate=1)
def phase(label, isa, files): return obj(label, isa, buildActionMask=2147483647, files=files, runOnlyForDeploymentPostprocessing=0)
phases = [prepare, phase('sources', 'PBXSourcesBuildPhase', [build(k) for k in source_refs]),
          phase('frameworks', 'PBXFrameworksBuildPhase', []), phase('resources', 'PBXResourcesBuildPhase', [build(k) for k in resources])]
def configurations(label, target=False):
    keys = []
    for name in ['Debug', 'Release']:
        values = dict(SDKROOT='appletvos', CLANG_ENABLE_MODULES='YES')
        if target: values.update(SWIFT_OPTIMIZATION_LEVEL='-Onone' if name == 'Debug' else '-O', SWIFT_EMIT_LOC_STRINGS='NO')
        keys.append(obj(label + name, 'XCBuildConfiguration', buildSettings=values, name=name,
                        **({'baseConfigurationReference': config} if target else {})))
    return obj(label + 'list', 'XCConfigurationList', buildConfigurations=keys, defaultConfigurationIsVisible=0, defaultConfigurationName='Release')
target = obj('target', 'PBXNativeTarget', buildConfigurationList=configurations('targetConfig', True), buildPhases=phases,
    buildRules=[], dependencies=[], name='PulseCanvasTV', productName='PulseCanvas TV', productReference=product,
    productType='com.apple.product-type.application')
project = obj('project', 'PBXProject', attributes={'LastUpgradeCheck': '2700'}, buildConfigurationList=configurations('projectConfig'),
    compatibilityVersion='Xcode 14.0', developmentRegion='en', hasScannedForEncodings=0, knownRegions=['en', 'Base'],
    mainGroup=group, productRefGroup=products, projectDirPath='', projectRoot='', targets=[target])
def encode(value, level=0):
    if isinstance(value, dict):
        return '{\n' + ''.join('\t' * (level + 1) + json.dumps(k) + ' = ' + encode(v, level + 1) + ';\n' for k, v in value.items()) + '\t' * level + '}'
    if isinstance(value, list): return '(\n' + ''.join('\t' * (level + 1) + encode(v, level + 1) + ',\n' for v in value) + '\t' * level + ')'
    return str(value) if isinstance(value, int) else json.dumps(value)
folder = root / 'PulseCanvasTV.xcodeproj'
folder.mkdir(exist_ok=True)
(folder / 'project.pbxproj').write_text('// !$*UTF8*$!\n' + encode(dict(archiveVersion=1, classes={}, objectVersion=56, objects=objects, rootObject=project)) + '\n')
scheme = folder / 'xcshareddata/xcschemes/PulseCanvasTV.xcscheme'
scheme.parent.mkdir(parents=True, exist_ok=True)
reference = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="PulseCanvas TV.app" BlueprintName="PulseCanvasTV" ReferencedContainer="container:PulseCanvasTV.xcodeproj"/>'
scheme.write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2700" version="1.3">
 <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{reference}</BuildActionEntry></BuildActionEntries></BuildAction>
 <TestAction buildConfiguration="Debug"/>
 <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{reference}</BuildableProductRunnable></LaunchAction>
 <ProfileAction buildConfiguration="Release"><BuildableProductRunnable runnableDebuggingMode="0">{reference}</BuildableProductRunnable></ProfileAction>
 <AnalyzeAction buildConfiguration="Debug"/>
 <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
''')
print(folder)
