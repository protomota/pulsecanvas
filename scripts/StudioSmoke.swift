import Foundation
import Combine
@main struct StudioSmoke {
    @MainActor static func main() throws {
        let suite = "PulseCanvas.StudioTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName:suite)!
        defer { defaults.removePersistentDomain(forName:suite) }
        let policyLibrary = ProjectMPresets(defaults: defaults)
        let policyStore = StudioStore(defaults: defaults, library: policyLibrary), policyRender = RenderState()
        let favorite = NativeEffects.activeIDs[0], ordinary = NativeEffects.activeIDs[1]
        policyRender.scene = favorite; policyStore.randomize(policyRender)
        let savedFavorite = policyStore.preset(policyRender)
        policyLibrary.toggleFavorite(favorite, appearance: savedFavorite)
        policyStore.randomize(policyRender) // Editing a look must not overwrite the favorite snapshot.
        policyStore.selectScene(ordinary, render: policyRender)
        let ordinaryFirst = policyStore.preset(policyRender)
        policyStore.selectScene(favorite, render: policyRender)
        precondition(policyStore.preset(policyRender) == savedFavorite)
        policyStore.selectScene(ordinary, render: policyRender)
        precondition(policyStore.preset(policyRender) != ordinaryFirst && policyStore.preset(policyRender).isValid)
        let stable = policyStore.preset(policyRender)
        policyStore.apply(to: policyRender); policyStore.save(policyRender)
        precondition(policyStore.preset(policyRender) == stable, "Playback/apply must not reroll the look")
        policyStore.reset(policyRender)
        precondition(policyStore.preset(policyRender) == VisualPreset.defaults(for: ordinary))
        policyLibrary.toggleFavorite(favorite)
        print("PASS selection policy: fresh non-favorites, full favorite snapshot restoration, edits preserve favorites, stable playback and explicit Reset")
        let render = RenderState(), store = StudioStore(defaults:defaults)
        for _ in 0..<50 {
            let unique = StudioTimeline.randomizedScenes(current: Array(repeating: 0, count: 80), favorites: [98,99], available: Array(0..<100))!
            precondition(unique.count == 80 && Set(unique).count == 80 && Set(unique).isSuperset(of: [98,99]))
            let full = StudioTimeline.randomizedScenes(current: Array(0..<20), favorites: [], available: Array(0..<20))!
            precondition(Set(full).count == 20 && zip(full, 0..<20).allSatisfy { $0 != $1 })
        }
        precondition(StudioTimeline.randomizedScenes(current: [0,1,2], favorites: [0], available: [0,1]) == nil)
        print("PASS unique Studio shuffle: no duplicate scenes, favorites included first, full-pool derangement and bounded pool exhaustion")
        render.playbackTime = 12.3; render.audioBands = Array(repeating: 0.25, count: 32); render.audioPulse = 0.7
        render.paused = true
        var selected = Set<Int>()
        let selectionEncoder = JSONEncoder(); selectionEncoder.outputFormatting = .sortedKeys
        let resetSuite = suite + ".Reset", resetDefaults = UserDefaults(suiteName: suite + ".Reset")!
        defer { resetDefaults.removePersistentDomain(forName: resetSuite) }
        let resetStore = StudioStore(defaults: resetDefaults), resetRender = RenderState()
        resetStore.isStudio = true
        resetStore.segments = [StudioSegment(start: 0, end: 8, scene: 18), StudioSegment(start: 8, end: 16, scene: 18)]
        let resetTimeline = try selectionEncoder.encode(resetStore.segments)
        resetRender.playbackTime = 5; resetRender.audioPulse = 0.7; resetRender.paused = false
        for scene in [10, 18, 19, 22, 31, RenderState.nativeSceneNames.count] {
            resetRender.scene = scene; resetStore.apply(to: resetRender)
            let expected = try selectionEncoder.encode(resetStore.preset(resetRender))
            let others = try selectionEncoder.encode(resetStore.presets.filter {$0.key != scene})
            resetStore.randomize(resetRender); resetRender.strobeEnabled = true
            resetStore.reset(resetRender)
            let actual = try selectionEncoder.encode(resetStore.preset(resetRender))
            let saved = try selectionEncoder.encode(StudioStore(defaults: resetDefaults).presets[scene])
            precondition(actual == expected && saved == expected, "Reset restores and persists this scene's normal defaults")
            let remaining = try selectionEncoder.encode(resetStore.presets.filter {$0.key != scene})
            precondition(remaining == others && resetRender.scene == scene && !resetRender.strobeEnabled)
            precondition(resetRender.playbackTime == 5 && resetRender.audioPulse == 0.7 && !resetRender.paused)
        }
        let afterResetTimeline = try selectionEncoder.encode(resetStore.segments)
        precondition(resetTimeline == afterResetTimeline)
        print("PASS Reset: native and ProjectM defaults restored and persisted; other styles, timeline and playback retained")
        let barsSuite = suite + ".Bars", barsDefaults = UserDefaults(suiteName: suite + ".Bars")!
        defer { barsDefaults.removePersistentDomain(forName: barsSuite) }
        let barsStore = StudioStore(defaults: barsDefaults), barsRender = RenderState()
        let grid = SongSegmentation(boundaries: Array(stride(from: 0.0, through: 48, by: 2)), bpm: 120)
        barsStore.isStudio = true; barsRender.scene = 22; barsRender.playbackTime = 9; barsRender.paused = true
        barsStore.makeTimeline(SongSegmentation(boundaries: [0,8,16,24,32,40,48], bpm: 120), render: barsRender)
        for i in barsStore.segments.indices { barsStore.segments[i].scene = 18 + i }
        barsRender.brightness = 1.27; barsRender.chaos = 0.31; barsStore.save(barsRender)
        let barsStyles = try selectionEncoder.encode(barsStore.presets)
        precondition(barsStore.setBars(1, at: 1, grid: grid, render: barsRender))
        precondition(barsStore.segments[0].end == 8 && barsStore.segments[1].start == 8 && barsStore.segments[1].end == 10)
        precondition(barsStore.setBars(2, at: 2, grid: grid, render: barsRender))
        precondition(Array(barsStore.segments.prefix(3)).map {[$0.start,$0.end]} == [[0,8],[8,10],[10,14]])
        precondition(Array(barsStore.segments.prefix(6)).map(\.scene) == [18,19,20,21,22,23])
        precondition(Array(barsStore.segments.prefix(3)).map {barsStore.barCount(for: $0)} == [4,1,2])
        precondition(barsStore.segments.last!.end == 48 && StudioTimeline.valid(barsStore.segments, sceneCount: RenderState.sceneNames.count))
        precondition(barsStore.barsPerSection == 4 && barsRender.playbackTime == 9 && barsRender.paused)
        let variableProject = CreatorProject(scene: barsRender.scene, appearance: barsStore.preset(barsRender), aspect: "16:9 · Wide", resolution: 1080, fps: 60, timeline: barsStore.segments, studioEnabled: true, visualPresets: barsStore.presets, barsPerSection: 4)
        let savedBars = try JSONDecoder().decode(CreatorProject.self, from: selectionEncoder.encode(variableProject))
        precondition(savedBars.timeline!.map(\.bars) == barsStore.segments.map(\.bars))
        let beforeBadBars = try selectionEncoder.encode(barsStore.segments)
        precondition(!barsStore.setBars(0, at: 1, grid: grid, render: barsRender) && !barsStore.setBars(3, at: -1, grid: grid, render: barsRender))
        precondition(!barsStore.setBars(3, grid: SongSegmentation(boundaries: [0,.nan,48], bpm:120), render: barsRender))
        let afterBadBars = try selectionEncoder.encode(barsStore.segments)
        precondition(beforeBadBars == afterBadBars)
        precondition(barsStore.setBars(3, grid: grid, render: barsRender))
        precondition(barsStore.barsPerSection == 3 && barsStore.segments.allSatisfy {$0.bars == 3})
        precondition(barsStore.segments.map(\.start) == [0,6,12,18,24,30,36,42] && barsStore.segments.last!.end == 48)
        // Following the new timing may save an untouched destination default, but existing settings cannot change.
        for (scene, preset) in try JSONDecoder().decode([Int:VisualPreset].self, from: barsStyles) {
            let actual = try selectionEncoder.encode(barsStore.presets[scene]), expected = try selectionEncoder.encode(preset)
            precondition(actual == expected)
        }
        let lengths = barsStore.segments.map(\.bars), timing = barsStore.segments.map {[$0.start,$0.end]}
        barsStore.randomizeTimeline(barsRender)
        precondition(barsStore.segments.map(\.bars) == lengths && barsStore.segments.map {[$0.start,$0.end]} == timing)
        precondition(barsStore.setBars(Int.max / 4, at: 0, grid: grid, render: barsRender) && barsStore.segments.count == 1 && barsStore.segments[0].end == 48)
        let legacySegment = try JSONDecoder().decode(StudioSegment.self, from: Data("{\"start\":0,\"end\":8,\"scene\":22}".utf8))
        precondition(legacySegment.bars == nil && barsStore.barCount(for: legacySegment) == 4)
        precondition(!StudioTimeline.valid([StudioSegment(start:0,end:8,scene:22,bars:0)], sceneCount:31))
        print("PASS Per-card bars: 4/1/2 sequence, beat-grid ripple, scene order, full-song tail fill/trim, apply-all, large lengths, randomization, settings, project round-trip and legacy compatibility")
        let randomBarsSuite = suite + ".RandomBars", randomBarsDefaults = UserDefaults(suiteName: randomBarsSuite)!
        defer { randomBarsDefaults.removePersistentDomain(forName: randomBarsSuite) }
        let randomBarsStore = StudioStore(defaults: randomBarsDefaults), randomBarsRender = RenderState()
        randomBarsStore.isStudio = true; randomBarsRender.scene = 18
        randomBarsRender.playbackTime = 9; randomBarsRender.paused = true
        randomBarsRender.chaos = 0.73; randomBarsRender.zoomSpeed = 2.1
        randomBarsStore.makeTimeline(SongSegmentation(boundaries: [0,8,16,24,32,40,48], bpm:120), render: randomBarsRender)
        for i in randomBarsStore.segments.indices { randomBarsStore.segments[i].scene = 18 + i }
        randomBarsStore.save(randomBarsRender)
        let randomBarsStyle = randomBarsStore.presets[18]!
        var lengthIndex = 0
        precondition(randomBarsStore.randomizeBars(grid: grid, render: randomBarsRender, chooseLength: {
            defer { lengthIndex += 1 }
            return [4,1,2][lengthIndex % 3]
        }))
        precondition(Array(randomBarsStore.segments.prefix(3)).map {[$0.start,$0.end]} == [[0,8],[8,10],[10,14]])
        precondition(Array(randomBarsStore.segments.prefix(6)).map(\.scene) == [18,19,20,21,22,23])
        precondition(randomBarsStore.segments.dropFirst(6).allSatisfy {$0.scene == 23}, "New tail cards repeat the last visualizer")
        precondition(randomBarsStore.segments.allSatisfy {grid.boundaries.contains($0.start) && grid.boundaries.contains($0.end)})
        precondition(randomBarsStore.segments.last!.end == 48 && randomBarsStore.segments.last!.bars == 4)
        precondition(StudioTimeline.valid(randomBarsStore.segments, sceneCount: RenderState.sceneNames.count))
        precondition(randomBarsStore.presets[18] == randomBarsStyle && randomBarsStore.barsPerSection == 4)
        precondition(randomBarsRender.playbackTime == 9 && randomBarsRender.paused && randomBarsStore.selectedSegment == 1)
        let randomBarsProject = CreatorProject(scene: randomBarsRender.scene, appearance: randomBarsStore.preset(randomBarsRender), aspect:"16:9 · Wide", resolution:1080, fps:60, timeline:randomBarsStore.segments, studioEnabled:true, visualPresets:randomBarsStore.presets, barsPerSection:4)
        let restoredRandomBars = try JSONDecoder().decode(CreatorProject.self, from: selectionEncoder.encode(randomBarsProject))
        let restoredRandomTiming = try selectionEncoder.encode(restoredRandomBars.timeline), savedRandomTiming = try selectionEncoder.encode(randomBarsStore.segments)
        precondition(restoredRandomTiming == savedRandomTiming)
        let invalidRandomBars = try selectionEncoder.encode(randomBarsStore.segments)
        var invalidIndex = 0
        precondition(!randomBarsStore.randomizeBars(grid: grid, render: randomBarsRender, chooseLength: {
            defer { invalidIndex += 1 }
            return invalidIndex == 0 ? 1 : 0
        }))
        precondition(!randomBarsStore.randomizeBars(grid: SongSegmentation(boundaries:[0,4,3,48], bpm:120), render: randomBarsRender))
        let afterInvalidRandomBars = try selectionEncoder.encode(randomBarsStore.segments)
        precondition(afterInvalidRandomBars == invalidRandomBars, "Invalid plans never partly replace the timeline")
        precondition(randomBarsStore.randomizeBars(grid:grid, render:randomBarsRender, chooseLength:{8}))
        precondition(randomBarsStore.segments.count == 3 && randomBarsStore.segments.map(\.scene) == [18,19,20], "Longer cards trim only the tail")
        let shortenedGrid = SongSegmentation(boundaries:[0,2,4,5], bpm:120)
        randomBarsStore.segments = [StudioSegment(start:0,end:5,scene:18,bars:3)]
        precondition(randomBarsStore.randomizeBars(grid:shortenedGrid, render:randomBarsRender, chooseLength:{8}))
        precondition(randomBarsStore.segments.count == 1 && randomBarsStore.segments[0].end == 5 && randomBarsStore.segments[0].bars == 8, "Partial final bars retain the requested count")
        randomBarsStore.makeTimeline(SongSegmentation(boundaries:[0,8,16,24,32,40,48], bpm:120), render:randomBarsRender)
        for _ in 0..<20 {
            precondition(randomBarsStore.randomizeBars(grid:grid, render:randomBarsRender))
            precondition(randomBarsStore.segments.allSatisfy {(1...8).contains($0.bars!)})
            precondition(randomBarsStore.segments.last!.end == 48 && StudioTimeline.valid(randomBarsStore.segments, sceneCount:RenderState.sceneNames.count))
        }
        let combinedTiming = randomBarsStore.segments.map {[$0.start,$0.end]}, combinedBars = randomBarsStore.segments.map(\.bars)
        let combinedScenes = randomBarsStore.segments.map(\.scene)
        randomBarsStore.randomizeTimeline(randomBarsRender)
        precondition(randomBarsStore.segments.map {[$0.start,$0.end]} == combinedTiming && randomBarsStore.segments.map(\.bars) == combinedBars)
        precondition(zip(combinedScenes, randomBarsStore.segments).allSatisfy {$0 != $1.scene})
        precondition(randomBarsRender.playbackTime == 9 && randomBarsRender.paused)
        print("PASS Timeline randomization: bars-only 4/1/2 beat-grid sequence, order, tail fill/trim, partial final bar, 1–8 range, invalid-plan atomicity, project round-trip and combined visualizers with settings/playhead retained")
        let performanceSuite = suite + ".BarsPerformance"
        let performanceDefaults = UserDefaults(suiteName: performanceSuite)!
        defer { performanceDefaults.removePersistentDomain(forName: performanceSuite) }
        let performanceStore = StudioStore(defaults: performanceDefaults), performanceRender = RenderState()
        performanceStore.applyCommonSettings(chaos: 0.5, zoomSpeed: nil, motionSpeed: nil, render: performanceRender)
        var styleUpdates = 0
        let styleObserver = performanceStore.$presets.dropFirst().sink { _ in styleUpdates += 1 }
        let storedStyles = performanceDefaults.data(forKey: "PulseCanvas.studio.v1")
        let longGrid = SongSegmentation(boundaries: (0...10_000).map {Double($0) * 2}, bpm: 120)
        performanceStore.segments = (0..<10_000).map {StudioSegment(start: Double($0) * 2, end: Double($0 + 1) * 2, scene: 10, bars: 1)}
        performanceStore.isStudio = true; performanceRender.playbackTime = 0
        let editStart = Date()
        for edit in 0..<100 {
            precondition(performanceStore.setBars(edit.isMultiple(of: 2) ? 2 : 1, at: 100, grid: longGrid, render: performanceRender))
        }
        let milliseconds = Date().timeIntervalSince(editStart) * 10
        precondition(styleUpdates == 0 && performanceDefaults.data(forKey: "PulseCanvas.studio.v1") == storedStyles,
                     "Timing-only edits cannot republish or rewrite the entire visual preset library")
        precondition(performanceStore.segments.last!.end == 20_000 && performanceStore.segments.count == 10_000)
        withExtendedLifetime(styleObserver) {}
        print("PASS Bars performance: 100 edits across 10,000 sections and \(performanceStore.presets.count) saved styles, no preset republishing or persistence, average \(String(format: "%.2f", milliseconds)) ms/edit")
        for _ in 0..<100 {
            let previous = render.scene
            store.save(render) // Include any unsaved active edits in the reference.
            let settingsBefore = try selectionEncoder.encode(store.presets)
            store.randomizeScene(render)
            precondition(render.scene != previous && RenderState.sceneNames.indices.contains(render.scene))
            let expected = RenderState(); expected.scene = render.scene; store.apply(to: expected)
            let actualStyle = try selectionEncoder.encode(store.preset(render)), expectedStyle = try selectionEncoder.encode(store.preset(expected))
            precondition(actualStyle == expectedStyle, "Random selection applies and stores the new appearance")
            let settingsAfter = try selectionEncoder.encode(store.presets)
            precondition(settingsAfter != settingsBefore && store.preset(render).isValid && !render.strobeEnabled, "New selection must produce a valid fresh look without enabling strobe")
            precondition(render.playbackTime == 12.3 && render.audioBands == Array(repeating: 0.25, count: 32) && render.audioPulse == 0.7 && render.paused)
            selected.insert(render.scene)
        }
        render.strobeEnabled = true; store.save(render)
        let beforeDice = try selectionEncoder.encode(store.preset(render)), diceScene = render.scene
        let otherStyles = store.presets.filter { $0.key != diceScene }
        store.randomize(render)
        precondition(render.scene == diceScene && render.strobeEnabled, "The dice button changes only the current visualizer, retaining its strobe toggle")
        let afterDice = try selectionEncoder.encode(store.preset(render))
        precondition(afterDice != beforeDice)
        let otherStylesAfter = try selectionEncoder.encode(store.presets.filter { $0.key != diceScene }), otherStylesBefore = try selectionEncoder.encode(otherStyles)
        precondition(otherStylesAfter == otherStylesBefore, "The dice button cannot change other visualizers")
        let clipDiceSuite = suite + ".clipDice", clipDiceDefaults = UserDefaults(suiteName: suite + ".clipDice")!
        defer { clipDiceDefaults.removePersistentDomain(forName: clipDiceSuite) }
        let clipDiceStore = StudioStore(defaults: clipDiceDefaults), clipDiceRender = RenderState()
        clipDiceStore.isStudio = true
        clipDiceStore.segments = [StudioSegment(start: 0, end: 8, scene: 22), StudioSegment(start: 8, end: 16, scene: 23), StudioSegment(start: 16, end: 24, scene: 23)]
        clipDiceRender.scene = 22; clipDiceRender.speed = 1.23; clipDiceRender.playbackTime = 12.3
        clipDiceRender.audioPCM = [0.1,0.2]; clipDiceRender.audioPulse = 0.7; clipDiceRender.paused = false
        clipDiceStore.save(clipDiceRender)
        var inactiveStyle = VisualPreset(); inactiveStyle.strobeEnabled = true; inactiveStyle.brightness = 1.3
        clipDiceStore.presets[23] = inactiveStyle
        let diceTimeline = try selectionEncoder.encode(clipDiceStore.segments)
        let activeBeforeClipDice = try selectionEncoder.encode(clipDiceStore.preset(clipDiceRender))
        let inactiveBeforeClipDice = try selectionEncoder.encode(inactiveStyle)
        clipDiceStore.randomizeVisuals(at: 1, render: clipDiceRender)
        let inactiveAfterClipDice = try selectionEncoder.encode(clipDiceStore.presets[23]!)
        let activeAfterClipDice = try selectionEncoder.encode(clipDiceStore.preset(clipDiceRender))
        precondition(inactiveAfterClipDice != inactiveBeforeClipDice && activeAfterClipDice == activeBeforeClipDice)
        precondition(clipDiceRender.scene == 22 && clipDiceStore.selectedSegment == 0 && clipDiceStore.presets[23]!.strobeEnabled)
        let diceSaved = try selectionEncoder.encode(StudioStore(defaults: clipDiceDefaults).presets[23]!)
        precondition(diceSaved == inactiveAfterClipDice, "Inactive clip dice persists the shared appearance")
        clipDiceStore.randomizeVisuals(at: 0, render: clipDiceRender)
        let activeAfterActiveDice = try selectionEncoder.encode(clipDiceStore.preset(clipDiceRender))
        precondition(activeAfterActiveDice != activeBeforeClipDice)
        let otherAfterActiveDice = try selectionEncoder.encode(clipDiceStore.presets[23]!)
        precondition(otherAfterActiveDice == inactiveAfterClipDice)
        precondition(clipDiceRender.playbackTime == 12.3 && clipDiceRender.audioPCM == [0.1,0.2] && clipDiceRender.audioPulse == 0.7 && !clipDiceRender.paused)
        let diceTimelineAfter = try selectionEncoder.encode(clipDiceStore.segments)
        precondition(diceTimeline == diceTimelineAfter, "Clip dice cannot change assignments or section boundaries")
        let dicePresetsBeforeInvalid = try selectionEncoder.encode(clipDiceStore.presets)
        clipDiceStore.randomizeVisuals(at: -1, render: clipDiceRender)
        clipDiceStore.randomizeVisuals(at: 3, render: clipDiceRender)
        let dicePresetsAfterInvalid = try selectionEncoder.encode(clipDiceStore.presets)
        precondition(dicePresetsBeforeInvalid == dicePresetsAfterInvalid)
        print("PASS Studio clip dice: active/inactive shared styles, persistence, explicit strobe choice, timeline assignments and playback retained")
        precondition(Set(RenderState.nativeSceneNames).count == RenderState.nativeSceneNames.count)
        precondition(!ProjectMPresets.shared.entries.isEmpty)
        precondition(Set(VisualPalette.allCases.map(\.title)).count == 5)
        store.isStudio = true
        store.segments = [StudioSegment(start: 0, end: 8, scene: 18), StudioSegment(start: 8, end: 16, scene: 17), StudioSegment(start: 16, end: 24, scene: 18)]
        let boundaries = store.segments.map { [$0.start, $0.end] }
        store.follow(time: 0, render: render)
        let revealAtStart = store.visualizerRevealRequest
        for tick in 0..<240 { store.follow(time: Double(tick) / 30, render: render) }
        precondition(store.visualizerRevealRequest == revealAtStart, "Playback ticks inside a section must not repeatedly scroll the preset row")
        render.zoom = 1.37; render.palette = 3; render.speed = 2.1; render.chaos = 0.83; render.liquidDetail = 0.91; render.zoomSpeed = 2.3; render.haloCount = 11
        store.follow(time: 8, render: render)
        precondition(store.visualizerRevealRequest == revealAtStart + 1, "Studio scene changes must reveal the selected preset")
        precondition(render.scene == 17 && store.selectedSegment == 1)
        store.follow(time: 16, render: render)
        precondition(store.visualizerRevealRequest == revealAtStart + 2, "Returning to an earlier scene must reveal it again")
        precondition(render.scene == 18 && render.zoom == 1.37 && render.palette == 3 && render.speed == 2.1 && render.chaos == 0.83 && render.liquidDetail == 0.91 && render.zoomSpeed == 2.3 && render.haloCount == 11, "Repeated visualizer must use shared settings")
        store.selectScene(20, render: render)
        store.follow(time: 17, render: render)
        precondition(store.visualizerRevealRequest == revealAtStart + 2, "Ordinary preset selection followed by playback must stay stationary")
        print("PASS Studio preset following: one reveal per visualizer change; returning scenes reveal again; playback ticks and manual preset selection do not scroll")
        precondition(store.segments[2].scene == 20 && store.segments[0].scene == 18)
        precondition(store.segments.map { [$0.start, $0.end] } == boundaries, "Changing visuals cannot move boundaries")
        precondition(StudioTimeline.index(at: 7.999, in: store.segments) == 0 && StudioTimeline.index(at: 8, in: store.segments) == 1 && StudioTimeline.index(at: 24, in: store.segments) == 2)
        precondition(!StudioTimeline.valid([StudioSegment(start: 0, end: 8, scene: 0), StudioSegment(start: 9, end: 16, scene: 1)], sceneCount: RenderState.sceneNames.count))
        store.isStudio = false
        render.scene = 22; render.chaos = 0.32; render.zoomSpeed = 0.77
        let beforeAssignment = store.segments.map(\.scene)
        precondition(store.assignAtPlayhead(9.5, render: render) == 1)
        precondition(store.segments[1].scene == 22 && store.segments[0].scene == beforeAssignment[0] && store.segments[2].scene == beforeAssignment[2])
        precondition(!store.isStudio && render.scene == 22 && render.chaos == 0.32 && render.zoomSpeed == 0.77 && render.playbackTime == 12.3)
        precondition(store.presets[22]?.chaos == 0.32 && store.segments.map { [$0.start, $0.end] } == boundaries)
        precondition(store.assignAtPlayhead(8, render: render) == 1 && store.assignAtPlayhead(24, render: render) == 2)
        precondition(store.assignAtPlayhead(.nan, render: render) == nil)
        let empty = StudioStore(defaults:defaults); empty.segments = []
        precondition(empty.assignAtPlayhead(0, render: render) == nil)
        store.isStudio = true
        print("PASS Use at playhead: containing section only, exact boundaries/end, shared settings, browsing and playback retained")
        let oldJSON = """
        {"version":1,"scene":0,"appearance":{"speed":1,"brightness":1,"particleSize":1,"palette":0,"fog":0.5,"rotation":0,"zoom":1,"motionBlur":0,"wireframe":true,"strobeEnabled":false,"strobeSensitivity":1,"strobeStrength":1},"aspect":"16:9 · Wide","resolution":1080,"fps":60,"clipStart":0,"clipEnd":30,"useEntireTrack":false}
        """
        let old = try JSONDecoder().decode(CreatorProject.self, from: Data(oldJSON.utf8))
        precondition(old.bundledSoundtrack == nil, "Existing projects retain external soundtrack references")
        precondition(old.timeline == nil && old.visualPresets == nil && old.studioEnabled == nil && old.appearance.chaos == 0.5 && old.appearance.liquidDetail == 0.6 && old.appearance.zoomSpeed == 1.5 && old.appearance.haloCount == 6 && old.barsPerSection == nil)
        let migratedJSON = String(data: try JSONEncoder().encode(old), encoding: .utf8)!
        precondition(!migratedJSON.contains("clipStart") && !migratedJSON.contains("clipEnd") && !migratedJSON.contains("useEntireTrack") && !migratedJSON.contains("wireframe"), "Legacy trim and overlay fields are ignored and no longer saved")
        var project = old; project.timeline = store.segments; project.studioEnabled = true; project.visualPresets = store.presets; project.barsPerSection = 7; project.resolution = 2160
        let restored = try JSONDecoder().decode(CreatorProject.self, from: JSONEncoder().encode(project))
        var bundledProject = project
        bundledProject.soundtrack = nil; bundledProject.bundledSoundtrack = "pulsecanvas"
        let restoredBundled = try JSONDecoder().decode(CreatorProject.self, from: JSONEncoder().encode(bundledProject))
        precondition(restoredBundled.bundledSoundtrack == "pulsecanvas" && restoredBundled.soundtrack == nil,
                     "Bundled soundtrack projects must not depend on an app installation path")
        precondition(restored.timeline?.map { [$0.start, $0.end] } == boundaries && restored.visualPresets?[18]?.zoom == 1.37 && restored.studioEnabled == true && restored.visualPresets?[18]?.chaos == 0.83 && restored.visualPresets?[18]?.liquidDetail == 0.91 && restored.visualPresets?[18]?.zoomSpeed == 2.3 && restored.visualPresets?[18]?.haloCount == 11 && restored.barsPerSection == 7 && restored.resolution == 2160)
        store.save(render)
        let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
        let styles = try encoder.encode(store.presets)
        let oldScenes = store.segments.map(\.scene)
        store.randomizeTimeline(render)
        precondition(Set(store.segments.map(\.scene)).count == store.segments.count)
        precondition(zip(oldScenes, store.segments.map(\.scene)).allSatisfy { $0 != $1 })
        precondition(zip(store.segments,store.segments.dropFirst()).allSatisfy { $0.scene != $1.scene })
        precondition(store.segments.map { [$0.start, $0.end] } == boundaries)
        let randomizedStyles = try encoder.encode(store.presets)
        precondition(randomizedStyles != styles, "Timeline randomization creates fresh shared looks")
        let beforeSection = store.segments.map(\.scene)
        store.randomizeSegment(at: 1, render: render)
        precondition(Set(store.segments.map(\.scene)).count == store.segments.count)
        precondition(store.segments[1].scene != beforeSection[1] && store.segments[0].scene == beforeSection[0] && store.segments[2].scene == beforeSection[2])
        precondition(store.segments.map { [$0.start, $0.end] } == boundaries && store.preset(render).chaos == store.presets[render.scene]?.chaos)
        store.save(render)
        let settingsBeforeStudioShuffle = try selectionEncoder.encode(store.presets)
        let beforeStudioShuffle = store.segments.map(\.scene)
        store.randomizeScene(render)
        precondition(Set(store.segments.map(\.scene)).count == store.segments.count)
        precondition(store.segments[store.selectedSegment].scene == render.scene && render.scene != beforeStudioShuffle[store.selectedSegment])
        precondition(store.segments.enumerated().allSatisfy { $0.offset == store.selectedSegment || $0.element.scene == beforeStudioShuffle[$0.offset] })
        precondition(store.segments.map { [$0.start, $0.end] } == boundaries)
        let settingsAfterStudioShuffle = try selectionEncoder.encode(store.presets)
        precondition(settingsAfterStudioShuffle != settingsBeforeStudioShuffle, "Studio random selection creates a fresh look")
        render.motionBlur = 0
        store.randomize(render)
        precondition((0...0.45).contains(render.motionBlur))
        // Include untouched visualizers and unsaved edits in the active scene.
        store.presets.removeValue(forKey: 18); store.presets.removeValue(forKey: 19)
        render.scene = 22; store.apply(to: render)
        render.brightness = 1.234; render.zoomSpeed = 0.72; render.strobeEnabled = false
        var expected = store.presets
        expected[render.scene] = store.preset(render)
        let reference = RenderState()
        for scene in ProjectMPresets.shared.availableScenes where expected[scene] == nil {
            reference.scene = scene; store.apply(to: reference); expected[scene] = store.preset(reference)
        }
        func withoutCommonSettings(_ preset: VisualPreset) throws -> Data {
            var copy = preset
            copy.chaos = 0.5; copy.zoomSpeed = 1.5; copy.speed = 1
            return try encoder.encode(copy)
        }
        let timelineBeforeCommon = try encoder.encode(store.segments)
        let selectedBeforeCommon = store.selectedSegment, activeScene = render.scene
        store.applyCommonSettings(chaos: 0.42, zoomSpeed: nil, motionSpeed: nil, render: render)
        precondition(store.presets.count == ProjectMPresets.shared.availableScenes.count)
        for scene in ProjectMPresets.shared.availableScenes {
            var original = expected[scene]!; original.chaos = 0.42
            let actual = try encoder.encode(store.presets[scene]!), wanted = try encoder.encode(original)
            precondition(actual == wanted, "Only the chosen common control may change")
        }
        store.applyCommonSettings(chaos: nil, zoomSpeed: 0, motionSpeed: 1.8, render: render)
        for scene in ProjectMPresets.shared.availableScenes {
            let preset = store.presets[scene]!
            precondition(preset.chaos == 0.42 && preset.zoomSpeed == 0 && preset.speed == 1.8)
            let actual = try withoutCommonSettings(preset), wanted = try withoutCommonSettings(expected[scene]!)
            precondition(actual == wanted, "Bulk settings cannot change palette, camera, strobe or other appearance")
        }
        precondition(render.scene == activeScene && render.chaos == 0.42 && render.zoomSpeed == 0 && render.speed == 1.8 && render.brightness == 1.234)
        let savedCommon = try encoder.encode(store.presets), persistedCommon = try encoder.encode(StudioStore(defaults:defaults).presets)
        precondition(savedCommon == persistedCommon, "Bulk controls persist for the next session")
        project.appearance = store.preset(render); project.visualPresets = store.presets
        let commonProject = try JSONDecoder().decode(CreatorProject.self, from: encoder.encode(project))
        precondition(commonProject.visualPresets!.values.allSatisfy { $0.chaos == 0.42 && $0.zoomSpeed == 0 && $0.speed == 1.8 })
        let timelineAfterCommon = try encoder.encode(store.segments)
        precondition(timelineAfterCommon == timelineBeforeCommon && selectedBeforeCommon == store.selectedSegment)
        precondition(render.playbackTime == 12.3 && render.audioBands == Array(repeating: 0.25, count: 32) && render.audioPulse == 0.7 && render.paused)
        store.follow(time: 0, render: render)
        precondition(render.chaos == 0.42 && render.zoomSpeed == 0 && render.speed == 1.8, "Studio uses shared bulk settings")
        let beforeInvalid = try encoder.encode(store.presets)
        store.applyCommonSettings(chaos: nil, zoomSpeed: nil, motionSpeed: nil, render: render)
        store.applyCommonSettings(chaos: .nan, zoomSpeed: 1, motionSpeed: 1, render: render)
        let afterInvalid = try encoder.encode(store.presets)
        precondition(beforeInvalid == afterInvalid, "No selected settings or invalid values cannot mutate presets")
        let beforeStrobe = store.presets
        let strobeScene = render.scene, strobeSection = store.selectedSegment
        store.applyCommonSettings(chaos: nil, zoomSpeed: nil, motionSpeed: nil,
                                  strobeEnabled: true, strobeSensitivity: 1.7, strobeStrength: 0.62, render: render)
        func withoutStrobe(_ preset: VisualPreset) throws -> Data {
            var copy = preset
            copy.strobeEnabled = false; copy.strobeSensitivity = 1; copy.strobeStrength = 1
            return try encoder.encode(copy)
        }
        for scene in ProjectMPresets.shared.availableScenes {
            let appearance = store.presets[scene]!
            precondition(appearance.strobeEnabled && appearance.strobeSensitivity == 1.7 && appearance.strobeStrength == 0.62)
            let original = try withoutStrobe(beforeStrobe[scene]!), updated = try withoutStrobe(appearance)
            precondition(original == updated, "Strobe-only application preserves every other visual setting")
        }
        precondition(render.strobeEnabled && render.strobeSensitivity == 1.7 && render.strobeStrength == 0.62 && render.scene == strobeScene && store.selectedSegment == strobeSection)
        project.appearance = store.preset(render); project.visualPresets = store.presets
        let strobeProject = try JSONDecoder().decode(CreatorProject.self, from: encoder.encode(project))
        precondition(strobeProject.visualPresets!.values.allSatisfy { $0.strobeEnabled && $0.strobeSensitivity == 1.7 && $0.strobeStrength == 0.62 })
        let strobeSaved = try encoder.encode(store.presets), strobePersisted = try encoder.encode(StudioStore(defaults:defaults).presets)
        precondition(strobeSaved == strobePersisted)
        store.follow(time: 8, render: render)
        precondition(render.strobeEnabled && render.strobeSensitivity == 1.7 && render.strobeStrength == 0.62, "Every Studio section follows its shared strobe controls")
        store.applyCommonSettings(chaos: nil, zoomSpeed: nil, motionSpeed: nil, strobeEnabled: false, render: render)
        precondition(!render.strobeEnabled && store.presets.values.allSatisfy { !$0.strobeEnabled && $0.strobeSensitivity == 1.7 && $0.strobeStrength == 0.62 })
        for scene in ProjectMPresets.shared.availableScenes {
            let original = try withoutStrobe(beforeStrobe[scene]!), updated = try withoutStrobe(store.presets[scene]!)
            precondition(original == updated)
        }
        let strobeTimeline = try encoder.encode(store.segments)
        precondition(strobeTimeline == timelineBeforeCommon && render.playbackTime == 12.3 && render.paused)
        print("PASS: strobe Apply all enables all \(ProjectMPresets.shared.availableScenes.count) shared presets with chosen sensitivity/strength; Remove all disables flashes and retains those values; other controls, timeline/audio, persistence and project round-trip retained")
        print("PASS: selective common Chaos/zoom/motion applies to all \(ProjectMPresets.shared.availableScenes.count) styles and untouched defaults, retains unsaved edits and unselected settings including strobe; preserves timeline/audio; persists and round-trips shared Studio presets")
        print("PASS: Visual randomization includes whole-image softness")
        print("PASS: whole-timeline and individual-section randomization change designs, retain fixed boundaries with fresh settings")
        print("PASS: fixed section boundaries, exact switches, shared appearance across repeated sections, project round-trip, old project compatibility")
        print("PASS: 100 random visualizer selections, \(selected.count) designs selected, fresh settings and soundtrack state retained; dice randomizes only the current visualizer")
    }
}
