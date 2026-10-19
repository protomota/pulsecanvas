#!/usr/bin/env python3
"""Generate the deterministic, dependency-free macOS Xcode app project."""
from pathlib import Path
import hashlib
import json

root = Path(__file__).resolve().parent.parent
objects = {}
def ident(label): return hashlib.sha256(label.encode()).hexdigest()[:24].upper()
def obj(label, isa, **fields):
    key = ident(label)
    objects[key] = dict(isa=isa, **fields)
    return key
def ref(path, kind):
    return obj('file:'+path, 'PBXFileReference', lastKnownFileType=kind, path=path, sourceTree='<group>')
def build(key): return obj('build:'+key, 'PBXBuildFile', fileRef=key)
def phase(label, isa, files): return obj(label, isa, buildActionMask=2147483647, files=files, runOnlyForDeploymentPostprocessing=0)

sources = sorted(str(p.relative_to(root)) for p in (root/'Sources/PulseCanvas').glob('*.swift') if p.name not in ['ProjectMEngine.swift', 'AppUpdater.swift']) + ['macOS/BundleResources.swift']
source_refs = [ref(p,'sourcecode.swift') for p in sources]
resources = [ref('.build/store-resources/Resources','folder'),ref('.build/store-resources/AppIcon.icns','image.icns'),ref('.build/store-resources/Legal','folder'),ref('macOS/PrivacyInfo.xcprivacy','text.xml')]
config = ref('macOS/Release.xcconfig','text.xcconfig')
other_refs = [ref('Version.xcconfig','text.xcconfig'), config, ref('macOS/Info.plist','text.plist.xml'),ref('macOS/PulseCanvas.entitlements','text.plist.entitlements')]
product = obj('product','PBXFileReference',explicitFileType='wrapper.application',path='PulseCanvas Studio.app',sourceTree='BUILT_PRODUCTS_DIR',includeInIndex=0)
products = obj('products','PBXGroup',children=[product],name='Products',sourceTree='<group>')
group = obj('main','PBXGroup',children=source_refs+resources+other_refs+[products],sourceTree='<group>')
prepare = obj('prepare','PBXShellScriptBuildPhase',buildActionMask=2147483647,files=[],inputPaths=[],outputPaths=[],runOnlyForDeploymentPostprocessing=0,shellPath='/bin/bash',shellScript='"$SRCROOT/scripts/prepare-store-resources.sh"\n',name='Prepare Metal-only resources, icon and notices',alwaysOutOfDate=1)
srcphase=phase('sources','PBXSourcesBuildPhase',[build(k) for k in source_refs])
resphase=phase('resources','PBXResourcesBuildPhase',[build(k) for k in resources])
frameworkphase=phase('frameworks','PBXFrameworksBuildPhase',[])
def configs(label,target=False):
    keys=[]
    for name in ['Debug','Release']:
        settings={'SDKROOT':'macosx','CLANG_ENABLE_MODULES':'YES'}
        if target:
            settings.update(SWIFT_OPTIMIZATION_LEVEL='-Onone' if name=='Debug' else '-O',DEBUG_INFORMATION_FORMAT='dwarf' if name=='Debug' else 'dwarf-with-dsym',SWIFT_EMIT_LOC_STRINGS='NO')
        keys.append(obj(label+name,'XCBuildConfiguration',buildSettings=settings,name=name,**({'baseConfigurationReference':config} if target else {})))
    return obj(label+'list','XCConfigurationList',buildConfigurations=keys,defaultConfigurationIsVisible=0,defaultConfigurationName='Release')
target=obj('target','PBXNativeTarget',buildConfigurationList=configs('targetconfig',True),buildPhases=[prepare,srcphase,frameworkphase,resphase],buildRules=[],dependencies=[],name='PulseCanvas',productName='PulseCanvas Studio',productReference=product,productType='com.apple.product-type.application')
project=obj('project','PBXProject',attributes={'LastUpgradeCheck':'2700','TargetAttributes':{target:{'CreatedOnToolsVersion':'27.0','ProvisioningStyle':'Automatic','SystemCapabilities':{'com.apple.Sandbox':{'enabled':1}}}}},buildConfigurationList=configs('projectconfig'),compatibilityVersion='Xcode 14.0',developmentRegion='en',hasScannedForEncodings=0,knownRegions=['en','Base'],mainGroup=group,productRefGroup=products,projectDirPath='',projectRoot='',targets=[target])
def encode(v,level=0):
    if isinstance(v,dict): return '{\n'+''.join('\t'*(level+1)+json.dumps(str(k))+' = '+encode(x,level+1)+';\n' for k,x in v.items())+'\t'*level+'}'
    if isinstance(v,list): return '(\n'+''.join('\t'*(level+1)+encode(x,level+1)+',\n' for x in v)+'\t'*level+')'
    if isinstance(v,int):return str(v)
    return json.dumps(v,ensure_ascii=False)
folder=root/'PulseCanvas.xcodeproj'
folder.mkdir(exist_ok=True)
(folder/'project.pbxproj').write_text('// !$*UTF8*$!\n'+encode(dict(archiveVersion=1,classes={},objectVersion=56,objects=objects,rootObject=project))+'\n')
scheme=folder/'xcshareddata/xcschemes/PulseCanvas.xcscheme'
scheme.parent.mkdir(parents=True,exist_ok=True)
reference=f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="PulseCanvas Studio.app" BlueprintName="PulseCanvas" ReferencedContainer="container:PulseCanvas.xcodeproj"/>'
scheme.write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2700" version="1.3">
 <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{reference}</BuildActionEntry></BuildActionEntries></BuildAction>
 <TestAction buildConfiguration="Debug"/>
 <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="NO"><BuildableProductRunnable runnableDebuggingMode="0">{reference}</BuildableProductRunnable></LaunchAction>
 <ProfileAction buildConfiguration="Release"><BuildableProductRunnable runnableDebuggingMode="0">{reference}</BuildableProductRunnable></ProfileAction>
 <AnalyzeAction buildConfiguration="Debug"/>
 <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
''')
print(folder)
