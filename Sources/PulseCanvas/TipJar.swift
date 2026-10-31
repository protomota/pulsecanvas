#if STORE_BUILD
import Combine
import Foundation
import RevenueCat
import SwiftUI
#if os(macOS)
import AppKit
#endif

/// Explain failures without exposing receipts, account identifiers or error userInfo.
struct TipPurchaseFailure {
    static let purchaseErrorDomain = ErrorCode.errorDomain
    let message: String
    let diagnostic: String

    init(_ error: Error) {
        let failure = error as NSError
        let code = failure.domain == Self.purchaseErrorDomain ? ErrorCode(rawValue: failure.code) : nil
        switch code {
        case .some(.purchaseCancelledError):
            message = "The App Store cancelled this purchase. If you didn’t cancel, Apple Account sign-in may not have finished."
        case .some(.paymentPendingError):
            message = "Your tip is waiting for App Store approval. No further action is needed here."
        case .some(.purchaseNotAllowedError):
            message = "The App Store isn’t allowing purchases on this device. Check your App Store purchase restrictions."
        case .some(.networkError):
            message = "Your tip couldn’t be confirmed because of a connection problem. Check the App Store result before trying again."
        case .some(.storeProblemError):
            message = "Apple couldn’t finish the purchase. If its sign-in popup keeps returning, close it and check your App Store sign-in before trying again."
        default:
            message = "Your tip couldn’t be confirmed. Check the App Store result before trying again."
        }
        let safeDomains: Set<String> = [Self.purchaseErrorDomain, "SKErrorDomain", "StoreKit.StoreKitError",
                                        "ASDErrorDomain", "AMSErrorDomain", "NSURLErrorDomain", "NSCocoaErrorDomain"]
        var chain: [String] = []
        var current: NSError? = failure
        for _ in 0..<5 {
            guard let item = current else { break }
            let domain = safeDomains.contains(item.domain) ? item.domain : "OtherError"
            chain.append("\(domain):\(item.code)")
            current = item.userInfo[NSUnderlyingErrorKey] as? NSError
        }
        diagnostic = chain.joined(separator: " → ")
    }
}

/// Consumable purchases are a thank-you, never a feature entitlement.
@MainActor
final class TipJarStore: ObservableObject {
    @Published private(set) var products: [StoreProduct] = []
    @Published private(set) var isLoading = false
    @Published private(set) var purchasingID: String?
    @Published private(set) var message: String?
    @Published private(set) var hasTipped = false
    @Published private(set) var celebrationID = 0
    @Published private(set) var purchaseDiagnostic: String?
    @Published private(set) var hasSupportedDevelopment: Bool
    private let preferences: UserDefaults
    private static let supportKey = "nativeTips.hasSupportedDevelopment.v1"

    init(preferences: UserDefaults = .standard) {
        self.preferences = preferences
        hasSupportedDevelopment = preferences.bool(forKey: Self.supportKey)
        #if DEBUG && targetEnvironment(simulator)
        // UI previews only; never manufacture or record a StoreKit transaction.
        if let preview = ProcessInfo.processInfo.environment["PROTOMOTA_TEST_TIP_STATE"] {
            hasSupportedDevelopment = preview == "current" || preview == "previous"
            hasTipped = preview == "current"
            celebrationID = preview == "current" ? 1 : 0
        }
        #endif
    }

    private static var configuredKey: String?

    func load(productIDs: [String]) async {
        guard !isLoading, purchasingID == nil else { return }
        isLoading = true
        message = nil
        defer { isLoading = false }
        guard let key = Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String,
              key.hasPrefix("appl_"), !key.contains("$(") else {
            products = []
            message = "Tips aren’t available right now. Please try again later."
            return
        }
        if !Purchases.isConfigured {
            // Earlier editions used accounts. Keep their cached identities out of optional tips.
            let suiteName = (Bundle.main.bundleIdentifier ?? "com.protomota") + ".nativeTips.v1"
            guard let tipPreferences = UserDefaults(suiteName: suiteName) else {
                message = "Tips aren’t available right now. Please try again later."
                return
            }
            Purchases.logLevel = .error
            Purchases.configure(with: Configuration.Builder(withAPIKey: key)
                .with(userDefaults: tipPreferences)
                .with(storeKitVersion: .storeKit2)
                .with(automaticDeviceIdentifierCollectionEnabled: false)
                .with(diagnosticsEnabled: false))
            Self.configuredKey = key
        }
        guard Self.configuredKey == key else {
            products = []
            message = "Tips aren’t available right now. Please try again later."
            return
        }
        let fetched = await Purchases.shared.products(productIDs)
        guard !Task.isCancelled else { return }
        // Only the expected consumables can appear, in the intended tier order.
        products = productIDs.compactMap { id in
            fetched.first { $0.productIdentifier == id && $0.productType == .consumable }
        }
        if products.isEmpty {
            message = "Tips aren’t available right now. Please try again later."
        }
    }

