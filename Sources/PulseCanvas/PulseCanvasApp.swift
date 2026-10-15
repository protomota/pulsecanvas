import AppKit
import AVFoundation
import Combine
import StoreKit
import SwiftUI
import UniformTypeIdentifiers

struct LegalCreditsView: View {
    private var legalDirectory: URL? {
        guard let resources = Bundle.main.resourceURL else { return nil }
        let legal = resources.appendingPathComponent("Legal")
        return FileManager.default.fileExists(atPath: legal.path) ? legal : resources
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Legal & Credits").font(.title2).accessibilityAddTraits(.isHeader)
                Text("Application").font(.headline)
                Text("PulseCanvas first-party code uses the PulseCanvas Source-Available Noncommercial License. Earlier MIT releases retain their original terms. Third-party components and assets have separate terms.")
                #if STORE_BUILD
                Text("Metal edition").font(.headline)
                Text("This App Store edition includes \(NativeEffects.activeIDs.count) Metal visualizers. The projectM engine, OpenGL presets, and texture pack are not included.")
                #else
                Text("projectM engine").font(.headline)
                Text("projectM 4.2.0 is included under LGPL 2.1 or later. Engine source and rebuild instructions accompany the matching source package.")
                Text("Preset provenance").font(.headline)
                Text("Cream of the Crop pack curated by ISOSCELES")
                Link("https://www.patreon.com/posts/pack-nestdrop-91682111", destination: URL(string: "https://www.patreon.com/posts/pack-nestdrop-91682111")!)
                Text("\(ProjectMPresets.shared.entries.count.formatted()) presets are available from the curated library. Bundled originals retain their pinned Cream of the Crop provenance; user imports, if present, have separate origins. Display labels are separate from original filenames and creator metadata. Upstream assumes public domain where author licenses are missing; individual permissions remain unresolved. Attribution does not establish licensing clearance.")
                Text("Texture provenance").font(.headline)
                Text("67 images come from the Milkdrop texture pack. Its inclusion guidance does not document individual asset grants; those permissions remain unresolved separately from the presets.")
                #if DIRECT_BUILD && canImport(Sparkle) && !LOCAL_BUILD
                Text("Automatic updates").font(.headline)
                Text("Sparkle provides signed updates for the direct-download edition. Update checks send only the information needed to deliver the app; system profiling is disabled.")
                #endif
                #endif
                Button("Open licenses, notices & provenance") {
                    if let legalDirectory { NSWorkspace.shared.open(legalDirectory) }
                }
            }.padding(24).textSelection(.enabled)
        }.frame(minWidth: 500, minHeight: 440)
    }
}

