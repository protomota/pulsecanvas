import SwiftUI
import Combine

@MainActor
struct StudioTimelineView: View {
    @ObservedObject private var library = ProjectMPresets.shared
    @ObservedObject var studio: StudioStore
    @ObservedObject var render: RenderState
    @ObservedObject var audio: AudioController
    let exporting: Bool
    let present: () -> Void
    var compactness: CGFloat = 0
    @State private var choosingSegment: Int?
    @State private var favoritesSegment: Int?
    @State private var confirmRandomizeTimeline = false
    @State private var randomizeCapacityError = false
    @State private var randomizeVisualizers = true
    @State private var randomizeBarLengths = false
    @State private var showCommonSettings = false
    @State private var includeBars = false
    @State private var commonBars = 4
    @State private var includeChaos = true
    @State private var includeZoomSpeed = true
    @State private var includeMotionSpeed = true
    @State private var commonChaos: Float = 0.5
    @State private var commonZoomSpeed: Float = 1.5
    @State private var commonMotionSpeed: Float = 1
    @State private var strobeAction: StrobeAction = .keep
    @State private var commonStrobeSensitivity: Float = 1
    @State private var commonStrobeStrength: Float = 1
    private enum StrobeAction: String, CaseIterable {
        case keep = "Keep individual", add = "Apply all", remove = "Remove all"
    }
    private let accent = Color(red: 0.95, green: 0.68, blue: 0.55)

