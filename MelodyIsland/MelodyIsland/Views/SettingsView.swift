import SwiftUI

// MARK: - Master Settings & Customizer Window
struct SettingsView: View {
    @EnvironmentObject var vm: IslandViewModel
    @AppStorage("islandOpacity") private var storedOpacity: Double = 1.0
    @AppStorage("islandYOffset") private var yOffset: Double = 0.0
    @State private var selectedTab: SettingsTab = .appearance

    enum SettingsTab: String, CaseIterable, Identifiable {
        case appearance = "Tampilan"
        case playground = "Playground"
        case guide      = "Panduan"
        case about      = "Tentang"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .appearance: return "paintpalette.fill"
            case .playground: return "play.circle.fill"
            case .guide:      return "book.fill"
            case .about:      return "info.circle.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header Bar with credit
            headerBar

            Divider()

            // Main Tab Content
            TabView(selection: $selectedTab) {
                appearanceTab
                    .tag(SettingsTab.appearance)

                playgroundTab
                    .tag(SettingsTab.playground)

                GuideView()
                    .environmentObject(vm)
                    .tag(SettingsTab.guide)

                aboutTab
                    .tag(SettingsTab.about)
            }
            .tabViewStyle(.automatic)

            Divider()

            // Footer bar
            HStack {
                Text("MelodyIsland • by @uwayxt")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Selesai / Tutup") {
                    NSApp.keyWindow?.orderOut(nil)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .keyboardShortcut("w", modifiers: .command)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.02))
        }
        .frame(width: 550, height: 610)
        .onAppear {
            vm.opacity = storedOpacity
        }
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack {
            Image(systemName: "music.note.house.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: "#1DB954"))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("MelodyIsland")
                        .font(.headline)
                    Text("by @uwayxt")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: "#1DB954"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(hex: "#1DB954").opacity(0.12)))
                }
                Text("Dynamic Island & Synced Lyrics untuk macOS")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Custom Tab Segmented Control
            Picker("", selection: $selectedTab) {
                ForEach(SettingsTab.allCases) { tab in
                    Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 290)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color.primary.opacity(0.02))
    }

    // MARK: - 🎨 TAB 1: Appearance & Styles
    private var appearanceTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Live Screen Notch Preview
                notchPreviewCard

                // Lokasi Tampilan Lirik (Topbar / Island / Keduanya)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Lokasi Tampilan Lirik")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    HStack(spacing: 10) {
                        ForEach(DisplayLocationMode.allCases) { mode in
                            Button {
                                vm.setDisplayLocationMode(mode)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Image(systemName: mode.icon)
                                            .font(.system(size: 14))
                                            .foregroundStyle(vm.displayLocationMode == mode ? Color(hex: "#1DB954") : .secondary)
                                        Spacer()
                                        if vm.displayLocationMode == mode {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 12))
                                                .foregroundStyle(Color(hex: "#1DB954"))
                                        }
                                    }

                                    Text(mode.title)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.primary)

                                    Text(mode.subtitle)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(vm.displayLocationMode == mode ? Color(hex: "#1DB954").opacity(0.10) : Color.primary.opacity(0.03))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(vm.displayLocationMode == mode ? Color(hex: "#1DB954").opacity(0.4) : Color.clear, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.03)))

                // Style Version Picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Pilihan Versi Tampilan (Island Style)")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(IslandStyle.allCases) { style in
                        Button {
                            vm.setIslandStyle(style)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: vm.islandStyle == style ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 16))
                                    .foregroundStyle(vm.islandStyle == style ? Color(hex: "#1DB954") : .secondary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(style.displayName)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.primary)
                                    Text(style.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text("\(Int(style.defaultWidth))pt")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.primary.opacity(0.06)))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(vm.islandStyle == style ? Color(hex: "#1DB954").opacity(0.10) : Color.primary.opacity(0.03))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(vm.islandStyle == style ? Color(hex: "#1DB954").opacity(0.4) : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.03)))

                // Visualizer Color Theme
                VStack(alignment: .leading, spacing: 10) {
                    Text("Warna Waveform & Visualizer")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    HStack(spacing: 12) {
                        ForEach(VisualizerTheme.allCases) { theme in
                            Button {
                                vm.setVisualizerTheme(theme)
                            } label: {
                                VStack(spacing: 6) {
                                    Circle()
                                        .fill(theme.color)
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(Color.white, lineWidth: vm.visualizerTheme == theme ? 2 : 0)
                                        )
                                        .shadow(color: theme.color.opacity(0.5), radius: 4, x: 0, y: 2)

                                    Text(theme.title)
                                        .font(.caption2)
                                        .foregroundStyle(vm.visualizerTheme == theme ? .primary : .secondary)
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(vm.visualizerTheme == theme ? Color.primary.opacity(0.08) : Color.clear)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                // Lebar Dynamic Island (Compact Mode)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Lebar Dynamic Island (Mode Pil / Lirik)")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Toggle("Lebar Adaptif Otomatis (Mengikuti Panjang Lirik)", isOn: Binding(
                        get: { vm.isAdaptiveWidth },
                        set: { vm.setIsAdaptiveWidth($0) }
                    ))
                    .font(.system(size: 13))

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Batas Lebar Kustom: \(Int(vm.customCompactWidth)) pt")
                                .font(.caption)
                            Spacer()
                            Text("Lebar Aktif: \(Int(vm.currentCompactWidth)) pt")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: Binding(
                            get: { vm.customCompactWidth },
                            set: { vm.setCustomCompactWidth($0) }
                        ), in: 260...560, step: 10) {
                            Text("Lebar Pil")
                        }
                    }

                    Text(vm.isAdaptiveWidth ? "Island otomatis memanjang/memendek sesuai panjang 1 baris lirik yang sedang dinyanyikan secara real-time." : "Island menggunakan lebar tetap yang Anda atur.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.03)))

                // Dimension & Opacity Sliders
                VStack(alignment: .leading, spacing: 12) {
                    Text("Penyesuaian Posisi & Opacity")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Transparansi Island: \(Int(storedOpacity * 100))%")
                                .font(.caption)
                            Spacer()
                        }
                        Slider(value: $storedOpacity, in: 0.4...1.0, step: 0.05) {
                            Text("Opacity")
                        }
                        .onChange(of: storedOpacity) { _, newVal in
                            vm.opacity = newVal
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Jarak Nudge Notch (Y-Offset): \(Int(yOffset)) pt")
                                .font(.caption)
                            Spacer()
                        }
                        Slider(value: $yOffset, in: -10...40, step: 2) {
                            Text("Offset")
                        }
                        .onChange(of: yOffset) { _, _ in
                            if let panel = (NSApp.delegate as? AppDelegate)?.islandPanel {
                                panel.updateFrame(for: vm.islandState, style: vm.islandStyle, animated: true)
                            }
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.03)))
            }
            .padding(18)
        }
    }

    // Notch Live Preview Card
    private var notchPreviewCard: some View {
        VStack(spacing: 8) {
            Text("Pratinjau Langsung (Live Preview)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                // Mockup screen background
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "#1E1E24"))
                    .frame(height: 80)

                // Mockup Notch Simulator
                VStack {
                    Capsule()
                        .fill(Color.black)
                        .frame(width: 140, height: 14)
                        .offset(y: -4)
                    Spacer()
                }

                // Render current compact island style
                CompactIslandView()
                    .environmentObject(vm)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.92))
                            .overlay(
                                Capsule().strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                            )
                    )
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 4)
                    .offset(y: 4)
            }
        }
    }

    // MARK: - ⚡ TAB 2: Playground & Controls
    private var playgroundTab: some View {
        VStack(spacing: 20) {
            Text("Playground & Kontrol Pemutar")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Current Song Card
            HStack(spacing: 14) {
                AlbumArtView(image: vm.currentTrack?.albumArt, size: 54, cornerRadius: 10)

                VStack(alignment: .leading, spacing: 4) {
                    Text(vm.currentTrack?.title ?? "Tidak Ada Lagu")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.primary)

                    Text(vm.currentTrack?.artist ?? "—")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.secondary)

                    Text(vm.currentLyricText)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(vm.visualizerTheme.color)
                        .lineLimit(1)
                }

                Spacer()

                AudioVisualizer(
                    isPlaying: vm.currentTrack?.isPlaying ?? false,
                    tintColor: vm.visualizerTheme.color,
                    barCount: 5
                )
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.primary.opacity(0.04)))

            // Playback Actions
            HStack(spacing: 20) {
                Button {
                    vm.previousTrack()
                } label: {
                    Image(systemName: "backward.fill").font(.title3)
                }
                .buttonStyle(.bordered)

                Button {
                    vm.playPause()
                } label: {
                    Image(systemName: vm.currentTrack?.isPlaying == true ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#1DB954"))

                Button {
                    vm.nextTrack()
                } label: {
                    Image(systemName: "forward.fill").font(.title3)
                }
                .buttonStyle(.bordered)
            }

            // Quick State Morph Buttons
            HStack(spacing: 12) {
                Button {
                    vm.expand()
                } label: {
                    Label("Expand Island (Lirik)", systemImage: "arrow.up.left.and.arrow.down.right")
                }
                .buttonStyle(.bordered)

                Button {
                    vm.collapse()
                } label: {
                    Label("Collapse (Pill)", systemImage: "arrow.down.right.and.arrow.up.left")
                }
                .buttonStyle(.bordered)

                Button {
                    Task { await vm.fetchActivePlayerState() }
                } label: {
                    Label("Sync Pemutar Sekarang", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#1DB954"))
            }

            Spacer()
        }
        .padding(20)
    }

    // MARK: - ℹ️ TAB 4: About & Credits
    private var aboutTab: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: "#1DB954"), Color(hex: "#0E5E2A")], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 72, height: 72)
                Image(systemName: "music.note")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
            }
            .shadow(color: Color(hex: "#1DB954").opacity(0.4), radius: 12, x: 0, y: 6)

            VStack(spacing: 4) {
                Text("MelodyIsland (Dynatify)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Versi 1.1.0 • macOS Native")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 6) {
                Text("Designed & Built with ❤️")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    Text("Credit by:")
                        .font(.body)
                    Text("@uwayxt")
                        .font(.headline)
                        .foregroundStyle(Color(hex: "#1DB954"))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color(hex: "#1DB954").opacity(0.12)))
            }

            VStack(spacing: 6) {
                Text("Integrasi & Teknologi:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("• Lirik: LRCLIB (Open Source Synced Lyrics)")
                    .font(.caption)
                Text("• Pemutar: Spotify AppleScript & NSRunningApplication Engine")
                    .font(.caption)
                Text("• Antarmuka: SwiftUI + AppKit Glassmorphism HUD")
                    .font(.caption)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.04)))

            Spacer()
        }
        .padding(20)
    }
}
