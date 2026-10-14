import SwiftUI

// MARK: - Island Root View
struct IslandRootView: View {
    @EnvironmentObject var vm: IslandViewModel
    @State private var isHovered = false

    // Computed corner radius based on state
    private var cornerRadius: CGFloat {
        switch vm.islandState {
        case .closed:   return 14
        case .compact:  return 22
        case .expanded, .dragging: return 26
        }
    }

    var body: some View {
        Group {
            if vm.islandState == .compact && vm.islandStyle == .splitDual {
                DualSplitIslandView()
                    .environmentObject(vm)
            } else {
                LiquidGlassShell(cornerRadius: cornerRadius) {
                    Group {
                        switch vm.islandState {
                        case .closed:
                            ClosedIslandView()
                        case .compact:
                            CompactIslandView()
                                .environmentObject(vm)
                        case .expanded, .dragging:
                            ExpandedIslandView()
                                .environmentObject(vm)
                        }
                    }
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.islandState)
                }
            }
        }
        .scaleEffect(isHovered && vm.islandState == .compact ? 1.02 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
        .padding(IslandPanel.shadowPadding)
        .opacity(vm.opacity)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            if vm.islandState == .compact || vm.islandState == .closed {
                vm.expand()
            }
        }
    }
}