@main
struct PulseCanvasApp: App {
    @NSApplicationDelegateAdaptor(AppLifecycle.self) private var lifecycle
    @Environment(\.openWindow) private var openWindow
    @StateObject private var render = RenderState()
    @StateObject private var audio = AudioController()
    @StateObject private var radio = RadioController()
    @StateObject private var studio = StudioStore()
    @StateObject private var exporter = SocialExportController()
    @StateObject private var presentation = StudioPresentationController()
    #if DIRECT_BUILD && canImport(Sparkle) && !LOCAL_BUILD
    @StateObject private var updater = AppUpdater()
    #endif
    var body: some Scene {
        WindowGroup("PulseCanvas Studio") {
            CreatorView(render: render, audio: audio, radio: radio, studio: studio, exporter: exporter, presentation: presentation, lifecycle: lifecycle)
                #if DIRECT_BUILD && canImport(Sparkle) && !LOCAL_BUILD
                .environmentObject(updater)
                #endif
                .preferredColorScheme(.dark)
                .frame(minWidth: 1080, minHeight: 740)
                .onReceive(audio.visualizationUpdated) {
                    let target = radio.isActive ? radio.visualizer : render
                    target.audioTrebleAttackTime = audio.trebleAttackTime
                    target.audioTreblePulse = audio.selectedURL == nil ? nil : audio.treblePulse
                    target.audioBeatMotionTime = audio.beatMotionTime
                    target.audioMomentum = audio.momentum
                    target.audioPulse = audio.beatPulse
                    target.audioBands = audio.spectrum
                    target.audioEnvelopes = audio.envelopes
                    target.audioSwell = audio.swell
                    target.playbackTime = audio.selectedURL == nil ? nil : audio.playbackSeconds
                    if radio.isActive { radio.follow(time: audio.playbackSeconds) }
                    else if !exporter.isExporting && presentation.followsStudioTimeline { studio.follow(time: audio.playbackSeconds, render: render) }
                    if target.scene >= RenderState.nativeSceneNames.count { target.audioPCM = audio.visualizationPCM(at: audio.playbackSeconds) }
                }
                .onAppear {
                    NSApplication.shared.setActivationPolicy(.regular)
                    studio.apply(to: render)
                    audio.loadDefaultSoundtrackIfNeeded()
                    radio.attach(audio: audio)
                    lifecycle.attach(audio: audio, radio: radio)
                }
        }
        #if STORE_BUILD
        .defaultSize(width: 1440, height: 900)
        #else
        .defaultSize(width: 1440, height: 940)
        #endif
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Legal & Credits") { openWindow(id: "legal-credits") }
                #if DIRECT_BUILD && canImport(Sparkle) && !LOCAL_BUILD
                Button("Check for Updates…") { updater.checkForUpdates() }.disabled(!updater.canCheck)
                #endif
            }
            CommandMenu("Preview") {
                if presentation.isPresented {
                    Button("Exit presentation") { audio.pause(); presentation.dismiss() }
                } else {
                    Button(audio.isPlaying ? "Pause soundtrack" : "Play soundtrack") {
                        if radio.isActive { radio.togglePlayback() } else { audio.playPause() }
                    }.keyboardShortcut(.space, modifiers: [])
                    if radio.isActive {
                        Button("Next radio song") { radio.next() }.keyboardShortcut(.rightArrow, modifiers: [])
                        Button("Randomize radio visualizer") { radio.randomizeCurrentVisualizer() }.keyboardShortcut("r", modifiers: [.command, .shift])
                    } else {
                        Button("Next visualizer") { choose(1) }.keyboardShortcut(.rightArrow, modifiers: [])
                        Button("Previous visualizer") { choose(-1) }.keyboardShortcut(.leftArrow, modifiers: [])
                        Button("Random visualizer") { if !exporter.isExporting { studio.randomizeScene(render) } }.keyboardShortcut("r", modifiers: [.command, .shift])
                    }
                }
            }
        }
        #if DIRECT_BUILD && canImport(Sparkle) && !LOCAL_BUILD
        Settings {
            VStack(alignment: .leading, spacing: 16) {
                Text("Updates").font(.title2)
                Toggle("Automatically check for updates", isOn: $updater.automaticChecks)
                Text("The direct-download edition checks pulsecanvas.si for signed updates. System profiling is disabled.").font(.callout).foregroundStyle(.secondary)
                Button("Check for Updates…") { updater.checkForUpdates() }.disabled(!updater.canCheck)
            }.padding(24).frame(width: 440)
        }
        #endif
        Window("Legal & Credits", id: "legal-credits") {
            LegalCreditsView()
        }.defaultSize(width: 560, height: 540)
    }
    private func choose(_ direction: Int) {
        guard !exporter.isExporting else { return }
        let choices = ProjectMPresets.shared.availableScenes
        guard let position = choices.firstIndex(of: render.scene), !choices.isEmpty else { return }
        studio.selectScene(choices[(position + direction + choices.count) % choices.count], render: render)
    }
}

@MainActor
struct CreatorView: View {
    @Environment(\.openWindow) private var openWindow
    #if DIRECT_BUILD && canImport(Sparkle) && !LOCAL_BUILD
    @EnvironmentObject private var updater: AppUpdater
    #endif
    @ObservedObject var render: RenderState
    @ObservedObject var audio: AudioController
    @ObservedObject var radio: RadioController
    @ObservedObject var studio: StudioStore
    @ObservedObject var exporter: SocialExportController
    @ObservedObject var presentation: StudioPresentationController
    let lifecycle: AppLifecycle
    @State private var message = ""
    @ObservedObject private var presetLibrary = ProjectMPresets.shared
    @State private var showVisualizerBrowser = false
    @State private var showHelp = false
    @State private var showCommunityInHelp = false
    @State private var showProjectSettings = false
    @State private var showRadio = false
    @StateObject private var engagement = CreatorEngagement()
    @Environment(\.requestReview) private var requestReview
    @State private var timelineSoundtrack: URL?
    private let accent = Color(red: 0.95, green: 0.68, blue: 0.55)
    private let background = Color(red: 0.145, green: 0.12, blue: 0.16)
    private let panel = Color(red: 0.20, green: 0.17, blue: 0.22)

    var body: some View {
        ZStack {
            if radio.isActive {
                RadioPlayerView(radio: radio, audio: audio, render: radio.visualizer)
            } else if presentation.isPresented {
                StudioPresentationView(render: render, audio: audio, studio: studio, mode: presentation.mode, aspect: exporter.aspect) {
                    audio.pause(); presentation.dismiss()
                }
            } else { editor }
        }
        .background(StudioWindowReader(attach: { window in
            presentation.attach(window); lifecycle.track(window)
        }).frame(width: 0, height: 0))
        .onChange(of: presentation.isPresented) { _, active in if !active { audio.pause() } }
        .onReceive(radio.soundtrackInstalled) {
            if !radio.isActive { timelineSoundtrack = audio.selectedURL }
            message = ""
        }
        .onChange(of: audio.selectedURL) { _, url in
            guard !radio.isActive else { return }
            render.playbackTime = url == nil ? nil : audio.playbackSeconds
            render.audioTreblePulse = url == nil ? nil : audio.treblePulse
            if url != timelineSoundtrack {
                timelineSoundtrack = url
                studio.segments = []; studio.detectedBPM = nil
                if studio.isStudio && url != nil { detectSegments() }
            }
        }
        .onChange(of: exporter.isExporting) { _, exporting in if exporting { radio.pause() } }
        .sheet(isPresented: $showRadio) {
            RadioLibraryView(radio: radio) { showRadio = false }
                .dismissOnOutsideClick { showRadio = false }
        }
        .onChange(of: exporter.successfulSaveID) { _, id in
            if let id { engagement.videoSaved(id: id) }
        }
        .task { await engagement.observeStorefront() }
        .task(id: canPresentExportThanks) {
            guard canPresentExportThanks else { return }
            // Let the saved-video confirmation finish before another modal appears.
            do { try await Task.sleep(for: .seconds(11)) } catch { return }
            while canPresentExportThanks {
                // Other Studio sheets and an inactive app must not consume the reminder.
                if presentation.canPresentEditorSheet {
                    if engagement.presentExportThanks() {
                        #if STORE_BUILD
                        requestReview()
                        #endif
                    }
                    return
                }
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
            }
        }
        .sheet(isPresented: $engagement.showsThanks) {
            CreatorThanksView(engagement: engagement, isExportMilestone: true) { engagement.showsThanks = false }
                .dismissOnOutsideClick { engagement.showsThanks = false }
        }
    }

