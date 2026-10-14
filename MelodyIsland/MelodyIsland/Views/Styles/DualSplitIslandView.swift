import SwiftUI

// MARK: - Versi 2: Dual Split Island (Pill + Detached Bubble as in Screenshot)
struct DualSplitIslandView: View {
    @EnvironmentObject var vm: IslandViewModel
    private var track: Track? { vm.currentTrack }

    var body: some View {
        HStack(spacing: 8) {
            // Main Pill: Album Art + Live Lyric Line
            HStack(spacing: 11) {
                AlbumArtView(image: track?.albumArt, size: 28, cornerRadius: 7)

                ZStack(alignment: .leading) {
                    Text(vm.currentLyricText)
                        .font(.system(size: 13, weight: vm.hasActiveMusic ? .medium : .regular, design: .rounded))
                        .foregroundStyle(vm.hasActiveMusic ? vm.islandTextColor : vm.islandSecondaryTextColor)
                        .lineLimit(1)
                        .id(vm.currentLyricDisplayKey)
                        .transition(
                            .asymmetric(
                                insertion: .opacity
                                    .combined(with: .offset(y: 3))
                                    .combined(with: .scale(scale: 0.98, anchor: .leading)),
                                removal: .opacity
                                    .combined(with: .offset(y: -3))
                            )
                        )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .clipped()
                .animation(.spring(response: 0.38, dampingFraction: 0.88), value: vm.currentLyricDisplayKey)
            }
            .padding(.leading, 10)
            .padding(.trailing, 14)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(vm.islandGlassBackground)
                    .overlay(
                        Capsule().strokeBorder(vm.islandBorderGradient, lineWidth: 1)
                    )
            )
            .shadow(color: vm.islandShadowColor, radius: 10, x: 0, y: 3)

            // Detached Waveform Circle Bubble (flat when paused)
            WaveformBubbleView(
                isPlaying: track?.isPlaying ?? false,
                tintColor: vm.visualizerTheme.color
            )
        }
    }
}
