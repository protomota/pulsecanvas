import Foundation
import AVFoundation
import Metal
import CoreGraphics
import AppKit

private struct StoredStylesFixture: Codable { let presets: [Int:VisualPreset]; let identities: [Int:String]? }
@main struct ProjectMIntegrationSmoke {
    @MainActor static func main() async throws {
        let root = URL(fileURLWithPath:".build/validation/projectm-integration-"+UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let suiteName = "PulseCanvas.ProjectM.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName:suiteName)!
        defer {defaults.removePersistentDomain(forName:suiteName)}
        var library = ProjectMPresets(importedRoot:root.appendingPathComponent("Imported"), defaults:defaults)
        let report = try JSONSerialization.jsonObject(with:Data(contentsOf:library.bundledRoot.appendingPathComponent("compatibility-report.json"))) as! [String:Any]
        let countRetained = report["retained"] as! Int
        let nativeCount = RenderState.nativeSceneNames.count
        precondition(library.entries.count == countRetained && library.sceneNames.count == countRetained + nativeCount)
        precondition(library.availableScenes.count == countRetained + NativeEffects.activeIDs.count)
        let fixtureScene = library.scene(for:"projectm:Dancer/Glowsticks/EoS - glowsticks v2 04 music minimal (benjam's tracer mix).milk")!
        let secondScene = library.scene(for:"projectm:Dancer/Comet Mirror/EoS + Phat - chasers 14 sentinel 616_1.milk")!
        precondition(library.sceneNames[fixtureScene] == "Mosaic Nova")
        let duplicatedNames = Dictionary(grouping: library.sceneNames, by: { $0 }).filter { $0.value.count > 1 }.keys.sorted()
        if !duplicatedNames.isEmpty { FileHandle.standardError.write(Data("Duplicate display names: \(duplicatedNames)\n".utf8)) }
        precondition(duplicatedNames.isEmpty, "Every preset needs a unique display name")
        precondition(library.entries.allSatisfy {$0.title.split(separator:" ").count == 2 && $0.originalTitle != nil && $0.icon != nil})
        let icons = Set(library.sceneNames.indices.map {library.icon(for:$0)})
        let invalidIcons = icons.filter { NSImage(systemSymbolName: $0, accessibilityDescription: nil) == nil }.sorted()
        if !invalidIcons.isEmpty { FileHandle.standardError.write(Data("Invalid icons: \(invalidIcons)\n".utf8)) }
        precondition(icons.isSuperset(of: Set(library.iconNames)) && invalidIcons.isEmpty)
        precondition(NativeEffects.activeIDs.allSatisfy { library.icon(for: $0) == NativeEffects.all[$0].icon }, "Native visualizers must use their registered icons")
        precondition(library.categories.contains("Fractal") && library.categories.contains("Waveform"))
        precondition(!library.categories.contains("Transitions") && !library.categories.contains("! Transition"))
        library.toggleFavorite(fixtureScene); library.toggleFavorite(22)
        let restored = ProjectMPresets(importedRoot:root.appendingPathComponent("Imported"), defaults:defaults)
        precondition(restored.isFavorite(fixtureScene) && restored.isFavorite(22))
        library.toggleFavorite(fixtureScene); precondition(!library.isFavorite(fixtureScene))
        // Existing imported libraries must remain readable even though the app
        // no longer exposes an import action. Write an old-format disk fixture.
        let previousNames = library.sceneNames
        let pack = library.importedRoot.appendingPathComponent("FixturePack")
        try FileManager.default.createDirectory(at:pack.appendingPathComponent("Waves"),withIntermediateDirectories:true)
        let preset = ProjectMPresets.shared.preset(for:fixtureScene)!
        try FileManager.default.copyItem(at:ProjectMPresets.shared.url(for:preset),to:pack.appendingPathComponent("Waves/Fixture.milk"))
        try Data([0,1,2]).write(to:pack.appendingPathComponent("Waves/texture.png"))
        let imported = ProjectMPreset(id:"import:FixturePack/Waves/Fixture.milk",path:"FixturePack/Waves/Fixture.milk",title:"Fixture Wave",category:"Imported · FixturePack",originalTitle:"Fixture",icon:"waveform")
        try JSONEncoder().encode([imported]).write(to:library.importedRoot.appendingPathComponent("imports.json"))
        library = ProjectMPresets(importedRoot:library.importedRoot,defaults:defaults)
        let scene = library.scene(for:imported.id)!
        precondition(Array(library.sceneNames.prefix(previousNames.count)) == previousNames)
        precondition(scene == countRetained + nativeCount && library.url(for:imported).lastPathComponent == "Fixture.milk")
        precondition(FileManager.default.fileExists(atPath:library.url(for:imported).deletingLastPathComponent().appendingPathComponent("texture.png").path))
        let restoredImport = ProjectMPresets(importedRoot:library.importedRoot, defaults:defaults)
        precondition(restoredImport.scene(for:imported.id) == scene)
        precondition(restoredImport.isFavorite(22))
        let ids = library.identities(for:[0,fixtureScene,scene]); precondition(ids.count == 3 && ids[scene] == imported.id && ids[0] == "native:0")
        let firstLegacy = legacyPresetID(library)
        let movedExternal = try library.migratedScene(31, identities: [31: firstLegacy])
        precondition(movedExternal == library.scene(for: firstLegacy) && movedExternal >= nativeCount)
        let newNative = try library.migratedScene(31, identities: [31: "native:31"])
        precondition(newNative == 31)
        print("PASS Library: all presets indexed, categories, stable identities, persistent favorites and legacy imports with textures")

        let legacy = try JSONDecoder().decode([String].self,from:Data(contentsOf:library.bundledRoot.appendingPathComponent("legacy-identities.json")))
        let oldFixture = legacy.firstIndex(of:library.identity(for:fixtureScene))! + 31
        let retiredID = "projectm:Fractal/Blobby/va ultramix2 - 28.milk"
        let oldRetired = legacy.firstIndex(of:retiredID)! + 31
        precondition(library.scene(for:retiredID) == nil && library.retiredIDs.contains(retiredID))
        var nativeAppearance = VisualPreset(); nativeAppearance.chaos = 0.22
        var fixtureAppearance = VisualPreset(); fixtureAppearance.chaos = 0.42
        let original = CreatorProject(scene:oldRetired,appearance:VisualPreset(),aspect:SocialAspect.landscape.rawValue,resolution:1080,fps:60,
            timeline:[StudioSegment(start:0,end:8,scene:oldFixture),StudioSegment(start:8,end:16,scene:oldRetired),StudioSegment(start:16,end:24,scene:22)],
            studioEnabled:true,visualPresets:[oldFixture:fixtureAppearance,oldRetired:VisualPreset(),22:nativeAppearance],
            effectIdentities:[oldFixture:library.identity(for:fixtureScene),oldRetired:retiredID])
        for useIdentities in [true,false] {
            var project = original; if !useIdentities {project.effectIdentities = nil}
            defaults.set(try JSONEncoder().encode(StoredStylesFixture(presets:project.visualPresets!,identities:project.effectIdentities)),forKey:"PulseCanvas.studio.v1")
            let migratedStore = StudioStore(defaults:defaults)
            precondition(migratedStore.presets.count == 2 && migratedStore.presets[fixtureScene]?.chaos == 0.42 && migratedStore.presets[22]?.chaos == 0.22)
            let migrated = try project.remapped(using:library)
            precondition(migrated.scene == 22 && migrated.timeline?.map(\.scene) == [fixtureScene,22,22])
            precondition(migrated.appearance.chaos == 0.22, "The selected retired effect must use the saved fallback appearance")
            precondition(migrated.timeline?.map {[$0.start,$0.end]} == [[0,8],[8,16],[16,24]])
            precondition(migrated.visualPresets?.count == 2 && migrated.visualPresets?[fixtureScene]?.chaos == 0.42 && migrated.visualPresets?[22]?.chaos == 0.22)
        }
        var missingImport = original; missingImport.effectIdentities = [oldFixture:library.identity(for:fixtureScene),oldRetired:"import:missing/preset.milk"]
        do {_ = try missingImport.remapped(using:library); fatalError("Missing user imports must report an error")} catch is ProjectMError {}
        let preview = ProjectMPreviewSize.dimensions(width:3840,height:2160)
        let portraitPreview = ProjectMPreviewSize.dimensions(width:2160,height:3840)
        precondition(preview.width == 1280 && preview.height == 720 && portraitPreview.width == 720 && portraitPreview.height == 1280)
        precondition(ProjectMPreviewSize.dimensions(width:577,height:325).width == 577)
        print("PASS retirement migration: stable IDs and older numeric indices retain styles; retired clips fall back without collisions, boundaries unchanged; missing imports report errors")
        print("PASS preview sizing: capped for Retina performance; aspect ratio and small canvases retained")

        let audioURL = root.appendingPathComponent("soundtrack.wav")
        let format = AVAudioFormat(standardFormatWithSampleRate:48000,channels:2)!
        let buffer = AVAudioPCMBuffer(pcmFormat:format,frameCapacity:115200)!
        buffer.frameLength = 115200
        for frame in 0..<115200 {
            let t = Double(frame)/48000
            let envelope = exp(-fmod(t,0.25)*20)
            buffer.floatChannelData![0][frame] = Float(sin(t*2*Double.pi*180)*envelope*0.85)
            buffer.floatChannelData![1][frame] = Float(sin(t*2*Double.pi*660)*envelope*0.7)
        }
        do {let audio = try AVAudioFile(forWriting:audioURL,settings:format.settings); try audio.write(from:buffer)}
        let analysis = try SoundtrackAnalyzer(url:audioURL)
        let beginning = try analysis.pcm(at:0)
        precondition(beginning.allSatisfy {$0 == 0})
        let pcm = try analysis.pcm(at:0.1)
        precondition(pcm.count == 2048 && pcm.contains {$0 != 0})
        precondition(stride(from:0,to:pcm.count,by:2).contains {pcm[$0] != pcm[$0+1]})
        print("PASS audio: 48 kHz source resamples to stereo 44.1 kHz; no lookahead before track start")

        let state = RenderState(), renderer = VisualizerRenderer(state:state)
        state.scene = fixtureScene; state.chaos = 1; state.zoomSpeed = 0
        try renderer.prepareOffscreen(width:320,height:180)
        var last: MTLTexture?
        for frame in 0..<60 {
            let t = Double(frame)/60
            state.audioPCM = try analysis.pcm(at:t)
            last = try renderer.renderOffscreen(time:t,audioBands:[],audioPulse:0)
        }
        var pixels = [UInt8](repeating:0,count:320*180*4)
        last!.getBytes(&pixels,bytesPerRow:320*4,from:MTLRegionMake2D(0,0,320,180),mipmapLevel:0)
        precondition(stride(from:0,to:pixels.count,by:4).contains {max(pixels[$0],pixels[$0+1],pixels[$0+2]) > 20})
        print("PASS rendering: preset equations, waves and feedback produce GPU output through the Metal compositor")
        for (width, height) in [(577,325),(513,287),(63,99),(719,959),(3840,2160)] {
            try renderer.prepareOffscreen(width:width,height:height)
            let texture = try renderer.renderOffscreen(time:1.1,audioBands:[],audioPulse:0)
            precondition(texture.width == width && texture.height == height)
        }
        print("PASS shared GPU surfaces: arbitrary window widths, portrait and 4K render without stride validation failures")
        // Save and restore the user's format settings, which this test changes only temporarily.
        let formatKey = "PulseCanvas.videoFormat.v1", savedFormat = UserDefaults.standard.data(forKey:formatKey)
        defer {if let savedFormat {UserDefaults.standard.set(savedFormat,forKey:formatKey)} else {UserDefaults.standard.removeObject(forKey:formatKey)}}
        let export = SocialExportController(); export.resolution = 720; export.fps = 30; export.aspect = .portrait
        let destination = root.appendingPathComponent("studio.mp4")
        let sections = [StudioSegment(start:0,end:0.8,scene:fixtureScene),StudioSegment(start:0.8,end:1.6,scene:22),StudioSegment(start:1.6,end:2.4,scene:secondScene)]
        var appearance = VisualPreset(); appearance.chaos = 1; appearance.zoomSpeed = 0
        await export.export(audioURL:audioURL,render:state,to:destination,segments:sections,appearances:[fixtureScene:appearance,22:appearance,secondScene:appearance])
        precondition(export.exportedURL == destination, export.status)
        let asset = AVURLAsset(url:destination)
        let duration = try await asset.load(.duration).seconds
        let video = try await asset.loadTracks(withMediaType:.video)
        let tracks = try await asset.loadTracks(withMediaType:.audio)
        precondition(!tracks.isEmpty && !video.isEmpty && abs(duration-2.4)<0.05)
        let dimensions = try await video[0].load(.naturalSize)
        precondition(dimensions.width == 720 && dimensions.height == 960)
        let generator = AVAssetImageGenerator(asset:asset)
        for timestamp in [0.6,1.4,2.2] {
            let result = try await generator.image(at:CMTime(seconds:timestamp,preferredTimescale:600))
            precondition(result.image.width == 720 && result.image.height == 960)
            var decoded = [UInt8](repeating:0,count:64*64*4)
            decoded.withUnsafeMutableBytes { bytes in
                let context = CGContext(data:bytes.baseAddress,width:64,height:64,bitsPerComponent:8,bytesPerRow:64*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
                context.draw(result.image,in:CGRect(x:0,y:0,width:64,height:64))
            }
            precondition(stride(from:0,to:decoded.count,by:4).contains {max(decoded[$0],decoded[$0+1],decoded[$0+2]) > 20}, "Section \(timestamp) must contain visible exported graphics")
        }
        print("PASS export: portrait MP4 decodes all three Studio sections across ProjectM / Metal / ProjectM, includes soundtrack, correct duration and dimensions")

        // These effects went black only after a preceding preset left its clock
        // and audio history in the shared engine. Check their actual 4K MP4 frames.
        let transitionIDs = [
            "projectm:Waveform/Wire Flat Double/suksma - demonizer - a shot.milk",
            "projectm:Dancer/Comet Mirror/beta106S + Phat - sentinel linearity b nz+ ski mbullox.milk",
            "projectm:Waveform/Wire Circular/phinjamain.milk",
            "projectm:Fractal/Nested Spiral/Stahlregen - Spiral Beats (Fluctuating Flowers).milk"
        ]
        let transitionScenes = [fixtureScene] + transitionIDs.map { library.scene(for: $0)! }
        let transitionSections = transitionScenes.enumerated().map {
            StudioSegment(start: Double($0.offset) * 0.48, end: Double($0.offset + 1) * 0.48, scene: $0.element)
        }
        export.resolution = 2160; export.fps = 60; export.aspect = .wide
        let transitionDestination = root.appendingPathComponent("transitions-4k.mp4")
        await export.export(audioURL: audioURL, render: state, to: transitionDestination, segments: transitionSections,
            appearances: Dictionary(uniqueKeysWithValues: transitionScenes.map { ($0, appearance) }))
        precondition(export.exportedURL == transitionDestination, export.status)
        let transitionAsset = AVURLAsset(url: transitionDestination)
        let transitionGenerator = AVAssetImageGenerator(asset: transitionAsset)
        transitionGenerator.requestedTimeToleranceBefore = .zero; transitionGenerator.requestedTimeToleranceAfter = .zero
        for (index, section) in transitionSections.enumerated() {
            let result = try await transitionGenerator.image(at: CMTime(seconds: section.start + 0.4, preferredTimescale: 600))
            precondition(result.image.width == 3840 && result.image.height == 2160)
            var decoded = [UInt8](repeating: 0, count: 128 * 72 * 4)
            decoded.withUnsafeMutableBytes { bytes in
                let context = CGContext(data: bytes.baseAddress, width: 128, height: 72, bitsPerComponent: 8, bytesPerRow: 128 * 4,
                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
                context.draw(result.image, in: CGRect(x: 0, y: 0, width: 128, height: 72))
            }
            let visible = stride(from: 0, to: decoded.count, by: 4).filter { max(decoded[$0], decoded[$0 + 1], decoded[$0 + 2]) > 24 }.count
            print("4K section \(index + 1), \(library.sceneNames[section.scene]): \(visible)/9216 visible pixels"); fflush(stdout)
            precondition(visible > 128 * 72 / 100, "4K section \(index + 1), \(library.sceneNames[section.scene]), must contain visible graphics")
        }
        print("PASS 4K/60 export: decoded Tangled Weave, Crimson Spark, Temporal Flame and Spiral Helix after consecutive ProjectM switches")
    }
    @MainActor private static func legacyPresetID(_ library: ProjectMPresets) -> String {
        library.entries[0].id
    }
}