    private var canPresentExportThanks: Bool {
        engagement.pendingExportThanks && !exporter.isExporting && !presentation.isPresented
            && !showVisualizerBrowser && !showProjectSettings && !showHelp && !showRadio
    }

    private var editor: some View {
        GeometryReader { space in
            let compactness = min(1, max(0, (860 - space.size.height) / 120))
            VStack(spacing: 0) {
                toolbar(compactness: compactness, narrow: space.size.width < 1250)
                Divider()
                visualizers(compactness: compactness)
                Divider()
                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        canvas
                        Divider()
                        if studio.isStudio {
                            StudioTimelineView(studio: studio, render: render, audio: audio, exporting: exporter.isExporting, present: presentStudio, compactness: compactness)
                            Divider()
                        }
                        SoundtrackControls(audio: audio, exporting: exporter.isExporting,
                            selectSoundtrack: selectSoundtrack, compactness: compactness)
                            .padding(.horizontal, 20).padding(.vertical, 20 - 10 * compactness).background(panel)
                    }
                    Divider()
                    inspector.frame(width: 300)
                }
                Divider()
                HStack {
                    Text(message.isEmpty ? (radio.isActive ? radio.status : audio.status) : message).lineLimit(1)
                    Spacer()
                    if !exporter.status.isEmpty { Text(exporter.status).lineLimit(1).foregroundStyle(exporter.status.contains("failed") ? .red : .secondary) }
                    Text("\(ProjectMPresets.shared.availableScenes.count) visualizers").foregroundStyle(.secondary)
                }.font(.system(size: 11)).padding(.horizontal, 20).padding(.vertical, 9)
            }
        }
        .background(background).tint(accent)
        .overlay { ExportOverlayView(exporter: exporter) }
        .sheet(isPresented: $showVisualizerBrowser) {
            PulseCanvasLibraryView(radio: radio, selected: render.scene,
                choose: { scene in choose(scene); showVisualizerBrowser = false },
                dismiss: { showVisualizerBrowser = false })
                .dismissOnOutsideClick { showVisualizerBrowser = false }
        }
        .sheet(isPresented: $showProjectSettings) { projectSettings.dismissOnOutsideClick { showProjectSettings = false } }
        .sheet(isPresented: $showHelp) {
            Group {
            if showCommunityInHelp {
                CreatorThanksView(engagement: engagement) { showHelp = false }
            } else {
            VStack(alignment: .leading, spacing: 18) {
                Text("Create a music visual").font(.title2)
                Text("1. Choose a visualizer from the top row. Adjust its colors, motion, and camera on the right.")
                Text("2. Add a soundtrack. Play or scrub it to preview how the visuals react to the music.")
                Text("3. Open Project settings to choose your canvas shape and video quality. Save video lets you choose a folder and saves an MP4 with your full soundtrack and visuals.")
                Text("Phone uses 9:16. Portrait uses 3:4.").foregroundStyle(.secondary)
                DisclosureGroup("Privacy") {
                    Text("PulseCanvas processes music and videos locally on your Mac. Radio downloads its catalog and music from the library you choose; the hosting service receives ordinary network requests. Your own soundtracks are not uploaded. The app has no accounts, usage analytics or advertising tracking and does not record your microphone. Preferences, favorites and downloaded radio tracks are stored locally. Saved projects can contain a soundtrack path and a macOS access bookmark; audio and preset files are not embedded.")
                        .font(.callout).foregroundStyle(.secondary)
                }
                Button {
                    engagement.recordClick(.review)
                    NSWorkspace.shared.open(PulseCanvasCommunity.review)
                } label: {
                    Label("Rate on the App Store", systemImage: "star.bubble")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }.buttonStyle(StudioButtonStyle(treatment: .primary))
                Button("Ratings, sharing & support") { showCommunityInHelp = true }
                    .buttonStyle(StudioButtonStyle())
                Button("Legal & Credits") { openWindow(id: "legal-credits") }
                    .buttonStyle(StudioButtonStyle(compact: true))
                Button("Done") { showHelp = false }.buttonStyle(StudioButtonStyle(treatment: .primary))
            }.padding(30).frame(width: 500)
            }
            }.dismissOnOutsideClick { showHelp = false }
        }
    }

    private func toolbar(compactness: CGFloat, narrow: Bool) -> some View {
        HStack(spacing: 10) {
            Button { studio.randomizeScene(render) } label: {
                Label("Random visualizer", systemImage: "shuffle")
            }.buttonStyle(StudioButtonStyle(treatment: .accent))
                .help("Pick another visualizer with its saved settings")
            #if DIRECT_BUILD && canImport(Sparkle) && !LOCAL_BUILD
            AppUpdateButton(updater: updater)
            #endif
            Spacer(minLength: 8)
            Button { showVisualizerBrowser = true } label: { Label("Library", systemImage: "square.grid.2x2") }
                .help("Browse categories and save favorites")
            Button { showRadio = true } label: { Label("Radio", systemImage: "dot.radiowaves.left.and.right") }
                .help("Listen with a beat-aligned shuffle of your favorite visualizers")
            Button { openProject() } label: { Label("Open project", systemImage: "folder") }
            Button { saveProject() } label: { Label("Save project", systemImage: "square.and.arrow.down") }
            Button { showProjectSettings = true } label: { Label("Project settings", systemImage: "gearshape") }
            Button { startExport() } label: { Label("Save video", systemImage: "square.and.arrow.down") }
                .buttonStyle(StudioButtonStyle(treatment: .primary))
                .help("Choose a destination and save your video as an MP4")
            Button { showCommunityInHelp = false; showHelp = true } label: {
                Image(systemName: "questionmark").font(.system(size: 17, weight: .semibold))
            }
                .buttonStyle(StudioButtonStyle(circular: true))
                .help("How to create a video").accessibilityLabel("Help")
        }.buttonStyle(StudioButtonStyle(compact: narrow)).lineLimit(1)
            .padding(.horizontal, 22).padding(.vertical, 14 - 8 * compactness).disabled(exporter.isExporting)
    }

    private func visualizers(compactness: CGFloat) -> some View {
        HStack(spacing: 14) {
            VStack(spacing: 1) {
                Button("Visualizers") { radio.leave(); studio.isStudio = false }
                    .buttonStyle(StudioTabStyle(selected: !studio.isStudio))
                Button("Studio") {
                    studio.save(render); studio.isStudio = true
                    if studio.segments.isEmpty { detectSegments() }
                    studio.follow(time: audio.playbackSeconds, render: render)
                }.buttonStyle(StudioTabStyle(selected: studio.isStudio))
            }.padding(2).frame(width: 100)
                .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.white.opacity(0.12)))
                .disabled(exporter.isExporting)
            VisualizerPresetStrip(selected:render.scene, revealRequest: studio.visualizerRevealRequest, accent:accent, background:background, choose:choose)
                .equatable().frame(height: 90)
                .overlay {
                    HStack(spacing: 0) {
                        Rectangle().frame(width: 1)
                        Spacer(minLength: 0)
                        Rectangle().frame(width: 1)
                    }
                    .frame(height: 62)
                    .offset(y: -8)
                    .foregroundStyle(.white.opacity(0.22))
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
        }.padding(.horizontal, 20).padding(.vertical, 8 - 4 * compactness).background(panel).disabled(exporter.isExporting)
    }

    private var canvas: some View {
        GeometryReader { space in
            let layout = CanvasPreviewLayout(size: space.size, aspectRatio: exporter.aspect.aspectRatio)
            ZStack {
                ZStack {
                    Rectangle().fill(Color.black)
                    if !exporter.isExporting {
                        VisualizerView(state: render)
                    }
                }.frame(width: layout.preview.width, height: layout.preview.height)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(.white.opacity(0.12)))
                    .position(x: layout.preview.midX, y: layout.preview.midY)
                VStack(spacing: 0) {
                    canvasHeader
                        .shadow(color: layout.overlaysChrome ? .black.opacity(0.8) : .clear, radius: 3, y: 1)
                    Spacer(minLength: 0)
                    canvasFooter
                        .shadow(color: layout.overlaysChrome ? .black.opacity(0.8) : .clear, radius: 3, y: 1)
                }.padding(layout.padding)
            }.frame(width: space.size.width, height: space.size.height).clipped()
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var canvasHeader: some View {
        HStack {
            Text(RenderState.sceneNames[render.scene]).font(.system(size: 18, weight: .medium)).lineLimit(1)
            Spacer()
            Button { presetLibrary.toggleFavorite(render.scene) } label: {
                Label(presetLibrary.isFavorite(render.scene) ? "Favorited" : "Favorite", systemImage: presetLibrary.isFavorite(render.scene) ? "heart.fill" : "heart")
            }.buttonStyle(StudioButtonStyle(treatment: presetLibrary.isFavorite(render.scene) ? .accent : .quiet, compact: true))
                .help(presetLibrary.isFavorite(render.scene) ? "Remove this visualizer from Favorites" : "Add this visualizer to Favorites")
                .disabled(exporter.isExporting)
            if !studio.isStudio {
                Button { useAtPlayhead() } label: { Label("Use at playhead", systemImage: "timeline.selection") }
                    .buttonStyle(StudioButtonStyle(compact: true))
                    .help("Assign this visualizer to the Studio section at the current song position")
                    .disabled(audio.selectedURL == nil || exporter.isExporting)
                Button { presentVisualizer() } label: { Label("Present", systemImage: "play.rectangle.fill") }
                    .buttonStyle(StudioButtonStyle(treatment: .primary, compact: true))
                    .accessibilityLabel("Present visualizer full screen")
                    .help("Watch this visualizer full screen with the soundtrack. Escape returns to the editor.")
                    .disabled(exporter.isExporting)
            }
        }
    }

    private var canvasFooter: some View {
        VStack(spacing: 4) {
            HStack {
                Text(exporter.aspect.rawValue).foregroundStyle(.secondary)
                Spacer()
                let dimensions = exporter.aspect.dimensions(resolution: exporter.resolution)
                Text("\(dimensions.width) × \(dimensions.height)  /  \(exporter.fps) fps").monospacedDigit().foregroundStyle(.secondary)
            }.font(.system(size: 11))
            if let error = render.errorMessage { Text(error).font(.caption).foregroundStyle(.red) }
        }
    }

    private var inspector: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Group {
                    HStack {
                        Text("Visual style").font(.title3.weight(.semibold))
                        Spacer()
                        Button("Reset") { studio.reset(render) }
                            .buttonStyle(StudioButtonStyle(compact: true))
                            .help("Reset this visualizer to its default visual settings; all sections using it update")
                            .accessibilityLabel("Reset visualizer to defaults")
                        Button { studio.randomize(render) } label: { Image(systemName: "dice.fill").font(.system(size: 20, weight: .medium)).frame(width: 32, height: 32).contentShape(Rectangle()) }
                            .buttonStyle(StudioButtonStyle(compact: true)).help("Randomize visuals").accessibilityLabel("Randomize visuals")
                    }
                    if render.scene < RenderState.nativeSceneNames.count {
                    Text("Color palette").font(.system(size: 12, weight: .medium))
                    VStack(spacing: 4) {
                        ForEach(VisualPalette.allCases, id: \.rawValue) { palette in
                            Button { render.palette = palette.rawValue; studio.save(render) } label: {
                                HStack(spacing: 10) {
                                    HStack(spacing: 0) {
                                        ForEach(0..<palette.stops.count, id: \.self) { index in
                                            let rgb = palette.stops[index]
                                            Rectangle().fill(Color(red: Double(rgb.x), green: Double(rgb.y), blue: Double(rgb.z)))
                                        }
                                    }.frame(width: 70, height: 18).clipShape(RoundedRectangle(cornerRadius: 4))
                                    Text(palette.title).font(.system(size: 12))
                                    Spacer()
                                    if render.palette == palette.rawValue { Image(systemName: "checkmark").foregroundStyle(accent) }
                                }.padding(.horizontal, 10).frame(minHeight: 44)
                                    .background(render.palette == palette.rawValue ? accent.opacity(0.12) : background.opacity(0.4), in: RoundedRectangle(cornerRadius: 6))
                                    .contentShape(Rectangle())
                            }.buttonStyle(.plain).accessibilityLabel(palette.title).accessibilityAddTraits(render.palette == palette.rawValue ? .isSelected : [])
                        }
                    }
                    } else {
                        Text("This preset supplies its own colors, shapes, waves, and feedback. Adjust motion and audio response below.")
                            .font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                    Divider()
                    Text("Motion & depth").font(.system(size: 12, weight: .medium))
                    control("Motion speed", key: \.speed, range: 0.05...3)
                    control("Zoom speed", key: \.zoomSpeed, range: 0...3)
                        .help("Add continuous forward zoom. Zero keeps the framing flat while the visualization continues animating.")
                    control("Chaos", key: \.chaos, range: 0...1)
                        .help("Zero turns off music response while smooth visualization motion and zoom continue. Increase for beat-driven waves, local swelling, liquid deformation, and motion.")
                    control("Brightness", key: \.brightness, range: 0.1...3)
                    if let detail = NativeEffects.effect(render.scene)?.detailLabel {
                        control(detail, key: \.liquidDetail, range: 0...1)
                            .help(render.scene == 23 ? "Add flowing ripples, finer folds, and sharper liquid reflections." : "Add finer structure and surface detail.")
                    }
                    if render.scene == 28 {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack { Text("Halo count"); Spacer(); Text("\(render.haloCount)").foregroundStyle(.secondary).monospacedDigit() }
                            Slider(value: Binding(get: { Float(render.haloCount) }, set: { render.haloCount = Int($0.rounded()); studio.save(render) }), in: 1...12, step: 1)
                                .accessibilityLabel("Halo count")
                        }.font(.system(size: 11))
                            .help("Number of rings in each travelling group. Add more for a denser field of halos.")
                    }
                    if render.scene < RenderState.nativeSceneNames.count {
                    control(NativeEffects.effect(render.scene)?.sizeLabel ?? "Particle size", key: \.particleSize, range: 0.3...6)
                    control("Depth / fog", key: \.fog, range: 0...1)
                    }
                    control("Camera zoom", key: \.zoom, range: 0.3...2)
                    control("Camera rotation", key: \.rotation, range: -3.14...3.14)
                    control("Blur", key: \.motionBlur, range: 0...0.9)
                    Toggle("Hi-hat strobe", isOn: Binding(get: { render.strobeEnabled }, set: { render.strobeEnabled = $0; studio.save(render) })).toggleStyle(StudioSwitchStyle())
                    if render.strobeEnabled {
                        control("Strobe sensitivity", key: \.strobeSensitivity, range: 0.25...4)
                        control("Flash strength", key: \.strobeStrength, range: 0.1...1)
                        Text("White flashes follow rapid high-frequency attacks in the soundtrack.").font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                }.disabled(exporter.isExporting)
                if let url = exporter.exportedURL {
                    Button { NSWorkspace.shared.activateFileViewerSelecting([url]) } label: {
                        Label("Show in Finder", systemImage: "folder").frame(maxWidth: .infinity)
                    }.buttonStyle(StudioButtonStyle(compact: true))
                }
            }.padding(19)
        }.background(panel)
    }

    private var projectSettings: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Project settings").font(.title2.weight(.semibold))
            Text("Canvas shape and export quality for this project.").font(.system(size: 13)).foregroundStyle(.secondary)
            VStack(spacing: 18) {
                Picker("Canvas", selection: $exporter.aspect) {
                    ForEach(SocialAspect.allCases) { aspect in Text(aspect.rawValue).tag(aspect) }
                }
                Picker("Resolution", selection: $exporter.resolution) { Text("720p").tag(720); Text("1080p").tag(1080); Text("4K").tag(2160) }
                Picker("Frame rate", selection: $exporter.fps) {
                    ForEach(SocialExportController.supportedFrameRates, id: \.self) { rate in
                        Text(rate == 120 ? "120 fps (Experimental)" : "\(rate) fps").tag(rate)
                    }
                }
            }.pickerStyle(.menu).controlSize(.large)
            if exporter.fps == 120 {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "flask").foregroundStyle(accent)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Experimental frame rate").font(.system(size: 13, weight: .semibold))
                        Text("120 fps renders twice as many frames as 60 fps. Export times and playback support vary.")
                            .font(.system(size: 12)).foregroundStyle(.secondary)
                        #if !STORE_BUILD
                        Text("Some OpenGL presets may become darker or look different. Choose 60 fps if this happens.")
                            .font(.system(size: 12)).foregroundStyle(.secondary)
                        #endif
                    }.fixedSize(horizontal: false, vertical: true)
                }.padding(14).frame(maxWidth: .infinity, alignment: .leading)
                    .background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }
            Text("Resolution uses the shorter canvas edge. Export saves an MP4 with the soundtrack included.")
                .font(.system(size: 12)).foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("Done") { showProjectSettings = false }.buttonStyle(StudioButtonStyle(treatment: .primary))
            }
        }.padding(30).frame(width: 460).tint(accent)
    }

    private func control(_ name: String, key: ReferenceWritableKeyPath<RenderState, Float>, range: ClosedRange<Float>) -> some View {
        VStack(spacing: 6) {
            HStack { Text(name); Spacer(); Text(String(format: "%.2f", render[keyPath: key])).monospacedDigit().foregroundStyle(.secondary) }.font(.system(size: 11))
            Slider(value: Binding(get: { render[keyPath: key] }, set: { render[keyPath: key] = $0; studio.save(render) }), in: range)
                .accessibilityLabel(name)
        }
    }
    private func presentStudio() {
        guard studio.isStudio, audio.selectedURL != nil, !studio.segments.isEmpty, !exporter.isExporting else { return }
        studio.save(render)
        if presentation.present(audio: audio) { audio.playFullSoundtrack() }
    }

    private func presentVisualizer() {
        guard !studio.isStudio, !exporter.isExporting else { return }
        studio.save(render)
        if presentation.present(audio: audio, mode: .visualizer) { audio.playFullSoundtrack() }
    }

    private func choose(_ index: Int) { studio.selectScene(index, render: render); if index >= RenderState.nativeSceneNames.count { render.audioPCM = audio.visualizationPCM(at: audio.playbackSeconds) } }
    private func useAtPlayhead() {
        if studio.segments.isEmpty { detectSegments() }
        if let index = studio.assignAtPlayhead(audio.playbackSeconds, render: render) {
            message = "\(RenderState.sceneNames[render.scene]) assigned to section \(index + 1) · \(format(studio.segments[index].start))"
        } else { message = "Add a soundtrack to create Studio sections" }
    }
    private func detectSegments() {
        guard let plan = audio.segmentPlan(beatsPerSection: studio.beatsPerSection) else { return }
        studio.makeTimeline(plan, render: render)
        studio.follow(time: audio.playbackSeconds, render: render)
    }
    private func format(_ seconds: Double) -> String { guard seconds.isFinite else { return "0:00" }; return String(format: "%d:%02d", Int(max(0, seconds)) / 60, Int(max(0, seconds)) % 60) }
    private func selectSoundtrack() {
        let picker = NSOpenPanel(); picker.allowedContentTypes = [.audio]; picker.allowsMultipleSelection = false; picker.canChooseDirectories = false
        picker.message = "Choose the soundtrack for this video"
        if picker.runModal() == .OK, let url = picker.url {
            radio.leave()
            if audio.load(url: url) { message = "" }
        }
    }
    private func startExport() {
        guard !exporter.isExporting else { return }
        let picker = NSSavePanel(); picker.allowedContentTypes = [.mpeg4Movie]; picker.nameFieldStringValue = "PulseCanvas-\(RenderState.sceneNames[render.scene].replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: " ", with: "-").prefix(120)).mp4"
        picker.title = "Save video"
        picker.prompt = "Save video"
        picker.canCreateDirectories = true
        picker.message = "Choose where to save your finished video"
        guard picker.runModal() == .OK, let url = picker.url else { return }
        radio.pause(); audio.pause()
        studio.save(render)
        let segments = studio.isStudio ? studio.segments : []
        let appearances = studio.presets
        Task { await exporter.export(audioURL: audio.selectedURL, render: render, to: url, segments: segments, appearances: appearances) }
    }
    private func saveProject() {
        let picker = NSSavePanel(); picker.nameFieldStringValue = "Untitled.pulsecanvas"; picker.allowedContentTypes = [UTType(filenameExtension: "pulsecanvas") ?? .json]; picker.canSelectHiddenExtension = true
        guard picker.runModal() == .OK, let url = picker.url else { return }
        studio.save(render)
        let bundledSoundtrack = BundledSoundtrack.identifier(for: audio.selectedURL)
        let project = CreatorProject(soundtrack: bundledSoundtrack == nil ? audio.selectedURL : nil, scene: render.scene, appearance: studio.preset(render), aspect: exporter.aspect.rawValue, resolution: exporter.resolution, fps: exporter.fps, timeline: studio.segments, studioEnabled: studio.isStudio, visualPresets: studio.presets, barsPerSection: studio.barsPerSection, effectIdentities: presetLibrary.identities(for: Set(studio.presets.keys).union(studio.segments.map(\.scene)).union([render.scene])), bundledSoundtrack: bundledSoundtrack, soundtrackBookmark: audio.soundtrackBookmark)
        do { let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; try encoder.encode(project).write(to: url, options: .atomic); message = "Project saved" }
        catch { message = "Cannot save project: \(error.localizedDescription)" }
    }
    private func openProject() {
        let picker = NSOpenPanel(); picker.allowsMultipleSelection = false; picker.canChooseDirectories = false; picker.message = "Choose a PulseCanvas project"
        guard picker.runModal() == .OK, let url = picker.url else { return }
        radio.leave()
        do {
            var project = try JSONDecoder().decode(CreatorProject.self, from: Data(contentsOf: url))
            project = try project.remapped(using: presetLibrary)
            guard project.version == 1, RenderState.sceneNames.indices.contains(project.scene), [720, 1080, 2160].contains(project.resolution), SocialExportController.supportedFrameRates.contains(project.fps), let aspect = SocialAspect(rawValue: project.aspect), project.appearance.isValid else { throw CocoaError(.fileReadCorruptFile) }
            guard project.barsPerSection.map({ $0 > 0 && $0 <= Int.max / 4 }) ?? true else { throw CocoaError(.fileReadCorruptFile) }
            guard StudioTimeline.valid(project.timeline ?? [], sceneCount: RenderState.sceneNames.count) else { throw CocoaError(.fileReadCorruptFile) }
            guard project.visualPresets?.allSatisfy({ RenderState.sceneNames.indices.contains($0.key) && $0.value.isValid }) ?? true else { throw CocoaError(.fileReadCorruptFile) }
            let soundtrack = try BundledSoundtrack.resolve(identifier: project.bundledSoundtrack, externalURL: project.soundtrack)
            let previousSoundtrack = timelineSoundtrack
            timelineSoundtrack = soundtrack
            if let soundtrack {
                if !audio.load(url: soundtrack, bookmark: project.soundtrackBookmark) {
                    let locate = NSOpenPanel()
                    locate.allowedContentTypes = [.audio]
                    locate.allowsMultipleSelection = false; locate.canChooseDirectories = false
                    locate.message = "Locate this project’s soundtrack: \(soundtrack.lastPathComponent). Saved projects reference audio files; they do not include the audio."
                    guard locate.runModal() == .OK, let replacement = locate.url, audio.load(url: replacement) else {
                        timelineSoundtrack = previousSoundtrack; message = "Project was not opened. Its soundtrack is unavailable."; return
                    }
                }
                timelineSoundtrack = audio.selectedURL
            } else { audio.clear() }
            guard (project.timeline?.last?.end ?? 0) <= audio.duration + 0.05 else { throw CocoaError(.fileReadCorruptFile) }
            if let presets = project.visualPresets { studio.presets = presets }
            studio.segments = project.timeline ?? []; studio.isStudio = project.studioEnabled ?? false
            render.scene = project.scene; studio.apply(project.appearance, to: render)
            studio.selectedSegment = 0
            studio.barsPerSection = project.barsPerSection ?? 4
            exporter.aspect = aspect; exporter.resolution = project.resolution; exporter.fps = project.fps
            studio.detectedBPM = audio.segmentPlan(beatsPerSection: studio.beatsPerSection)?.bpm
            studio.follow(time: audio.playbackSeconds, render: render)
            message = "Project opened"
        } catch { message = "Cannot open project: \(error.localizedDescription)" }
    }
}

