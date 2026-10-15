import SwiftUI
import AppKit

extension View {
    /// Consume the outside click so closing a sheet never activates the editor.
    func dismissOnOutsideClick(_ dismiss: @escaping () -> Void) -> some View {
        background(SheetOutsideClickHandler(dismiss: dismiss).frame(width: 0, height: 0))
    }
}

private struct SheetOutsideClickHandler: NSViewRepresentable {
    let dismiss: () -> Void
    func makeNSView(context: Context) -> SheetClickView {
        let view = SheetClickView()
        view.dismiss = dismiss
        return view
    }
    func updateNSView(_ view: SheetClickView, context: Context) { view.dismiss = dismiss }
    static func dismantleNSView(_ view: SheetClickView, coordinator: ()) { view.stopMonitoring() }
}

private final class SheetClickView: NSView {
    var dismiss: (() -> Void)?
    private var monitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stopMonitoring()
        guard window != nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            let dismissed = MainActor.assumeIsolated {
                guard let self, let sheet = self.window, let parent = sheet.sheetParent,
                      sheet.attachedSheet == nil,
                      event.window === parent else { return false }
                self.dismiss?()
                return true
            }
            return dismissed ? nil : event
        }
    }

    func stopMonitoring() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}

/// Shared controls keep transport, project actions, and export visually related.
struct StudioButtonStyle: ButtonStyle {
    enum Treatment { case secondary, accent, primary, quiet }
    var treatment: Treatment = .secondary
    var compact = false
    var circular = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @State private var hovering = false
    private let peach = Color(red: 0.95, green: 0.68, blue: 0.55)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, circular ? 0 : (compact ? 11 : 16))
            .frame(width: circular ? 44 : nil, height: circular ? 44 : nil)
            .frame(minHeight: 44)
            .foregroundStyle(treatment == .primary ? Color(red: 0.22, green: 0.13, blue: 0.15) : .white.opacity(0.92))
            .background(fill(pressed: configuration.isPressed), in: RoundedRectangle(cornerRadius: circular ? 22 : 11))
            .overlay(RoundedRectangle(cornerRadius: circular ? 22 : 11).strokeBorder(border, lineWidth: isFocused ? 2 : 1))
            .opacity(isEnabled ? 1 : 0.4)
            .contentShape(RoundedRectangle(cornerRadius: circular ? 22 : 11))
            .onHover { hovering = $0 }
    }

    private func fill(pressed: Bool) -> Color {
        if treatment == .primary { return peach.opacity(pressed ? 0.7 : (hovering && isEnabled ? 1 : 0.92)) }
        if pressed { return peach.opacity(0.23) }
        if hovering && isEnabled { return Color.white.opacity(treatment == .quiet ? 0.09 : 0.13) }
        switch treatment {
        case .accent: return peach.opacity(0.14)
        case .quiet: return .clear
        default: return Color.white.opacity(0.055)
        }
    }

    private var border: Color {
        if isFocused { return peach }
        if treatment == .primary { return peach }
        if treatment == .accent { return peach.opacity(hovering ? 0.65 : 0.38) }
        return Color.white.opacity(hovering && isEnabled ? 0.25 : (treatment == .quiet ? 0 : 0.13))
    }
}

/// A 44-point hit area includes both the label and a clearly visible switch.
struct StudioSwitchStyle: ToggleStyle {
    var icon: String? = nil
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    private let peach = Color(red: 0.95, green: 0.68, blue: 0.55)

    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(spacing: 9) {
                if let icon { Image(systemName: icon).foregroundStyle(configuration.isOn ? peach : .white.opacity(0.55)) }
                configuration.label.font(.system(size: 12, weight: .medium))
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    Capsule().fill(configuration.isOn ? peach : Color.white.opacity(0.15))
                    Capsule().strokeBorder(configuration.isOn ? peach : Color.white.opacity(0.22), lineWidth: 1)
                    Circle().fill(configuration.isOn ? Color(red: 0.23, green: 0.14, blue: 0.16) : .white.opacity(0.85))
                        .frame(width: 22, height: 22).padding(3)
                }.frame(width: 48, height: 28)
            }.padding(.horizontal, 10).frame(minHeight: 44)
                .background(configuration.isOn ? peach.opacity(0.08) : Color.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 9))
                .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(isFocused ? peach : .white.opacity(configuration.isOn ? 0.13 : 0.07), lineWidth: isFocused ? 2 : 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.4)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }.toggleStyle(.switch)
        }
    }
}

/// Equal-width mode tabs share a visible track and one selected indicator.
struct StudioTabStyle: ButtonStyle {
    let selected: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @State private var hovering = false
    private let peach = Color(red: 0.95, green: 0.68, blue: 0.55)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .frame(maxWidth: .infinity).frame(height: 44)
            .foregroundStyle(selected ? peach : .white.opacity(0.8))
            .background(selected ? peach.opacity(configuration.isPressed ? 0.25 : 0.16) : .white.opacity(hovering || configuration.isPressed ? 0.09 : 0.035), in: RoundedRectangle(cornerRadius: 6))
            .overlay(alignment: .leading) {
                Capsule().fill(peach).frame(width: 3, height: 20).padding(.leading, 4).opacity(selected ? 1 : 0)
            }
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(isFocused ? peach : .clear, lineWidth: 2))
            .contentShape(Rectangle())
            .opacity(isEnabled ? 1 : 0.4)
            .accessibilityAddTraits(selected ? .isSelected : [])
            .onHover { hovering = $0 }
    }
}
