import SwiftUI
import AppKit

// MARK: - Master Compact Island Router (Dispatches to selected style)
struct CompactIslandView: View {
    @EnvironmentObject var vm: IslandViewModel
    private var track: Track? { vm.currentTrack }

    var body: some View {
        Group {
            switch vm.islandStyle {
            case .directLyrics:
                DirectLyricsIslandView()
            case .splitDual:
                DualSplitIslandView()
            case .classic:
                classicLayout
            case .compactMinimal:
                minimalLayout
            case .karaokeTicker:
                KaraokeTickerIslandView()
            }
        }
    }

    // MARK: - Versi 3: Classic Layout (Cover + Title + Artist + Visualizer)
    private var classicLayout: some View {
        HStack(spacing: 10) {
            AlbumArtView(image: track?.albumArt, size: 30, cornerRadius: 6)

            VStack(alignment: .leading, spacing: 1) {
                Text(track?.title ?? (vm.appLanguage == .english ? "No music playing" : "Tidak ada musik"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(vm.hasActiveMusic ? vm.islandTextColor : vm.islandSecondaryTextColor)
                    .lineLimit(1)

                Text(track?.artist ?? (vm.appLanguage == .english ? "Open Spotify / Apple Music" : "Buka Spotify / Apple Music"))
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(vm.islandSecondaryTextColor.opacity(0.8))
                    .lineLimit(1)
            }
            .frame(maxWidth: 130, alignment: .leading)

            AudioVisualizer(
                isPlaying: track?.isPlaying ?? false,
                tintColor: vm.visualizerTheme.color,
                barCount: 3
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
    }

    // MARK: - Versi 4: Ultra Minimalist Pill
    private var minimalLayout: some View {
        HStack(spacing: 8) {
            AlbumArtView(image: track?.albumArt, size: 22, cornerRadius: 5)

            Text(track?.title ?? "Dynatify")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(vm.hasActiveMusic ? vm.islandTextColor : vm.islandSecondaryTextColor)
                .lineLimit(1)

            Circle()
                .fill(vm.visualizerTheme.color)
                .frame(width: 5, height: 5)
                .opacity(track?.isPlaying == true ? 1.0 : 0.25)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
    }
}

// MARK: - Reusable Album Art View
struct AlbumArtView: View {
    let image: NSImage?
    let size: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        Group {
            if let img = image {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
            } else {
                ZStack {
                    Color(hex: "#1A1A1A")
                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.38, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