private struct SpectrumMeter: View {
    let bands: [Float]
    var body: some View {
        GeometryReader { size in
            let gap: CGFloat = 2
            HStack(alignment: .bottom, spacing: gap) {
                ForEach(0..<16, id: \.self) { index in
                    let band = bands.indices.contains(index) && bands[index].isFinite ? CGFloat(bands[index]) : 0
                    let height = max(2, size.size.height * min(1, max(0, band)))
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(Color(red: 0.95, green: 0.68, blue: 0.55).opacity(0.7))
                        .frame(width: 3, height: height)
                        .animation(.linear(duration: 0.065), value: height)
                }
            }.frame(width: size.size.width, height: size.size.height, alignment: .bottomLeading)
        }
    }
}

/// Keep frame-rate playback updates inside the small soundtrack panel.
@MainActor
private struct SoundtrackControls: View {
    @ObservedObject var audio: AudioController
    let exporting: Bool
    let selectSoundtrack: () -> Void
    var compactness: CGFloat = 0
    @State private var playbackRevision = 0
    private let accent = Color(red: 0.95, green: 0.68, blue: 0.55)
    var body: some View {
        let _ = playbackRevision
        VStack(alignment: .leading, spacing: 14 - 6 * compactness) {
            HStack(spacing: 12) {
                Image(systemName: "waveform").font(.system(size: 18)).foregroundStyle(accent)
                    .frame(width: 44, height: 44).background(accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 4) {
                    Text(audio.title).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                    Text(audio.selectedURL == nil ? "Add music to sync your visuals." : "\(format(audio.duration)) soundtrack")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Spacer()
                Button { selectSoundtrack() } label: {
                    Label(audio.selectedURL == nil ? "Add soundtrack" : "Replace audio", systemImage: "waveform.badge.plus")
                }
                if audio.selectedURL != nil {
                    Button { audio.clear() } label: { Image(systemName: "xmark").frame(width: 20) }
                        .buttonStyle(StudioButtonStyle(treatment: .quiet, compact: true))
                        .help("Remove soundtrack").accessibilityLabel("Remove soundtrack")
                }
            }.buttonStyle(StudioButtonStyle())
            HStack(spacing: 14) {
                Button { audio.playPause() } label: {
                    Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 17, weight: .semibold)).frame(width: 22, height: 4)
                }.buttonStyle(StudioButtonStyle(treatment: .primary, compact: true))
                    .accessibilityLabel(audio.isPlaying ? "Pause soundtrack" : "Play soundtrack")
                    .help("Play or pause soundtrack (Space)").disabled(audio.selectedURL == nil)
                VStack(spacing: 4) {
                    HStack {
                        Text(format(audio.playbackSeconds))
                        Spacer()
                        Text(format(audio.duration)).foregroundStyle(.secondary)
                    }.font(.system(size: 12, weight: .medium)).monospacedDigit()
                    Slider(value: Binding(get: { audio.progress }, set: { audio.seek(fraction: $0) }), in: 0...1)
                        .accessibilityLabel("Soundtrack position").disabled(audio.selectedURL == nil)
                }
                    SpectrumMeter(bands: audio.spectrum).frame(width: 78, height: 28).accessibilityHidden(true)
                Toggle("Loop", isOn: $audio.loopEnabled).toggleStyle(StudioSwitchStyle(icon: "repeat"))
                    .fixedSize(horizontal: true, vertical: false)
                    .help("Repeat the soundtrack when it ends").disabled(audio.selectedURL == nil)
                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.2").font(.system(size: 13)).foregroundStyle(.secondary)
                    Slider(value: $audio.volume, in: 0...1).frame(width: 70).accessibilityLabel("Preview volume")
                }
            }
        }.disabled(exporting)
            .onReceive(audio.visualizationUpdated.throttle(for: .milliseconds(33), scheduler: RunLoop.main, latest: true)) { playbackRevision &+= 1 }
    }

    private func format(_ seconds: Double) -> String {
        let seconds = max(0, Int(seconds)); return "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }
}
