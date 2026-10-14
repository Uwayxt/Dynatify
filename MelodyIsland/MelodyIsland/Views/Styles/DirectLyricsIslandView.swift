import SwiftUI

// MARK: - Versi 1: Direct Synced Lyrics Stream (Screenshot Style)
struct DirectLyricsIslandView: View {
    @EnvironmentObject var vm: IslandViewModel
    private var track: Track? { vm.currentTrack }

    var body: some View {
        HStack(spacing: 12) {
            // Album Art
            AlbumArtView(image: track?.albumArt, size: 30, cornerRadius: 7)

            // Current Synced Lyric Text (Per-baris real time, anchored ZStack preventing width squish)
            ZStack(alignment: .leading) {
                Text(vm.currentLyricText)
                    .font(.system(size: 13, weight: vm.hasActiveMusic ? .medium : .regular, design: .rounded))
                    .foregroundStyle(vm.hasActiveMusic ? vm.islandTextColor : vm.islandSecondaryTextColor)
                    .lineLimit(1)
                    .id(vm.currentLyricDisplayKey)
                    .transition(
                        .asymmetric(
                            insertion: .opacity
                                .combined(with: .offset(y: 4))
                                .combined(with: .scale(scale: 0.98, anchor: .leading)),
                            removal: .opacity
                                .combined(with: .offset(y: -4))
                        )
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .clipped()
            .animation(.spring(response: 0.38, dampingFraction: 0.88), value: vm.currentLyricDisplayKey)

            // Waveform Audio Visualizer (flat when paused)
            AudioVisualizer(
                isPlaying: track?.isPlaying ?? false,
                tintColor: vm.visualizerTheme.color,
                barCount: 4
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
    }
}
