import SwiftUI
import StoreKit
#if os(macOS)
import AppKit
#else
import UIKit
#if os(tvOS)
import CoreImage.CIFilterBuiltins
#endif
#endif

extension Notification.Name {
    static let pulseCanvasOnboarding = Notification.Name("PulseCanvas.showOnboarding")
}

#if os(visionOS)
private struct PulseCanvasOnboardingActiveKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var pulseCanvasOnboardingActive: Bool {
        get { self[PulseCanvasOnboardingActiveKey.self] }
        set { self[PulseCanvasOnboardingActiveKey.self] = newValue }
    }
}
#endif

enum PulseCanvasOnboarding {
    static let completedKey = "PulseCanvas.onboarding.completed.v1"
    static var initialStep: Int {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "-PCOnboardingStep"), args.indices.contains(index + 1) {
            return min(4, max(0, Int(args[index + 1]) ?? 0))
        }
        #endif
        return 0
    }
    static var forced: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-PCOnboardingQA")
        #else
        return false
        #endif
    }
    static var fixture: Bool {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        return !forced && (args.contains("-PCMobileQA") || args.contains("-PCUITesting"))
        #else
        return false
        #endif
    }
}

/// Owns the entire root surface; onboarding is never presented in a sheet or popover.
struct PulseCanvasOnboardingPresentation: ViewModifier {
    var onReplay: () -> Void = {}
    @AppStorage(PulseCanvasOnboarding.completedKey) private var completed = false
    @State private var replay = false
    @State private var presentationID = UUID()
    @State private var force = PulseCanvasOnboarding.forced
    private var showingOnboarding: Bool {
        replay || force || (!completed && !PulseCanvasOnboarding.fixture)
    }
    func body(content: Content) -> some View {
        Group {
            #if os(visionOS)
            // Keep the established spatial editor attached to its window during
            // replay. Removing and reinserting it can leave its controls unhittable.
            ZStack {
                if (completed || PulseCanvasOnboarding.fixture) && !force {
                    content.opacity(showingOnboarding ? 0 : 1)
                        .environment(\.pulseCanvasOnboardingActive, showingOnboarding)
                        .allowsHitTesting(!showingOnboarding)
                        .accessibilityElement(children: showingOnboarding ? .ignore : .contain)
                        .accessibilityHidden(showingOnboarding)
                }
                if showingOnboarding { onboarding }
            }
            #else
            if showingOnboarding { onboarding } else { content }
            #endif
        }
        .onReceive(NotificationCenter.default.publisher(for: .pulseCanvasOnboarding)) { _ in
            onReplay()
            presentationID = UUID()
            replay = true
        }
    }
    private var onboarding: some View {
        PulseCanvasOnboardingView(initialStep: replay ? 0 : PulseCanvasOnboarding.initialStep) {
            completed = true
            replay = false
            force = false
        }.id(presentationID)
    }
}

