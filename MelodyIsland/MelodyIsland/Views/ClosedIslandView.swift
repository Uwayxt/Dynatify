import SwiftUI

// MARK: - Closed Island (Subtle Notch Dot)
struct ClosedIslandView: View {
    @EnvironmentObject var vm: IslandViewModel
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(vm.hasActiveMusic ? vm.visualizerTheme.color : Color.white.opacity(0.3))
                .frame(width: 6, height: 6)
                .scaleEffect((pulse && vm.currentTrack?.isPlaying == true) ? 1.3 : 0.85)
                .opacity((pulse && vm.currentTrack?.isPlaying == true) ? 1 : 0.6)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 0.9).repeatForever(autoreverses: true)
            ) {
                pulse = true
            }
        }
    }
}
