import SwiftUI

// MARK: - Versi 5: Karaoke Glow Bar
struct KaraokeTickerIslandView: View {
    @EnvironmentObject var vm: IslandViewModel
    private var track: Track? { vm.currentTrack }

    var body: some View {
        HStack(spacing: 12) {
            // Album Art with subtle glow
            AlbumArtView(image: track?.albumArt, size: 28, cornerRadius: 6)
                .shadow(color: vm.visualizerTheme.color.opacity(vm.hasActiveMusic ? 0.4 : 0), radius: 6, x: 0, y: 0)

            // Karaoke Glow Lyric
            VStack(alignment: .leading, spacing: 2) {
                ZStack(alignment: .leading) {
                    Text(vm.currentLyricText)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, vm.hasActiveMusic ? vm.visualizerTheme.color.opacity(0.9) : .white.opacity(0.5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineLimit(1)
                        .shadow(color: vm.hasActiveMusic ? vm.visualizerTheme.color.opacity(0.3) : .clear, radius: 4, x: 0, y: 0)
                        .id(vm.currentLyricDisplayKey)
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .offset(y: 3)),
                                removal: .opacity.combined(with: .offset(y: -3))
                            )
                        )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .clipped()
                .animation(.spring(response: 0.38, dampingFraction: 0.88), value: vm.currentLyricDisplayKey)

                if let next = vm.nextLyricText {
                    Text(next)
                        .font(.system(size: 10, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.35))
                        .lineLimit(1)
                        .id("next_\(vm.currentLyricDisplayKey)")
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.28), value: vm.currentLyricDisplayKey)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Waveform
            AudioVisualizer(
                isPlaying: track?.isPlaying ?? false,
                tintColor: vm.visualizerTheme.color,
                barCount: 4
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }
}