struct PulseCanvasOnboardingView: View {
    let finish: () -> Void
    @State private var step: Int
    init(initialStep: Int = PulseCanvasOnboarding.initialStep, finish: @escaping () -> Void) {
        self.finish = finish
        _step = State(initialValue: min(4, max(0, initialStep)))
    }
    #if os(tvOS)
    @State private var supportURL: URL?
    #endif
    @StateObject private var engagement = CreatorEngagement()
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize = 42
    @ScaledMetric(relativeTo: .largeTitle) private var tabletTitleSize = 56
    @ScaledMetric(relativeTo: .body) private var tabletBodySize = 24
    @ScaledMetric(relativeTo: .headline) private var tabletLessonTitleSize = 23
    @ScaledMetric(relativeTo: .subheadline) private var tabletDetailSize = 20
    @ScaledMetric(relativeTo: .footnote) private var tabletNoteSize = 18
    private let accent = Color(red: 0.95, green: 0.68, blue: 0.55)
    private let background = Color(red: 50.0 / 255, green: 44.0 / 255, blue: 55.0 / 255)
    private let ink = Color.white
    private var names: [String] {
        #if os(tvOS)
        ["Welcome", "Visualizers", "Radio", "Viewing", "Support"]
        #else
        ["Welcome", "Visualizers", "Studio", "Play & share", "Support"]
        #endif
    }
    private let assets = ["welcome", "visuals", "studio", "share", "support"]
    #if os(iOS)
    private let locksTextPositions = true
    #else
    private let locksTextPositions = false
    #endif
    #if os(tvOS)
    private let isTV = true
    #else
    private let isTV = false
    #endif
    private func title(for step: Int) -> String {
        switch step {
        case 0: return "Your music.\nYour visual world."
        case 1: return "Find a look.\nMake it yours."
        case 2:
            #if os(tvOS)
            return "Press play.\nSet the room in motion."
            #else
            return "Give your song\na visual story."
            #endif
        case 3:
            #if os(tvOS)
            return "Less on screen.\nMore to get lost in."
            #elseif os(visionOS)
            return "Make room\nfor your music."
            #else
            return "From your canvas\nto any screen."
            #endif
        default: return "Free to create.\nSupported by you."
        }
    }
    private func subtitle(for step: Int) -> String {
        switch step {
        case 0: return "Turn sound into moving art with PulseCanvas Studio. A few basics, then the canvas is yours."
        case 1: return "Explore the visualizer library, save your favorites, and shape the colors and motion to suit your music."
        case 2:
            #if os(tvOS)
            return "Open Music & Radio to choose a station. PulseCanvas pairs the music with a changing sequence of visuals."
            #else
            return "Choose music or import a soundtrack. Studio finds the beat so your scenes can change with the song."
            #endif
        case 3:
            #if os(tvOS)
            return "Choose Hide controls for an uninterrupted view. Use the remote to bring playback and visual controls back."
            #elseif os(visionOS)
            return "Open the immersive screen to surround yourself with the visuals, or export your Studio project as an MP4."
            #else
            return "Enjoy your visuals full screen, or export an MP4 with your soundtrack, ready to save and share."
            #endif
        default: return "Every feature is free, with no account or subscription. Your support helps us keep building."
        }
    }
    private func lessons(for step: Int) -> [(String, String, String)] {
        switch step {
        case 0: return [("waveform", "Start with a song", "Try the included music or discover a station in Radio."),
                        ("sparkles", "Watch the music move", "Visuals respond to the rhythm as you listen.")]
        case 1: return [("square.grid.2x2", "Explore the library", "Browse categories and heart the looks you love."),
                        ("slider.horizontal.3", "Shape your style", "Adjust palettes, motion, and Chaos for a different feel.")]
        case 2:
            #if os(tvOS)
            return [("radio", "Choose your station", "Find music in Music & Radio, then press Play."),
                    ("shuffle", "Try another visual", "Use Randomize to change the look while the song continues.")]
            #else
            return [("rectangle.stack", "Build scenes in Studio", "Choose a visualizer and a bar length for each scene."),
                    ("shuffle", "Try a new sequence", "Randomize the timeline, then fine-tune your favorite moments.")]
            #endif
        case 3:
            #if os(tvOS)
            return [("playpause", "Keep the remote close", "Play/Pause controls the music. Back reveals or hides controls."),
                    ("heart", "Keep your favorites", "Heart a visualizer to find it again in the library.")]
            #elseif os(visionOS)
            return [("vision.pro", "Open the immersive screen", "Choose Hide room for full immersion before entering."),
                    ("film", "Save your creation", "Export MP4 renders the Studio timeline with your soundtrack.")]
            #elseif os(macOS)
            return [("arrow.up.left.and.arrow.down.right", "Press Present", "Space pauses playback. Escape returns to the editor."),
                    ("film", "Save a video", "In Project settings, choose a canvas and quality. Then choose Save video.")]
            #else
            return [("arrow.up.left.and.arrow.down.right", "Open full-screen viewing", "Tap to reveal the controls while you listen."),
                    ("film", "Export your video", "Open Project actions → Export MP4. Render, then Save video to Files.")]
            #endif
        default: return []
        }
    }
    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width >= 760 || geometry.size.width > geometry.size.height
            let short = geometry.size.height < 500 && wide
            #if os(iOS)
            let largeTablet = UIDevice.current.userInterfaceIdiom == .pad && min(geometry.size.width, geometry.size.height) >= 900
            #else
            let largeTablet = false
            #endif
            VStack(spacing: 0) {
                header(wide: wide).zIndex(2)
                GeometryReader { pageGeometry in
                    OnboardingFittedContent(alignment: locksTextPositions && !largeTablet ? .topLeading : .center) {
                        page(wide: wide, size: pageGeometry.size, compact: pageGeometry.size.height < 480, largeTablet: largeTablet)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .clipped()
                }.id(step)
                footer(wide: wide, short: short).zIndex(2)
            }
            .padding(.horizontal, isTV ? 85 : (wide ? 48 : 24))
            .padding(.top, isTV ? 46 : 16)
            .padding(.bottom, isTV ? 40 : 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(background.ignoresSafeArea())
            #if !os(tvOS)
            .contentShape(Rectangle())
            // A recognized drag takes precedence over button taps so swiping
            // across Continue cannot also activate it. Ordinary taps still work.
            .highPriorityGesture(DragGesture(minimumDistance: 20).onEnded { value in
                let distance = value.translation
                #if os(iOS)
                // Accept a deliberate short flick as well as a longer drag.
                // Require real horizontal travel before consulting momentum.
                let projected = value.predictedEndTranslation
                guard abs(distance.width) >= 24,
                      abs(distance.width) > abs(distance.height) * 1.25,
                      abs(distance.width) >= 44 || (distance.width * projected.width > 0 && abs(projected.width) >= 80) else { return }
                #else
                guard abs(distance.width) >= 44,
                      abs(distance.width) > abs(distance.height) * 1.25 else { return }
                #endif
                changeStep(step + (distance.width < 0 ? 1 : -1))
            })
            #if os(macOS)
            .background(OnboardingTrackpadNavigation { direction in
                changeStep(step + direction)
            })
            #endif
            #endif
        }
        .dynamicTypeSize(.xSmall ... .xxxLarge)
        .foregroundStyle(ink).tint(accent).preferredColorScheme(.dark).environment(\.colorScheme, .dark)
        .task { await engagement.observeStorefront() }
        #if DEBUG
        .task(id: step) {
            // A capture waits for the actual page to appear before taking its screenshot.
            guard PulseCanvasOnboarding.forced else { return }
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            let file = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("onboarding-capture-ready.txt")
            try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? String(step).write(to: file, atomically: true, encoding: .utf8)
        }
        #endif
        #if os(tvOS)
        .onExitCommand { if step > 0 { changeStep(step - 1) } else { finish() } }
        #endif
    }
    @ViewBuilder private func page(wide: Bool, size: CGSize, compact: Bool, largeTablet: Bool) -> some View {
        if wide {
            HStack(alignment: locksTextPositions && !largeTablet ? .top : .center, spacing: compact ? 28 : (isTV ? 75 : 54)) {
                illustration
                    .frame(width: min(size.width * 0.44, isTV || largeTablet ? 620 : 510),
                           height: min(size.height * (compact ? 0.75 : 0.94), isTV || largeTablet ? 620 : 510))
                copy(wide: true, compact: compact, largeTablet: largeTablet).frame(maxWidth: isTV ? 660 : (largeTablet ? 600 : 490))
            }.frame(maxWidth: isTV ? 1450 : (largeTablet ? 1280 : 1120))
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("onboardingContent")
        } else {
            VStack(alignment: .leading, spacing: compact ? 12 : 20) {
                illustration.frame(height: min(compact ? 110 : 220, size.height * (compact ? 0.22 : 0.32)))
                    .frame(maxWidth: .infinity)
                copy(wide: false, compact: compact, largeTablet: false)
            }.frame(maxWidth: 500)
        }
    }
    private var startTitle: String {
        #if os(tvOS)
        "Start listening"
        #else
        "Start creating"
        #endif
    }
    private func header(wide: Bool) -> some View {
        HStack(spacing: 10) {
            if let logo = onboardingImage(named: "logo") {
                logo.resizable().interpolation(.high).scaledToFit()
                    .frame(width: isTV ? 58 : 36, height: isTV ? 58 : 36)
                    .clipShape(RoundedRectangle(cornerRadius: isTV ? 12 : 8)).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("PulseCanvas").font(.system(size: isTV ? 28 : 19, weight: .semibold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.8)
                Text("Studio").font(.caption).foregroundStyle(ink.opacity(0.92))
            }
            Spacer()
            Button("Skip onboarding", action: finish).lineLimit(1).minimumScaleFactor(0.8).buttonStyle(OnboardingButtonStyle(primary: false, compact: true))
                .accessibilityIdentifier("onboardingSkip")
        }.frame(minHeight: isTV ? 70 : 48)
    }
    private var illustration: some View {
        Group {
            #if os(tvOS)
            if step == 4, let url = supportURL, let qr = qrImage(for: url) {
                VStack(spacing: 20) {
                    Image(uiImage: qr).resizable().interpolation(.none).scaledToFit()
                        .padding(24).background(.white, in: RoundedRectangle(cornerRadius: 24))
                    Text("Scan with your phone").font(.title3)
                    Text(url.host ?? "pulsecanvas.si").font(.callout).foregroundStyle(.secondary)
                }.padding(60)
            } else if let image = onboardingImage(named: assets[step]) {
                image.resizable().interpolation(.high).scaledToFit()
            }
            #else
            if let image = onboardingImage(named: assets[step]) {
                image.resizable().interpolation(.high).scaledToFit()
            }
            #endif
        }
        .accessibilityHidden(true)
    }
    private func onboardingImage(named name: String) -> Image? {
        let directories = ["Resources/Onboarding", "Onboarding"]
        guard let url = directories.compactMap({ Bundle.module.url(forResource: name, withExtension: "png", subdirectory: $0) }).first else { return nil }
        #if os(macOS)
        guard let image = NSImage(contentsOf: url) else { return nil }
        return Image(nsImage: image)
        #else
        guard let image = UIImage(contentsOfFile: url.path) else { return nil }
        return Image(uiImage: image)
        #endif
    }
    private func copy(wide: Bool, compact: Bool, largeTablet: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 12 : (isTV ? 26 : 20)) {
            copySection { index in
                Text(title(for: index)).font(.system(size: isTV ? (compact ? 46 : 54) : (largeTablet ? tabletTitleSize : min(titleSize, wide ? 52 : 38) * (compact ? 0.88 : 1)), weight: .bold, design: .rounded))
                    .tracking(-1.2).fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("onboardingTitle").accessibilityAddTraits(.isHeader)
            }
            copySection { index in
                Text(subtitle(for: index)).font(isTV ? .system(size: compact ? 24 : 28) : (largeTablet ? .system(size: tabletBodySize) : (compact ? .callout : .body))).foregroundStyle(ink.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true).lineSpacing(3)
                    .accessibilityIdentifier("onboardingSubtitle")
            }
            #if os(iOS)
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: compact ? 12 : 18) {
                    ForEach(0..<2) { row in
                        copySection(steps: 0..<4) { index in
                            lessonRow(lessons(for: index)[row], compact: compact, largeTablet: largeTablet)
                        }.accessibilityIdentifier("onboardingLesson\(row)")
                    }
                }.accessibilityHidden(step == 4)
                if step == 4 { support(largeTablet: largeTablet) }
                else { support(largeTablet: largeTablet).hidden().accessibilityHidden(true) }
            }
            #else
            copySection { index in
                details(for: index, compact: compact)
            }
            #endif
        }.frame(maxWidth: locksTextPositions ? .infinity : nil, alignment: .topLeading)
    }
    @ViewBuilder private func copySection<Content: View>(steps: Range<Int> = 0..<5, @ViewBuilder content: @escaping (Int) -> Content) -> some View {
        #if os(iOS)
        // Reserve the largest section across all slides in this layout pass.
        // Titles, descriptions and details therefore keep the same top/left
        // origins, including after rotation and Dynamic Type changes.
        ZStack(alignment: .topLeading) {
            ZStack(alignment: .topLeading) {
                ForEach(steps, id: \.self) { index in
                    content(index).hidden()
                }
            }.accessibilityElement(children: .ignore).accessibilityHidden(true)
            if steps.contains(step) {
                content(step)
            }
        }.frame(maxWidth: .infinity, alignment: .topLeading)
        #else
        content(step)
        #endif
    }
    @ViewBuilder private func details(for step: Int, compact: Bool) -> some View {
        if step == 4 { support() }
        else {
            VStack(alignment: .leading, spacing: compact ? 12 : (isTV ? 24 : 18)) {
                ForEach(lessons(for: step), id: \.0) { lesson in
                    lessonRow(lesson, compact: compact)
                }
            }
        }
    }
    private func lessonRow(_ lesson: (String, String, String), compact: Bool, largeTablet: Bool = false) -> some View {
        HStack(alignment: .onboardingLessonTitle, spacing: 14) {
            Image(systemName: lesson.0).font(.system(size: isTV ? 30 : (largeTablet ? 28 : 22))).foregroundStyle(accent)
                .frame(width: isTV || largeTablet ? 40 : 28).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(lesson.1).font(isTV ? .system(size: compact ? 23 : 26, weight: .semibold) : (largeTablet ? .system(size: tabletLessonTitleSize, weight: .semibold) : (compact ? .subheadline.weight(.semibold) : .headline)))
                    .alignmentGuide(.onboardingLessonTitle) { $0[VerticalAlignment.center] }
                Text(lesson.2).font(isTV ? .system(size: compact ? 20 : 22) : (largeTablet ? .system(size: tabletDetailSize) : (compact ? .caption : .subheadline))).foregroundStyle(ink.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }.accessibilityElement(children: .combine)
    }
    private func support(largeTablet: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            #if os(tvOS)
            if engagement.offersWebsiteTip {
                Button { supportURL = PulseCanvasCommunity.tips } label: {
                    Label("Buy Me a Coffee", systemImage: "cup.and.saucer").frame(maxWidth: .infinity)
                }.buttonStyle(OnboardingButtonStyle(primary: false)).accessibilityIdentifier("onboardingCoffee")
            }
            Button { supportURL = PulseCanvasCommunity.review } label: {
                Label("Rate on the App Store", systemImage: "star").frame(maxWidth: .infinity)
            }.buttonStyle(OnboardingButtonStyle(primary: false)).accessibilityIdentifier("onboardingRate")
            Text("Choose an option, then scan the code with your phone.").font(.system(size: 20)).foregroundStyle(.secondary)
            #else
            if engagement.offersWebsiteTip {
                Button {
                    engagement.recordClick(.tip); openURL(PulseCanvasCommunity.tips)
                } label: { Label("Buy Me a Coffee", systemImage: "cup.and.saucer").frame(maxWidth: .infinity) }
                    .buttonStyle(OnboardingButtonStyle(primary: false, fontSize: largeTablet ? tabletLessonTitleSize : nil))
                    .accessibilityIdentifier("onboardingCoffee")
                    .accessibilityHint("Opens Buy Me a Coffee in your browser")
            }
            Button {
                engagement.recordClick(.review); openURL(PulseCanvasCommunity.review)
            } label: { Label("Rate on the App Store", systemImage: "star").frame(maxWidth: .infinity) }
                .buttonStyle(OnboardingButtonStyle(primary: false, fontSize: largeTablet ? tabletLessonTitleSize : nil)).accessibilityIdentifier("onboardingRate")
            #endif
            Text("Always optional. Find onboarding and support again in \(supportLocation).")
                .font(isTV ? .system(size: 20) : (largeTablet ? .system(size: tabletNoteSize) : .footnote)).foregroundStyle(ink.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    #if os(tvOS)
    private func qrImage(for url: URL) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(url.absoluteString.utf8)
        guard let output = filter.outputImage,
              let cg = CIContext().createCGImage(output.transformed(by: CGAffineTransform(scaleX: 10, y: 10)), from: output.extent.applying(CGAffineTransform(scaleX: 10, y: 10))) else { return nil }
        return UIImage(cgImage: cg)
    }
    #endif
    private var supportLocation: String {
        #if os(macOS)
        return "Settings"
        #elseif os(tvOS)
        return "Settings"
        #else
        return "Settings"
        #endif
    }
    @ViewBuilder private func footer(wide: Bool, short: Bool) -> some View {
        if short {
            HStack(spacing: 24) {
                progress(compact: true)
                navigation.frame(maxWidth: 360)
            }.frame(maxWidth: .infinity).padding(.top, 10)
        } else {
            VStack(spacing: isTV ? 24 : 18) {
                progress(compact: false)
                navigation.frame(maxWidth: isTV ? 560 : 420)
            }.frame(maxWidth: .infinity).padding(.top, 14)
        }
    }
    private func progress(compact: Bool) -> some View {
        HStack(spacing: 7) {
            if !compact {
                ForEach(0..<5) { index in
                    Capsule().fill(index == step ? accent : ink.opacity(0.18))
                        .frame(width: index == step ? 26 : 7, height: 6)
                }
            }
            Text("\(step + 1) of 5 · \(names[step])").font(isTV ? .callout : .caption)
                .foregroundStyle(ink.opacity(0.92)).padding(.leading, 7)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(step + 1) of 5, \(names[step])")
        .accessibilityIdentifier("onboardingProgress")
        #if !os(tvOS)
        .accessibilityHint("Adjust to move between onboarding pages")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: changeStep(step + 1)
            case .decrement: changeStep(step - 1)
            @unknown default: break
            }
        }
        #endif
    }
    private var navigation: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button { changeStep(step - 1) } label: { Image(systemName: "chevron.left").frame(width: 20) }
                    .buttonStyle(OnboardingButtonStyle(primary: false)).accessibilityLabel("Back")
                    .accessibilityIdentifier("onboardingBack")
            }
            Button {
                if step == 4 { finish() } else { changeStep(step + 1) }
            } label: {
                HStack(spacing: 12) {
                    Text(step == 4 ? startTitle : "Continue").lineLimit(1).minimumScaleFactor(0.7)
                    Image(systemName: "arrow.right")
                }.frame(maxWidth: .infinity)
            }.buttonStyle(OnboardingButtonStyle(primary: true)).accessibilityIdentifier("onboardingContinue")
        }
    }
    private func changeStep(_ value: Int) {
        let next = min(names.count - 1, max(0, value))
        guard next != step else { return }
        #if os(tvOS)
        supportURL = nil
        #endif
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) { step = next }
    }
}