    func purchase(_ product: StoreProduct) async {
        guard purchasingID == nil, products.contains(where: { $0.productIdentifier == product.productIdentifier }) else { return }
        purchasingID = product.productIdentifier
        message = nil
        purchaseDiagnostic = nil
        defer { purchasingID = nil }
        do {
            let result = try await Purchases.shared.purchase(product: product)
            guard !result.userCancelled else {
                let cancelled = TipPurchaseFailure(ErrorCode.purchaseCancelledError)
                message = cancelled.message
                purchaseDiagnostic = cancelled.diagnostic
                return
            }
            guard result.transaction != nil else {
                message = "Your tip is still being confirmed by the App Store."
                return
            }
            hasTipped = true
            celebrationID += 1
            hasSupportedDevelopment = true
            preferences.set(true, forKey: Self.supportKey)
            message = nil
        } catch {
            let failure = TipPurchaseFailure(error)
            message = failure.message
            purchaseDiagnostic = failure.diagnostic
        }
    }
}

struct TipJarView: View {
    let appName: String
    let productPrefix: String
    let privacyURL: URL
    private let accent = Color(red: 0.95, green: 0.68, blue: 0.55)
    var onTipCompleted: () -> Void = {}
    @StateObject private var store = TipJarStore()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var celebrating = false
    @State private var celebratedID = 0

    private var productIDs: [String] {
        ["small", "medium", "large"].map { productPrefix + "." + $0 }
    }

    private var isDark: Bool { colorScheme == .dark }
    private var pageColor: Color { isDark ? Color(white: 0.075) : Color(white: 0.965) }
    private var surfaceColor: Color { isDark ? Color(white: 0.135) : .white }
    private var borderColor: Color { isDark ? Color(white: 0.26) : Color(white: 0.85) }
    private var primaryText: Color { isDark ? Color(white: 0.96) : Color(white: 0.08) }
    private var secondaryText: Color { isDark ? Color(white: 0.73) : Color(white: 0.36) }
    private var accentForeground: Color { .black }
    private var showsCurrentSuccess: Bool {
        store.hasTipped && store.purchasingID == nil && store.message == nil
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("Support \(appName)")
                .font(.headline)
                .foregroundStyle(primaryText)
            Spacer(minLength: 12)
            Button("Done") { dismiss() }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(primaryText)
                .padding(.horizontal, 18)
                .frame(minHeight: 44)
                .background(surfaceColor, in: Capsule())
                .overlay(Capsule().strokeBorder(borderColor, lineWidth: 1))
                .buttonStyle(.plain)
                .disabled(store.purchasingID != nil)
                .accessibilityIdentifier("tipJarDone")
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: "heart.fill")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(accent)
                .frame(width: 58, height: 58)
                .background(surfaceColor, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(borderColor))
                .accessibilityHidden(true)
            Text("Keep \(appName) growing.")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(primaryText)
                .fixedSize(horizontal: false, vertical: true)
            Text("All features are free. If you’d like to support future updates, you can make a one-time contribution.")
                .font(.body)
                .foregroundStyle(secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }

    private var successConfirmation: some View {
        VStack(spacing: 16) {
            SupporterBadgeArtwork().frame(width: 104, height: 104)
            VStack(spacing: 8) {
                Label(showsCurrentSuccess ? "Tip completed" : "Thank you for your support", systemImage: "checkmark.circle.fill")
                    .font(.title2.bold())
                    .foregroundStyle(primaryText)
                    .accessibilityIdentifier("tipJarSuccessTitle")
                Text(showsCurrentSuccess
                     ? "Thank you for supporting development. You’re all set—no further action is needed."
                     : "Your previous tip was received. You can leave another tip whenever you’d like.")
                    .font(.body)
                    .foregroundStyle(secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("tipJarSuccessDetail")
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(surfaceColor, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(borderColor))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("tipJarSuccess")
    }

    private func tipOption(_ product: StoreProduct) -> some View {
        Button {
            Task { await store.purchase(product) }
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(product.localizedTitle)
                        .font(.headline)
                        .foregroundStyle(primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("One-time contribution")
                        .font(.subheadline)
                        .foregroundStyle(secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Group {
                    if store.purchasingID == product.productIdentifier {
                        ProgressView().tint(accentForeground)
                            .frame(minWidth: 60)
                    } else {
                        Text(product.localizedPriceString)
                            .font(.headline.weight(.bold))
                            .monospacedDigit()
                            .fixedSize()
                    }
                }
                .foregroundStyle(accentForeground)
                .padding(.horizontal, 17)
                .frame(minHeight: 44)
                .background(accent, in: Capsule())
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, minHeight: 82)
            .background(surfaceColor, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(borderColor))
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .disabled(store.purchasingID != nil)
        .opacity(store.purchasingID == nil || store.purchasingID == product.productIdentifier ? 1 : 0.55)
        .accessibilityLabel("\(product.localizedTitle), \(product.localizedPriceString), one-time contribution")
        .accessibilityHint("Opens the App Store purchase confirmation.")
        .accessibilityIdentifier("tipJarProduct-" + product.productIdentifier)
    }

    private var purchaseStatus: some View {
        Group {
            if let message = store.message {
                VStack(alignment: .leading, spacing: 12) {
                    Text(message)
                        .font(.callout)
                        .foregroundStyle(primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("tipJarStatus")
                    if let diagnostic = store.purchaseDiagnostic {
                        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
                        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
                        ShareLink(item: "\(appName) \(version) (\(build)) purchase: \(diagnostic)") {
                            Label("Share purchase diagnostic", systemImage: "square.and.arrow.up")
                        }
                        .font(.footnote)
                        .foregroundStyle(primaryText)
                        .accessibilityIdentifier("tipJarShareDiagnostic")
                    }
                    if store.products.isEmpty && !store.isLoading {
                        Button("Try Again") { Task { await store.load(productIDs: productIDs) } }
                            .buttonStyle(.bordered)
                            .foregroundStyle(primaryText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(surfaceColor, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(borderColor))
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Secure purchase through the App Store", systemImage: "lock.shield")
                .font(.footnote.weight(.medium))
            Text("Each contribution is a separate purchase, with no subscription or feature unlock.")
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 22) {
                Link("Privacy policy", destination: privacyURL)
                Link("Terms of use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            }
            .font(.footnote.weight(.medium))
            .foregroundStyle(primaryText)
        }
        .foregroundStyle(secondaryText)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    var body: some View {
        VStack(spacing: 0) {
            header.padding(.horizontal, 24).padding(.top, 16).padding(.bottom, 12)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if store.hasSupportedDevelopment {
                        successConfirmation
                        Text("Leave another tip (optional)")
                            .font(.headline)
                            .foregroundStyle(primaryText)
                    } else {
                        introduction
                    }
                    VStack(spacing: 12) {
                        if store.isLoading {
                            ProgressView("Loading tips…")
                                .foregroundStyle(secondaryText)
                                .frame(maxWidth: .infinity, minHeight: 82)
                        }
                        ForEach(store.products, id: \.productIdentifier) { product in
                            tipOption(product)
                        }
                    }
                    purchaseStatus
                    Divider().overlay(borderColor)
                    footer
                }
                .frame(maxWidth: 540, alignment: .leading)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .accessibilityIdentifier("tipJarContent")
        }
        #if os(iOS)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #else
        .frame(minWidth: 400, idealWidth: 520, maxWidth: 640)
        .frame(minHeight: 540, idealHeight: 760, maxHeight: 900)
        #endif
        .foregroundStyle(primaryText)
        .background(pageColor.ignoresSafeArea())
        .tint(accent)

        .overlay {
            if celebrating && !reduceMotion { SupporterConfetti(accent: accent) }
        }
        .onChange(of: store.celebrationID, initial: true) { _, value in
            guard value > celebratedID else { return }
            celebratedID = value
            celebrating = !reduceMotion
        }
        .onChange(of: reduceMotion) { _, value in
            if value { celebrating = false }
        }
        .task(id: celebratedID) {
            guard celebratedID > 0 else { return }
            try? await Task.sleep(for: .seconds(4.6))
            guard !Task.isCancelled else { return }
            celebrating = false
        }
        .interactiveDismissDisabled(store.purchasingID != nil)
        .task { await store.load(productIDs: productIDs) }
        .onDisappear { if store.hasTipped { onTipCompleted() } }
    }
}

/// Keep presentation local so cancelling never records a completed tip.
struct NativeTipButton<Label: View>: View {
    let appName: String
    let productPrefix: String
    let privacyURL: URL
    let onTipCompleted: () -> Void
    let label: Label
    @State private var isPresented = false

    init(appName: String, productPrefix: String, privacyURL: URL,
         onTipCompleted: @escaping () -> Void = {}, @ViewBuilder label: () -> Label) {
        self.appName = appName
        self.productPrefix = productPrefix
        self.privacyURL = privacyURL
        self.onTipCompleted = onTipCompleted
        self.label = label()
    }

    var body: some View {
        Button { isPresented = true } label: { label }
            #if os(iOS)
            .fullScreenCover(isPresented: $isPresented) {
                TipJarView(appName: appName, productPrefix: productPrefix,
                           privacyURL: privacyURL, onTipCompleted: onTipCompleted)
            }
            #else
            .sheet(isPresented: $isPresented) {
                TipJarView(appName: appName, productPrefix: productPrefix,
                           privacyURL: privacyURL, onTipCompleted: onTipCompleted)
            }
            #endif
    }
}

struct PulseCanvasTipButton<Label: View>: View {
    let onTipCompleted: () -> Void
    let label: Label
    init(onTipCompleted: @escaping () -> Void = {}, @ViewBuilder label: () -> Label) {
        self.onTipCompleted = onTipCompleted
        self.label = label()
    }
    var body: some View {
        NativeTipButton(appName: "PulseCanvas", productPrefix: "com.protomota.pulsecanvas.tip",
                        privacyURL: URL(string: "https://pulsecanvas.si/privacy/")!,
                        onTipCompleted: onTipCompleted) { label }
    }
}


/// Local acknowledgement of a completed consumable, independent of action checkmarks.
struct SupporterAcknowledgement: View {
    @AppStorage("nativeTips.hasSupportedDevelopment.v1") private var hasSupported = false
    private var visible: Bool {
        #if DEBUG && targetEnvironment(simulator)
        if let state = ProcessInfo.processInfo.environment["PROTOMOTA_TEST_TIP_STATE"] {
            return state == "current" || state == "previous"
        }
        #endif
        return hasSupported
    }
    var body: some View {
        if visible {
            HStack(spacing: 14) {
                SupporterBadgeArtwork().frame(width: 76, height: 76)
                VStack(alignment: .leading, spacing: 5) {
                    Text("PulseCanvas Supporter").font(.headline)
                    Text("Thank you for supporting development.")
                        .font(.callout).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 6)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("settingsSupporterBadge")
        }
    }
}

private struct SupporterBadgeArtwork: View {
    private var badgeImage: Image {
        #if os(macOS)
        if let url = Bundle.module.url(forResource: "SupporterBadge", withExtension: "png", subdirectory: "Resources"),
           let image = NSImage(contentsOf: url) { return Image(nsImage: image) }
        return Image(systemName: "heart.circle.fill")
        #else
        return Image("SupporterBadge")
        #endif
    }
    var body: some View {
        badgeImage
            .resizable().interpolation(.high).scaledToFit()
            .accessibilityLabel("PulseCanvas supporter badge")
            .accessibilityIdentifier("supporterBadgeArtwork")
    }
}

/// Two celebratory fountain bursts, with tumbling confetti and brief glitter flares.
/// Decoration never intercepts Done or any purchase control.
private struct SupporterConfetti: View {
    let accent: Color
    @State private var started = Date()
    private let duration = 4.6

    private func variation(_ index: Int, _ channel: Int) -> Double {
        let value = sin(Double(index * 73 + channel * 193) * 12.9898) * 43758.5453
        return value - floor(value)
    }

    private func sparklePath(radius: Double) -> Path {
        var path = Path()
        for point in 0..<8 {
            let angle = Double(point) * .pi / 4 - .pi / 2
            let distance = point.isMultiple(of: 2) ? radius : radius * 0.22
            let position = CGPoint(x: cos(angle) * distance, y: sin(angle) * distance)
            if point == 0 { path.move(to: position) } else { path.addLine(to: position) }
        }
        path.closeSubpath()
        return path
    }

    private func drawConfetti(_ context: GraphicsContext, size: CGSize, elapsed: Double) {
        let colors: [Color] = [accent, .white, accent.opacity(0.65), Color(red: 1, green: 0.83, blue: 0.49)]
        for index in 0..<150 {
            let delay = variation(index, 1) * 0.32 + (index > 95 ? 0.3 : 0)
            let age = elapsed - delay
            let lifetime = 2.6 + variation(index, 2) * 1.4
            guard age >= 0, age < lifetime else { continue }
            let direction = index.isMultiple(of: 2) ? 1.0 : -1.0
            let originX = direction > 0 ? size.width * 0.03 : size.width * 0.97
            let originY = size.height * (0.84 + variation(index, 3) * 0.12)
            let horizontalSpeed = size.width * (0.4 + variation(index, 4) * 0.65)
            let verticalSpeed = size.height * (0.68 + variation(index, 5) * 0.72)
            let gravity = size.height * (0.84 + variation(index, 6) * 0.2)
            let travel = (1 - exp(-0.38 * age)) / 0.38
            let flutter = sin(age * (5 + variation(index, 7) * 6) + Double(index)) * 15 * min(age, 1)
            let x = originX + direction * horizontalSpeed * travel + flutter
            let y = originY - verticalSpeed * age + 0.5 * gravity * age * age
            let fadeIn = min(1, age * 14)
            let fadeOut = min(1, (lifetime - age) * 2.6)
            let width = 4 + variation(index, 8) * 6
            let height = 7 + variation(index, 9) * 9
            var particle = context
            particle.opacity = fadeIn * fadeOut
            particle.translateBy(x: x, y: y)
            particle.rotate(by: .radians(Double(index) + direction * age * (3 + variation(index, 10) * 8)))
            // Changing face width gives each piece its own tumble in depth.
            particle.scaleBy(x: 0.18 + abs(cos(age * (5 + variation(index, 11) * 7) + Double(index))) * 0.82, y: 1)
            let rect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
            let path = index.isMultiple(of: 7) ? Path(ellipseIn: rect) : Path(roundedRect: rect, cornerRadius: 1.5)
            particle.fill(path, with: .color(colors[index % colors.count]))
        }
    }

    private func drawGlitter(_ context: GraphicsContext, size: CGSize, elapsed: Double) {
        for index in 0..<38 {
            let delay = 0.25 + variation(index, 12) * 2.3
            let age = elapsed - delay
            let lifetime = 0.4 + variation(index, 13) * 0.6
            guard age >= 0, age < lifetime else { continue }
            let progress = age / lifetime
            let shimmer = sin(progress * .pi)
            let x = size.width * (0.06 + variation(index, 14) * 0.88)
            let y = size.height * (0.12 + variation(index, 15) * 0.76) - age * 15
            let radius = (5 + variation(index, 16) * 9) * shimmer
            var sparkle = context
            sparkle.translateBy(x: x, y: y)
            sparkle.rotate(by: .radians(progress * 0.45))
            var glow = sparkle
            glow.opacity = shimmer * 0.32
            glow.addFilter(.blur(radius: 5))
            glow.fill(sparklePath(radius: radius * 1.6), with: .color(accent))
            sparkle.opacity = shimmer * 0.9
            sparkle.fill(sparklePath(radius: radius), with: .color(index.isMultiple(of: 3) ? accent : .white))
        }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(started)
                guard elapsed >= 0, elapsed < duration else { return }
                drawConfetti(context, size: size, elapsed: elapsed)
                drawGlitter(context, size: size, elapsed: elapsed)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#endif