    var body: some View {
        VStack(alignment: .leading, spacing: 10 - 4 * compactness) {
            HStack(spacing: 8) {
                Label("Studio", systemImage: "rectangle.split.3x1").font(.system(size: 14, weight: .semibold))
                if !studio.segments.isEmpty {
                    Text("\(studio.segments.count) sections").font(.system(size: 11)).foregroundStyle(.secondary).layoutPriority(-1)
                    if let bpm = studio.detectedBPM { Text("\(Int(bpm.rounded())) BPM").font(.system(size: 11)).foregroundStyle(.secondary).layoutPriority(-1) }
                }
                Spacer()
                Button {
                    confirmRandomizeTimeline = true
                } label: { Label("Randomize timeline", systemImage: "shuffle") }
                    .buttonStyle(StudioButtonStyle(treatment: .accent, compact: true)).disabled(studio.segments.isEmpty || exporting)
                    .help("Choose whether to randomize visualizers, bar lengths, or both")
                Button {
                    showCommonSettings = true
                } label: { Label("Apply to all", systemImage: "slider.horizontal.3") }
                    .buttonStyle(StudioButtonStyle(treatment: .accent, compact: true))
                    .help("Choose common settings for every visualizer and Studio section")
                Button(action: present) { Label("Present", systemImage: "play.rectangle.fill") }
                    .buttonStyle(StudioButtonStyle(treatment: .primary, compact: true))
                    .disabled(audio.selectedURL == nil || studio.segments.isEmpty || exporting)
                    .help("Play the Studio timeline full screen from the current position. Escape returns to the editor.")
                    .accessibilityLabel("Present Studio full screen")
            }.lineLimit(1)
            if studio.segments.isEmpty {
                Text("Add a soundtrack to create a sequence of visualizers.").font(.system(size: 12)).foregroundStyle(.secondary)
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 8) {
                            // Timing changes move boundaries, not card identities.
                            ForEach(studio.segments.indices, id: \.self) { index in
                                segmentCard(studio.segments[index], index: index).id(index)
                            }
                        }
                        // Keep card borders clear of the scroll view's clipping bounds,
                        // including space reserved by macOS for a horizontal scroller.
                        .padding(.vertical, 6)
                    }.frame(height: 140).scrollIndicators(.hidden)
                        .onAppear { proxy.scrollTo(studio.selectedSegment, anchor: .center) }
                        .onChange(of: studio.selectedSegment) { _, index in proxy.scrollTo(index, anchor: .center) }
                }
            }
        }.padding(.horizontal, 20).padding(.vertical, 12 - 4 * compactness)
            .background(Color.black.opacity(0.12)).disabled(exporting)
            .sheet(isPresented: $confirmRandomizeTimeline) { timelineRandomizationConfirmation.dismissOnOutsideClick { confirmRandomizeTimeline = false } }
            .sheet(isPresented: $showCommonSettings) { commonSettings.dismissOnOutsideClick { showCommonSettings = false } }
            .alert("Not enough unique visualizers", isPresented: $randomizeCapacityError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This timeline has \(studio.segments.count) sections and \(ProjectMPresets.shared.eligibleScenes.count) available visualizers. Use longer sections or add visualizers to randomize without repeats.")
            }
            .sheet(isPresented: Binding(get: {choosingSegment != nil}, set: {if !$0 {choosingSegment = nil}})) {
                if let index = choosingSegment, studio.segments.indices.contains(index) {
                    VStack(spacing:0) {
                        scenePicker(studio.segments[index], index:index)
                        HStack {
                            Spacer()
                            Button("Cancel") {choosingSegment = nil}
                                .buttonStyle(StudioButtonStyle(compact:true)).keyboardShortcut(.cancelAction)
                        }.padding(18)
                    }.dismissOnOutsideClick { choosingSegment = nil }
                }
            }
            .onChange(of: studio.selectedSegment) { _, index in
                if choosingSegment != index { choosingSegment = nil }
                favoritesSegment = nil
            }
    }

    private var timelineRandomizationConfirmation: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "shuffle").font(.system(size: 24, weight: .medium))
                    .foregroundStyle(accent).frame(width: 56, height: 56)
                    .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text("A fresh take on your Studio").font(.system(size: 21, weight: .semibold))
                    Text("Choose what to randomize across your Studio.")
                        .font(.system(size: 13)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Entire timeline", systemImage: "rectangle.split.3x1")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Text("\(studio.segments.count) sections").font(.system(size: 12, weight: .medium)).monospacedDigit()
                        .foregroundStyle(accent).padding(.horizontal, 10).padding(.vertical, 5)
                        .background(accent.opacity(0.1), in: Capsule())
                }
                Divider().overlay(.white.opacity(0.05))
                VStack(alignment: .leading, spacing: 6) {
                    Toggle("Visualizers", isOn: $randomizeVisualizers).toggleStyle(StudioSwitchStyle())
                        .accessibilityLabel("Randomize timeline visualizers")
                    Text(library.pool.enabled ? "Use only your visualizer pool. Small pools repeat to fill the timeline." : "Use favorites first, then unused library visuals. Each visualizer appears once.")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Toggle("Bar lengths", isOn: $randomizeBarLengths).toggleStyle(StudioSwitchStyle())
                        .accessibilityLabel("Randomize timeline bars")
                        .disabled(audio.selectedURL == nil)
                    Text("Choose lengths from 1–8 bars on the song’s beat grid.")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Divider().overlay(.white.opacity(0.05))
                Label(randomizeBarLengths ? "Tail sections may be trimmed or repeated to fit the song." : (randomizeVisualizers ? "Your current visualizer choices will be replaced." : "Select at least one option to continue."), systemImage: "arrow.triangle.2.circlepath")
                    .font(.system(size: 12)).foregroundStyle(.white.opacity(0.85))
                Label(randomizeBarLengths ? (randomizeVisualizers ? "Fresh looks replace visual settings. Your soundtrack stays." : "Visualizer order, soundtrack, and saved settings stay.") : "Fresh looks replace visual settings. Timing and soundtrack stay.", systemImage: "checkmark.circle")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.08)))
            HStack(spacing: 10) {
                Button("Cancel") { confirmRandomizeTimeline = false }
                    .buttonStyle(StudioButtonStyle()).keyboardShortcut(.cancelAction)
                Spacer()
                Button {
                    guard !exporting, !studio.segments.isEmpty else { return }
                    confirmRandomizeTimeline = false
                    audio.pause()
                    if randomizeBarLengths {
                        guard let grid = audio.segmentPlan(beatsPerSection: 4) else { return }
                        if audio.previewSectionStart != nil { audio.seek(fraction: audio.progress) }
                        choosingSegment = nil; favoritesSegment = nil
                        guard studio.randomizeBars(grid: grid, render: render) else { return }
                    }
                    if randomizeVisualizers, !studio.randomizeTimeline(render) { randomizeCapacityError = true }
                } label: { Label("Randomize timeline", systemImage: "shuffle") }
                    .buttonStyle(StudioButtonStyle(treatment: .primary))
                    .disabled(exporting || studio.segments.isEmpty || (!randomizeVisualizers && !randomizeBarLengths))
            }
        }.padding(28).frame(width: 490)
            .background(Color(red: 0.115, green: 0.095, blue: 0.14))
            .tint(accent)
            .onAppear { randomizeVisualizers = true; randomizeBarLengths = false }
    }

    private var commonSettings: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Apply settings to all", systemImage: "slider.horizontal.3").font(.title2)
            Text("Choose what to share across all \(ProjectMPresets.shared.availableScenes.count) visualizers and every Studio section. Unselected settings keep their individual values.")
                .font(.system(size: 13)).foregroundStyle(.secondary)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Toggle("Bars per section", isOn: $includeBars).toggleStyle(StudioSwitchStyle())
                                .accessibilityLabel("Apply bars to all Studio sections")
                            Spacer()
                            barStepper(value: $commonBars, label: "Bars for all Studio sections")
                                .disabled(!includeBars)
                        }
                        Text("Set every card to this length. Later cards shift to the beat grid; the last ends with the soundtrack.")
                            .font(.system(size: 11)).foregroundStyle(.secondary)
                    }.disabled(studio.segments.isEmpty || audio.selectedURL == nil)
                    Divider()
                    commonControl("Chaos", included: $includeChaos, value: $commonChaos, range: 0...1,
                                  help: "How strongly shapes react to music. Zero keeps procedural motion.")
                    commonControl("Zoom speed", included: $includeZoomSpeed, value: $commonZoomSpeed, range: 0...3,
                                  help: "Forward travel speed. Zero keeps the framing flat.")
                    commonControl("Motion speed", included: $includeMotionSpeed, value: $commonMotionSpeed, range: 0.05...3,
                                  help: "Base animation speed before the music response.")
                    Divider()
                    strobeSettings
                }.padding(.trailing, 12)
            }.frame(height: 470)
            HStack {
                Button("Cancel") { showCommonSettings = false }.buttonStyle(StudioButtonStyle())
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Apply selected settings") {
                    if includeBars { changeBars(commonBars) }
                    studio.applyCommonSettings(chaos: includeChaos ? commonChaos : nil,
                        zoomSpeed: includeZoomSpeed ? commonZoomSpeed : nil,
                        motionSpeed: includeMotionSpeed ? commonMotionSpeed : nil,
                        strobeEnabled: strobeAction == .keep ? nil : strobeAction == .add,
                        strobeSensitivity: strobeAction == .add ? commonStrobeSensitivity : nil,
                        strobeStrength: strobeAction == .add ? commonStrobeStrength : nil, render: render)
                    showCommonSettings = false
                }.buttonStyle(StudioButtonStyle(treatment: .primary)).keyboardShortcut(.defaultAction)
                    .disabled(!includeBars && !includeChaos && !includeZoomSpeed && !includeMotionSpeed && strobeAction == .keep)
            }
        }.padding(28).frame(width: 500).tint(accent).disabled(exporting)
            .onAppear {
                includeBars = false
                commonBars = studio.barsPerSection
                commonChaos = render.chaos
                commonZoomSpeed = render.zoomSpeed
                commonMotionSpeed = render.speed
                strobeAction = .keep
                commonStrobeSensitivity = render.strobeSensitivity
                commonStrobeStrength = render.strobeStrength
            }
    }

    private var strobeSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Hi-hat strobe", systemImage: "bolt.fill").font(.headline)
            HStack(spacing: 6) {
                ForEach(StrobeAction.allCases, id: \.self) { action in
                    Button { strobeAction = action } label: {
                        HStack(spacing: 4) {
                            if strobeAction == action { Image(systemName: "checkmark") }
                            Text(action.rawValue)
                        }.frame(maxWidth: .infinity)
                    }.buttonStyle(StudioButtonStyle(treatment: strobeAction == action ? .accent : .secondary, compact: true))
                        .accessibilityLabel("\(action.rawValue) hi-hat strobe")
                        .accessibilityAddTraits(strobeAction == action ? .isSelected : [])
                }
            }
            Text(strobeAction == .remove ? "Turn strobe off everywhere and retain individual flash settings." : "Apply all enables strobe everywhere with the settings below.")
                .font(.system(size: 11)).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 8) {
                HStack { Text("Strobe sensitivity"); Spacer(); Text(commonStrobeSensitivity, format: .number.precision(.fractionLength(2))).monospacedDigit() }
                Slider(value: $commonStrobeSensitivity, in: 0.25...4).accessibilityLabel("Strobe sensitivity for all visualizers")
                Text("Higher sensitivity includes softer hi-hat hits.").font(.system(size: 11)).foregroundStyle(.secondary)
            }.disabled(strobeAction != .add).opacity(strobeAction == .add ? 1 : 0.5)
            VStack(alignment: .leading, spacing: 8) {
                HStack { Text("Flash strength"); Spacer(); Text(commonStrobeStrength, format: .percent.precision(.fractionLength(0))).monospacedDigit() }
                Slider(value: $commonStrobeStrength, in: 0.1...1).accessibilityLabel("Flash strength for all visualizers")
            }.disabled(strobeAction != .add).opacity(strobeAction == .add ? 1 : 0.5)
            Text("Flashes follow hi-hat attacks. Zero Chaos keeps flashes off.").font(.system(size: 11)).foregroundStyle(.secondary)
        }
    }

    private func commonControl(_ title: String, included: Binding<Bool>, value: Binding<Float>, range: ClosedRange<Float>, help: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Toggle(title, isOn: included).toggleStyle(StudioSwitchStyle())
                    .accessibilityLabel("Apply \(title) to all visualizers")
                Spacer()
                Text(value.wrappedValue, format: .number.precision(.fractionLength(2))).monospacedDigit()
                    .foregroundStyle(included.wrappedValue ? .primary : .secondary)
            }
            Slider(value: value, in: range).disabled(!included.wrappedValue)
                .accessibilityLabel("\(title) for all visualizers")
            Text(help).font(.system(size: 11)).foregroundStyle(.secondary)
        }
    }

    private func segmentCard(_ segment: StudioSegment, index: Int) -> some View {
        let selected = studio.selectedSegment == index
        let palette = VisualPalette(rawValue: studio.presets[segment.scene]?.palette ?? 0) ?? .ultraviolet
        return ZStack(alignment: .topTrailing) {
            Button {
                choosingSegment = nil
                preview(segment)
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("\(time(segment.start)) – \(time(segment.end))").monospacedDigit()
                        Spacer()
                    }.font(.system(size: 11)).foregroundStyle(selected ? accent : .white.opacity(0.7)).frame(height: 36).padding(.trailing, 174)
                    HStack(spacing: 6) {
                        Image(systemName:ProjectMPresets.shared.icon(for:segment.scene)).font(.system(size:14, weight:.light)).foregroundStyle(accent)
                        Text(RenderState.sceneNames[segment.scene]).font(.system(size: 12, weight: .semibold)).lineLimit(1)
                        Spacer(minLength: 0)
                    }.foregroundStyle(.white.opacity(0.92)).frame(minHeight: 28).padding(.trailing, 152)
                    StudioSectionProgress(audio: audio, segment: segment, selected: selected, palette: palette)
                }.padding(12).frame(width: 364)
                    .background(selected ? accent.opacity(0.08) : Color.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(selected ? accent.opacity(0.6) : .white.opacity(0.09)))
                    .contentShape(RoundedRectangle(cornerRadius: 10))
            }.buttonStyle(.plain)
                .accessibilityLabel("Section \(index + 1) visualizer, \(RenderState.sceneNames[segment.scene]), \(time(segment.start)) to \(time(segment.end))")
                .help("Select this section; keep playing if playback is running, or preview while paused")
            HStack(spacing: 6) {
                barStepper(value: Binding(get: {studio.barCount(for: segment)}, set: {changeBars($0, at: index)}),
                           label: "Bars for section \(index + 1)")
                    .help("Set this card’s length in bars. Later cards shift; the last ends with the soundtrack.")
                Button {
                    choosingSegment = nil
                    audio.playSection(start: segment.start, end: segment.end)
                    studio.follow(time: audio.playbackSeconds, render: render)
                } label: {
                    Image(systemName: audio.isPlaying && audio.previewSectionStart == segment.start ? "pause.fill" : "play.fill")
                        .font(.system(size: 13, weight: .semibold)).frame(width: 44, height: 44)
                        .background(accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 9))
                        .contentShape(Rectangle())
                }.buttonStyle(.plain)
                    .accessibilityLabel("\(audio.isPlaying && audio.previewSectionStart == segment.start ? "Pause" : "Play") section \(index + 1)")
                    .help("Loop this section of the soundtrack and visualizer; click again to pause")
            }.padding(6)
        }.overlay(alignment: .bottomTrailing) {
            HStack(spacing: 0) {
                Button {
                    favoritesSegment = nil
                    preview(segment)
                    choosingSegment = choosingSegment == index ? nil : index
                } label: {
                    Image(systemName: "chevron.down").font(.system(size: 11, weight: .semibold))
                        .frame(width: 32, height: 44).contentShape(Rectangle())
                }.buttonStyle(.plain)
                    .accessibilityLabel("Choose visualizer for section \(index + 1)")
                    .help("Change this section’s visualizer")
                Button {
                    choosingSegment = nil
                    studio.randomizeSegment(at: index, render: render)
                    replay(segment)
                    studio.requestVisualizerReveal()
                } label: {
                    Image(systemName: "shuffle").font(.system(size: 13, weight: .medium))
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }.buttonStyle(.plain)
                    .accessibilityLabel("Random visualizer for section \(index + 1)")
                    .help("Choose a different visualizer and replay this section")
                Button {
                    choosingSegment = nil
                    studio.randomizeVisuals(at: index, render: render)
                    replay(segment)
                    studio.requestVisualizerReveal()
                } label: {
                    Image(systemName: "dice.fill").font(.system(size: 16, weight: .medium))
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }.buttonStyle(.plain)
                    .accessibilityLabel("Randomize visual style for section \(index + 1)")
                    .help("Roll shared style settings and replay this section; all sections using this visualizer update")
                Button {
                    choosingSegment = nil
                    favoritesSegment = favoritesSegment == index ? nil : index
                } label: {
                    Image(systemName: "heart").font(.system(size: 15, weight: .medium))
                        .foregroundStyle(favoritesSegment == index ? accent : .white.opacity(0.85))
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }.buttonStyle(.plain)
                    .accessibilityLabel("Choose favorite visualizer for section \(index + 1)")
                    .help("Choose one of your favorites for this section")
                    .popover(isPresented: Binding(get: {favoritesSegment == index}, set: {if !$0 && favoritesSegment == index {favoritesSegment = nil}}), arrowEdge: .top) {
                        StudioFavoritesPicker(selected: segment.scene) { scene in
                            guard studio.segments.indices.contains(index) else {favoritesSegment = nil; return}
                            studio.assignScene(scene, at: index, render: render)
                            favoritesSegment = nil
                            preview(studio.segments[index])
                        }
                    }
            }.padding(.trailing, 6).padding(.bottom, 11)
        }
    }
    private func scenePicker(_ segment: StudioSegment, index: Int) -> some View {
        VisualizerBrowser(selected: segment.scene, heading:"Choose visualizer · Section \(index + 1)", appearance: { studio.presets[$0] ?? VisualPreset.defaults(for: $0) }) { scene in
            guard studio.segments.indices.contains(index) else {choosingSegment = nil; return}
            studio.assignScene(scene, at: index, render: render)
            preview(studio.segments[index])
            choosingSegment = nil
        }
    }

    private func barStepper(value: Binding<Int>, label: String) -> some View {
        HStack(spacing: 0) {
            Button { value.wrappedValue -= 1 } label: {
                Image(systemName: "minus").font(.system(size: 10, weight: .semibold))
                    .frame(width: 44, height: 44).contentShape(Rectangle())
            }.buttonStyle(.plain).disabled(value.wrappedValue <= 1)
                .accessibilityLabel("Fewer \(label.lowercased())")
            VStack(spacing: 1) {
                TextField("Bars", value: value, format: .number.grouping(.never))
                    .textFieldStyle(.plain).font(.system(size: 12, weight: .semibold)).multilineTextAlignment(.center)
                    .accessibilityLabel(label)
                Text("bars").font(.system(size: 9)).foregroundStyle(.secondary).accessibilityHidden(true)
            }.frame(width: 34)
            Button { value.wrappedValue += 1 } label: {
                Image(systemName: "plus").font(.system(size: 10, weight: .semibold))
                    .frame(width: 44, height: 44).contentShape(Rectangle())
            }.buttonStyle(.plain).disabled(value.wrappedValue >= Int.max / 4)
                .accessibilityLabel("More \(label.lowercased())")
        }.background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 9))
    }

    private func changeBars(_ value: Int, at index: Int? = nil) {
        let bars = max(1, min(Int.max / 4, value))
        if let index, studio.segments.indices.contains(index), studio.barCount(for: studio.segments[index]) == bars { return }
        guard let grid = audio.segmentPlan(beatsPerSection: 4) else { return }
        audio.pause()
        if audio.previewSectionStart != nil { audio.seek(fraction: audio.progress) }
        choosingSegment = nil; favoritesSegment = nil
        studio.setBars(bars, at: index, grid: grid, render: render)
        studio.follow(time: audio.playbackSeconds, render: render)
    }
    private func replay(_ segment: StudioSegment) {
        audio.playSection(start: segment.start, end: segment.end, restart: true)
        studio.follow(time: audio.playbackSeconds, render: render)
    }
    private func preview(_ segment: StudioSegment) {
        audio.selectSection(start: segment.start, end: segment.end)
        studio.follow(time: segment.start, render: render)
    }
    private func time(_ seconds: Double) -> String { String(format: "%d:%02d", Int(seconds) / 60, Int(seconds) % 60) }
}