private extension VerticalAlignment {
    struct OnboardingLessonTitleAlignment: AlignmentID {
        static func defaultValue(in dimensions: ViewDimensions) -> CGFloat { dimensions[VerticalAlignment.center] }
    }
    static let onboardingLessonTitle = VerticalAlignment(OnboardingLessonTitleAlignment.self)
}

#if os(macOS)
/// SwiftUI's DragGesture covers click-and-drag. AppKit delivers two-finger
/// trackpad navigation as scroll events, so observe those only while this
/// onboarding surface is visible in its own window.
private struct OnboardingTrackpadNavigation: NSViewRepresentable {
    var navigate: (Int) -> Void

    func makeNSView(context: Context) -> TrackpadView {
        let view = TrackpadView()
        view.navigate = navigate
        return view
    }
    func updateNSView(_ view: TrackpadView, context: Context) { view.navigate = navigate }
    static func dismantleNSView(_ view: TrackpadView, coordinator: ()) { view.stopObserving() }

    final class TrackpadView: NSView {
        var navigate: (Int) -> Void = { _ in }
        private var monitor: Any?
        private var travel = CGSize.zero

        override func hitTest(_ point: NSPoint) -> NSView? { nil }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            stopObserving()
            guard window != nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel, .swipe]) { [weak self] event in
                self?.handle(event)
                return event
            }
        }

        func stopObserving() {
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
            travel = .zero
        }

        private func handle(_ event: NSEvent) {
            guard let window, event.window === window, window.isKeyWindow,
                  !isHiddenOrHasHiddenAncestor,
                  bounds.contains(convert(event.locationInWindow, from: nil)) else {
                travel = .zero
                return
            }
            if event.type == .swipe {
                // NSEvent uses +1 for a left swipe and -1 for a right swipe.
                if abs(event.deltaX) > abs(event.deltaY) { navigate(event.deltaX > 0 ? 1 : -1) }
                travel = .zero
                return
            }
            guard event.hasPreciseScrollingDeltas, event.momentumPhase.isEmpty,
                  !event.phase.isEmpty else { return }
            if event.phase.contains(.began) { travel = .zero }
            if event.phase.contains(.cancelled) { travel = .zero; return }
            travel.width += event.scrollingDeltaX
            travel.height += event.scrollingDeltaY
            if event.phase.contains(.ended) {
                defer { travel = .zero }
                guard abs(travel.width) >= 44,
                      abs(travel.width) > abs(travel.height) * 1.25 else { return }
                navigate(travel.width < 0 ? 1 : -1)
            }
        }
    }
}
#endif

