import SwiftUI

/// Resolve a double tap before a presentation's single tap can hide its controls.
/// The same gesture also recognizes a mouse double click on macOS.
struct VisualizerFavoriteGesture: ViewModifier {
    let favorite: () -> Bool
    var singleTap: (() -> Void)? = nil
    @State private var confirmation = 0
    @State private var showsConfirmation = false

    func body(content: Content) -> some View {
        content.contentShape(Rectangle())
            .gesture(TapGesture(count: 2).exclusively(before: TapGesture(count: 1)).onEnded { value in
                switch value {
                case .first: saveFavorite()
                case .second: singleTap?()
                }
            })
            .overlay {
                if showsConfirmation {
                    Label("Visualizer favorited", systemImage: "heart.fill")
                        .font(.headline).padding(16)
                        .foregroundStyle(.white)
                        .background(.ultraThinMaterial, in: Capsule())
                        .allowsHitTesting(false)
                        .accessibilityIdentifier("visualizerFavoriteConfirmation")
                }
            }
            .accessibilityAction(named: Text("Favorite visualizer"), saveFavorite)
            .task(id: confirmation) {
                guard confirmation > 0 else { return }
                do { try await Task.sleep(for: .seconds(2)) } catch { return }
                showsConfirmation = false
            }
    }

    private func saveFavorite() {
        guard favorite() else { return }
        confirmation += 1
        showsConfirmation = true
        AccessibilityNotification.Announcement("Visualizer favorited").post()
    }
}