@MainActor
private struct StudioFavoritesPicker: View {
    @ObservedObject private var library = ProjectMPresets.shared
    let selected: Int
    let choose: (Int) -> Void
    private var favorites: [Int] {
        library.eligibleScenes.filter {library.isFavorite($0)}
    }

    var body: some View {
        let scenes = favorites
        VStack(alignment: .leading, spacing: 8) {
            Label("Favorites", systemImage: "heart.fill").font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(red: 0.95, green: 0.68, blue: 0.55)).padding(.horizontal, 8)
            if scenes.isEmpty {
                Text("Tap a visualizer’s heart in the Library to add it here.")
                    .font(.system(size: 12)).foregroundStyle(.secondary).padding(8)
            } else {
                ScrollView {
                    LazyVStack(spacing: 3) {
                        ForEach(scenes, id: \.self) { scene in
                            Button {choose(scene)} label: {
                                HStack(spacing: 10) {
                                    Image(systemName: library.icon(for: scene)).frame(width: 22)
                                        .foregroundStyle(.orange.opacity(0.85))
                                    Text(RenderState.sceneNames[scene]).font(.system(size: 12, weight: .medium)).lineLimit(1)
                                    Spacer(minLength: 0)
                                    if scene == selected {Image(systemName: "checkmark").foregroundStyle(.orange)}
                                }.padding(.horizontal, 10).frame(maxWidth: .infinity, minHeight: 44)
                                    .background(scene == selected ? Color.orange.opacity(0.12) : .white.opacity(0.04), in: RoundedRectangle(cornerRadius: 7))
                                    .contentShape(Rectangle())
                            }.buttonStyle(.plain).accessibilityLabel("Use favorite \(RenderState.sceneNames[scene])")
                        }
                    }
                }.frame(height: min(CGFloat(scenes.count) * 47, 330))
            }
        }.padding(12).frame(width: 290)
    }
}

/// Only the progress fill observes the audio clock; cards change at section boundaries.
@MainActor
private struct StudioSectionProgress: View {
    let audio: AudioController
    let segment: StudioSegment
    let selected: Bool
    let palette: VisualPalette
    @State private var playbackRevision = 0
    var body: some View {
        let _ = playbackRevision
        let elapsed = min(1, max(0, (audio.playbackSeconds - segment.start) / (segment.end - segment.start)))
        GeometryReader { space in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.07))
                Capsule().fill(LinearGradient(colors: palette.stops.map { Color(red: Double($0.x), green: Double($0.y), blue: Double($0.z)) }, startPoint: .leading, endPoint: .trailing))
                    .frame(width: selected ? max(3, space.size.width * elapsed) : space.size.width)
            }
        }.frame(height: 3)
            .onReceive(audio.visualizationUpdated.throttle(for: .milliseconds(33), scheduler: RunLoop.main, latest: true)) {
                if selected { playbackRevision &+= 1 }
            }
    }
}
