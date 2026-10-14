import SwiftUI
import AppKit

// MARK: - NSVisualEffectView Wrapper (Liquid Glass / HUD material)
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    var cornerRadius: CGFloat = 0
    var state: NSVisualEffectView.State = .active

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.wantsLayer = true
        view.layer?.cornerRadius = cornerRadius
        view.layer?.masksToBounds = true
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.layer?.cornerRadius = cornerRadius
        nsView.layer?.masksToBounds = true
    }
}

// MARK: - Liquid Glass Container (Island Shell)
struct LiquidGlassShell<Content: View>: View {
    @EnvironmentObject var vm: IslandViewModel
    let cornerRadius: CGFloat
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background {
                ZStack {
                    VisualEffectBlur(
                        material: vm.isEffectiveDarkMode ? .hudWindow : .popover,
                        blendingMode: .behindWindow,
                        cornerRadius: cornerRadius
                    )
                    vm.islandGlassBackground
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(vm.islandBorderGradient, lineWidth: 1)
            }
            .shadow(
                color: vm.islandShadowColor,
                radius: vm.isEffectiveDarkMode ? 14 : 10,
                x: 0,
                y: vm.isEffectiveDarkMode ? 5 : 3
            )
    }
}