private struct OnboardingButtonStyle: ButtonStyle {
    var primary: Bool
    var compact = false
    var fontSize: CGFloat? = nil
    @Environment(\.isEnabled) private var enabled
    @Environment(\.isFocused) private var focused
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            #if os(tvOS)
            .font(.system(size: compact ? 24 : 26, weight: .semibold))
            #else
            .font(fontSize.map { .system(size: $0, weight: .semibold) } ?? (compact ? .subheadline.weight(.medium) : .headline))
            #endif
            .padding(.horizontal, compact ? 16 : 22).padding(.vertical, compact ? 12 : 17)
            .foregroundStyle(primary ? Color(red: 0.16, green: 0.12, blue: 0.20) : .white)
            .background(primary ? Color(red: 0.95, green: 0.68, blue: 0.55) : .white.opacity(configuration.isPressed ? 0.12 : 0.065), in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(primary ? 0 : 0.12), lineWidth: 1))
            .opacity(enabled ? (configuration.isPressed ? 0.8 : 1) : 0.4)
            #if os(tvOS)
            .brightness(focused ? 0.10 : 0)
            #endif
    }
}

/// Fit lesson artwork and copy to the available space without scrolling or
/// covering the header and navigation. Measure and transform in one layout pass.
private struct OnboardingFittedContent<Content: View>: View {
    var alignment: Alignment
    @ViewBuilder var content: () -> Content
    var body: some View {
        GeometryReader { available in
            content()
                .frame(width: available.size.width)
                .fixedSize(horizontal: false, vertical: true)
                .visualEffect { effect, measured in
                    effect.scaleEffect(min(1, available.size.height / max(1, measured.size.height)), anchor: alignment == .topLeading ? .topLeading : .center)
                }
                .frame(width: available.size.width, height: available.size.height, alignment: alignment)
                .clipped()
        }
    }
}
