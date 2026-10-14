import SwiftUI
import AppKit

// MARK: - Expanded Island (Full Synced Lyrics, Controls, Volume & Empty State)
struct ExpandedIslandView: View {
    @EnvironmentObject var vm: IslandViewModel
    private var track: Track? { vm.currentTrack }

    var body: some View {
        VStack(spacing: 0) {
            // Top collapse handle
            Button {
                vm.collapse()
            } label: {
                Capsule()
                    .fill(vm.islandSecondaryTextColor.opacity(0.35))
                    .frame(width: 40, height: 4.5)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            }
            .buttonStyle(.plain)
            .help("Klik untuk mengecilkan ke notch (Esc)")

            if vm.hasActiveMusic, let track = track {
                // ── Active Player View ────────────────────────
                headerSection(track: track)
                    .padding(.top, 6)
                    .padding(.horizontal, 18)

                lyricsSection
                    .padding(.top, 10)

                controlsSection(track: track)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 16)
            } else {
                // ── Empty State View ──────────────────────────
                emptyStateSection
                    .padding(24)
            }
        }
        .frame(width: 380)
    }

    // MARK: - Header
    private func headerSection(track: Track) -> some View {
        HStack(spacing: 12) {
            AlbumArtView(image: track.albumArt, size: 48, cornerRadius: 10)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(track.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(vm.islandTextColor)
                        .lineLimit(1)

                    // Source Badge (Spotify / Apple Music)
                    Text(track.playerSource.rawValue)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(track.playerSource == .spotify ? Color(hex: "#1DB954") : Color.pink)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(Capsule().fill(vm.islandSubtleFill))
                }

                Text(track.artist + (track.album.isEmpty ? "" : " • " + track.album))
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(vm.islandSecondaryTextColor)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 8) {
                AudioVisualizer(
                    isPlaying: track.isPlaying,
                    tintColor: vm.visualizerTheme.color,
                    barCount: 4
                )

                Button {
                    vm.collapse()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.up.circle.fill")
                            .font(.system(size: 14))
                        Text("Tutup")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(vm.islandTextColor.opacity(0.85))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(vm.islandSubtleFill))
                }
                .buttonStyle(.plain)
                .help("Kembali ke ukuran pil di notch (Esc)")
            }
        }
    }

    // MARK: - Lyrics
    private var lyricsSection: some View {
        ScrollViewReader { proxy in
            ZStack {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 4) {
                        Color.clear.frame(height: 60)

                        if vm.lyrics.isEmpty {
                            noLyricsPlaceholder
                        } else {
                            ForEach(Array(vm.lyrics.enumerated()), id: \.element.id) { idx, line in
                                LyricLine(
                                    line: line,
                                    isActive: idx == vm.activeLyricIndex,
                                    index: idx,
                                    activeIndex: vm.activeLyricIndex
                                )
                                .id(idx)
                                .onTapGesture {
                                    // Tap any lyric line to jump directly to that timestamp in song!
                                    vm.seek(to: line.timeSeconds / (vm.currentTrack?.durationSeconds ?? 1.0))
                                }
                            }
                        }

                        Color.clear.frame(height: 60)
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 190)
                // Gradient mask for smooth top & bottom fade
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.18),
                            .init(color: .black, location: 0.82),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .onChange(of: vm.activeLyricIndex) { _, newIndex in
                withAnimation(.smooth(duration: 0.35)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }

    private var noLyricsPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "music.note.list")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(vm.islandSecondaryTextColor.opacity(0.5))
            Text(vm.appLanguage == .english ? "Synced lyrics not available yet" : "Lirik tersinkronisasi belum tersedia")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(vm.islandSecondaryTextColor.opacity(0.7))
        }
        .frame(height: 120)
    }

    // MARK: - Controls & Scrubber & Volume
    private func controlsSection(track: Track) -> some View {
        VStack(spacing: 12) {
            // Time Scrubber
            HStack(spacing: 8) {
                TimeLabel(seconds: track.positionSeconds)
                    .environmentObject(vm)
                ProgressBar()
                    .environmentObject(vm)
                TimeLabel(seconds: track.durationSeconds)
                    .environmentObject(vm)
            }

            // Playback Buttons
            HStack(spacing: 28) {
                PlaybackControls()
                    .environmentObject(vm)
            }

            // Volume Slider
            HStack(spacing: 8) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(vm.islandSecondaryTextColor)

                VolumeSlider(value: Binding(
                    get: { track.volume },
                    set: { vm.setVolume(to: $0) }
                ))
                .environmentObject(vm)

                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(vm.islandSecondaryTextColor)
            }
            .padding(.top, 2)
        }
    }

    // MARK: - Empty State (No Music Playing)
    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(vm.islandSubtleFill)
                    .frame(width: 56, height: 56)
                Image(systemName: "music.note")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(vm.islandSecondaryTextColor)
            }

            VStack(spacing: 4) {
                Text(vm.appLanguage == .english ? "No Music Playing" : "Tidak Ada Musik yang Diputar")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(vm.islandTextColor)

                Text(vm.appLanguage == .english ? "Play a track on Spotify or Apple Music to see synced lyrics and live controls." : "Putar lagu di Spotify atau Apple Music untuk melihat kontrol dan lirik tersinkronisasi.")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(vm.islandSecondaryTextColor)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                Button {
                    NSWorkspace.shared.open(URL(string: "spotify:")!)
                } label: {
                    Label(vm.appLanguage == .english ? "Open Spotify" : "Buka Spotify", systemImage: "play.circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#1DB954"))

                Button {
                    NSWorkspace.shared.open(URL(string: "music:")!)
                } label: {
                    Label("Apple Music", systemImage: "music.note")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 4)

            Button {
                vm.collapse()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.up.circle.fill")
                        .font(.system(size: 13))
                    Text("Kecilkan ke Notch")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(vm.islandSecondaryTextColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(vm.islandSubtleFill))
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
    }
}

// MARK: - Custom Volume Slider
struct VolumeSlider: View {
    @EnvironmentObject var vm: IslandViewModel
    @Binding var value: Double
    @State private var isDragging = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(vm.islandSubtleFill)
                    .frame(height: 3.5)

                Capsule()
                    .fill(vm.islandTextColor.opacity(0.85))
                    .frame(width: max(0, min(geo.size.width * (value / 100.0), geo.size.width)), height: 3.5)
            }
            .frame(height: 14)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        let frac = max(0, min(val.location.x / geo.size.width, 1))
                        value = frac * 100.0
                    }
            )
        }
        .frame(height: 14)
    }
}
