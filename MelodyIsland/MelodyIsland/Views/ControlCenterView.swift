import SwiftUI
import AppKit

// MARK: - Pillar A: The Main App Window (Control Center Dashboard)
/// Designed specifically for Dynatify • by @uwayxt
struct ControlCenterView: View {
    @EnvironmentObject var vm: IslandViewModel
    @State private var selectedTab: ControlCenterTab = .general
    @State private var connectionMessage: String?
    @State private var isTestingConnection = false
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = true
    @AppStorage("islandOpacity") private var storedOpacity: Double = 1.0

    enum ControlCenterTab: String, CaseIterable, Identifiable {
        case general    = "General"
        case appearance = "Appearance"
        case lyrics     = "Lyrics"
        case shortcuts  = "Shortcuts"

        var id: String { rawValue }

        func title(for lang: AppLanguage) -> String {
            switch (self, lang) {
            case (.general, .english):    return "General"
            case (.general, .indonesian): return "Umum"
            case (.appearance, .english):    return "Appearance"
            case (.appearance, .indonesian): return "Tampilan"
            case (.lyrics, .english):    return "Lyrics"
            case (.lyrics, .indonesian): return "Lirik"
            case (.shortcuts, .english):    return "Shortcuts"
            case (.shortcuts, .indonesian): return "Pintasan"
            }
        }

        var icon: String {
            switch self {
            case .general:    return "gearshape.fill"
            case .appearance: return "paintbrush.fill"
            case .lyrics:     return "music.mic"
            case .shortcuts:  return "keyboard.fill"
            }
        }
    }

    private func tr(_ en: String, _ id: String) -> String {
        vm.appLanguage == .english ? en : id
    }

    var body: some View {
        VStack(spacing: 0) {
            // Master Hero Card (Status Besar & Quick Switch)
            heroHeaderView

            Divider()

            // 4 Tabs Dashboard
            TabView(selection: $selectedTab) {
                generalTabView
                    .tag(ControlCenterTab.general)
                    .tabItem {
                        Label(ControlCenterTab.general.title(for: vm.appLanguage), systemImage: "gearshape")
                    }

                appearanceTabView
                    .tag(ControlCenterTab.appearance)
                    .tabItem {
                        Label(ControlCenterTab.appearance.title(for: vm.appLanguage), systemImage: "paintbrush")
                    }

                lyricsTabView
                    .tag(ControlCenterTab.lyrics)
                    .tabItem {
                        Label(ControlCenterTab.lyrics.title(for: vm.appLanguage), systemImage: "music.mic")
                    }

                shortcutsTabView
                    .tag(ControlCenterTab.shortcuts)
                    .tabItem {
                        Label(ControlCenterTab.shortcuts.title(for: vm.appLanguage), systemImage: "keyboard")
                    }
            }
            .tabViewStyle(.automatic)
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Spacer(minLength: 8)

            Divider()

            // Footer Bar
            footerBarView
        }
        .frame(width: 580, height: 650)
        .background(
            VisualEffectBackground(material: .underWindowBackground, blendingMode: .behindWindow)
        )
    }

    // MARK: - Hero Header (Status Besar & Master Toggle)
    private var heroHeaderView: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                // App Logo / Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#0E1816"), Color(hex: "#4A7E74")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 54, height: 54)
                        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)

                    // Frosted pill inside logo
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 38, height: 18)
                        .overlay(
                            HStack(spacing: 3) {
                                Capsule().fill(Color(hex: "#1DB954")).frame(width: 4, height: 8)
                                Capsule().fill(Color(hex: "#1DB954")).frame(width: 4, height: 14)
                                Capsule().fill(Color(hex: "#1DB954")).frame(width: 4, height: 10)
                            }
                        )
                }

                // Title & Tagline
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text("Dynatify")
                            .font(.system(size: 20, weight: .bold, design: .rounded))

                        Text("by @uwayxt")
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(hex: "#1DB954"))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(
                                Capsule().fill(Color(hex: "#1DB954").opacity(0.15))
                            )
                    }

                    Text(tr("A silent companion for your deep work • macOS 27 Native", "Teman hening untuk deep work Anda • macOS 27 Native"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Master Toggle Switch
                VStack(alignment: .trailing, spacing: 3) {
                    Toggle("", isOn: Binding(
                        get: { vm.isIslandActive },
                        set: { vm.setIslandActive($0) }
                    ))
                    .toggleStyle(.switch)
                    .tint(Color(hex: "#1DB954"))
                    .labelsHidden()

                    Text(vm.isIslandActive ? tr("ACTIVE", "AKTIF") : tr("INACTIVE", "NONAKTIF"))
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(vm.isIslandActive ? Color(hex: "#1DB954") : Color.secondary)
                }
            }

            // Big Status Capsule Banner
            HStack(spacing: 10) {
                Circle()
                    .fill(vm.isIslandActive ? Color(hex: "#1DB954") : Color.gray)
                    .frame(width: 9, height: 9)
                    .shadow(color: vm.isIslandActive ? Color(hex: "#1DB954").opacity(0.8) : Color.clear, radius: 4)

                Text(vm.isIslandActive ? tr("Dynatify is Active", "Dynatify Aktif") : tr("Dynatify is Inactive", "Dynatify Nonaktif"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(vm.isIslandActive ? Color.primary : Color.secondary)

                Spacer()

                if let track = vm.currentTrack, track.isPlaying {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform")
                            .symbolEffect(.variableColor.iterative, options: .repeating)
                            .foregroundStyle(Color(hex: "#1DB954"))
                        Text("\(track.title) — \(track.artist)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                } else {
                    Text(vm.isIslandActive ? tr("Waiting for Spotify / Apple Music playback…", "Menunggu pemutaran Spotify / Apple Music…") : tr("Enable switch on the top right to activate Island", "Aktifkan sakelar di kanan untuk memunculkan Island"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(vm.isIslandActive ? Color(hex: "#1DB954").opacity(0.10) : Color.primary.opacity(0.04))
            )

            // Quick Actions Bar
            HStack(spacing: 10) {
                Button(action: {
                    vm.testIslandAnimation()
                }) {
                    Label(tr("Test Island Animation", "Uji Animasi Island"), systemImage: "sparkles")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button(action: {
                    vm.resetIslandPosition()
                }) {
                    Label(tr("Reset Position", "Reset Posisi"), systemImage: "arrow.counterclockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Button(action: {
                    vm.toggleIsland()
                }) {
                    Label(vm.isIslandVisible ? tr("Hide Island", "Sembunyikan Island") : tr("Show Island", "Tampilkan Island"),
                          systemImage: vm.isIslandVisible ? "eye.slash" : "eye")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .tint(vm.isIslandVisible ? Color.secondary : Color(hex: "#1DB954"))
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color.primary.opacity(0.02))
    }

    // MARK: - Tab 1: General Settings
    private var generalTabView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Section 0: Language Preferences (Bilingual Support: English Default & Indonesian)
                GroupBox(label: Label(tr("Language Preferences", "Preferensi Bahasa"), systemImage: "globe").font(.headline)) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            ForEach(AppLanguage.allCases) { lang in
                                LanguageCard(
                                    lang: lang,
                                    isSelected: vm.appLanguage == lang
                                ) {
                                    vm.setAppLanguage(lang)
                                }
                            }
                        }

                        Text(tr("Select your preferred interface language. English is active by default.", "Pilih bahasa tampilan antarmuka. Bahasa Inggris aktif secara bawaan."))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                // Section 1: Status & Behavior
                GroupBox(label: Label(tr("Dynamic Island Status", "Status Dynamic Island"), systemImage: "power").font(.headline)) {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle(tr("Enable Dynamic Island", "Aktifkan Dynamic Island"), isOn: Binding(
                            get: { vm.isIslandActive },
                            set: { vm.setIslandActive($0) }
                        ))
                        .toggleStyle(.switch)
                        .tint(Color(hex: "#1DB954"))

                        Text(tr("When turned off, the Island will not appear at the top of your screen even while music is playing.", "Jika dimatikan, Island tidak akan muncul di layar atas meskipun musik sedang diputar di Spotify atau Apple Music."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                // Section 2: System Preferences
                GroupBox(label: Label(tr("macOS System Preferences", "Preferensi Sistem macOS"), systemImage: "macwindow").font(.headline)) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(tr("Launch Automatically at Login (Launch at Login)", "Buka Otomatis Saat Login (Launch at Login)"), isOn: $launchAtLogin)
                            .onChange(of: launchAtLogin) { _, newValue in
                                UserDefaults.standard.set(newValue, forKey: "launchAtLogin")
                            }

                        Toggle(tr("Show Icon in macOS Dock (Show Dock Icon)", "Tampilkan Ikon di Dock macOS (Show Dock Icon)"), isOn: Binding(
                            get: { vm.showDockIcon },
                            set: { vm.setShowDockIcon($0) }
                        ))

                        Text(tr("When turned off, Dynatify runs silently in the background (.accessory) without cluttering your Dock, accessible anytime via the Menu Bar and Global Hotkey.", "Jika dimatikan, Dynatify akan berjalan di background (.accessory) tanpa mengotori Dock, dan kontrol tetap mudah diakses lewat Menu Bar dan Global Hotkey."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                // Section 3: Smart Auto-Trigger (Pillar D)
                GroupBox(label: Label(tr("Smart Auto-Trigger", "Pemicu Cerdas (Smart Auto-Trigger)"), systemImage: "bolt.badge.clock.fill").font(.headline)) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(tr("Auto-show Island when music starts playing", "Munculkan Island Otomatis Saat Musik Mulai Diputar"), isOn: Binding(
                            get: { vm.autoShowOnPlay },
                            set: { vm.setAutoShowOnPlay($0) }
                        ))

                        Toggle(tr("Auto-hide Island when music is paused (Auto-Hide on Pause)", "Sembunyikan Island Otomatis Saat Musik Dijeda (Auto-Hide on Pause)"), isOn: Binding(
                            get: { vm.autoHideOnPause },
                            set: { vm.setAutoHideOnPause($0) }
                        ))

                        if vm.autoHideOnPause {
                            HStack {
                                Text(tr("Pause duration before hiding:", "Durasi jeda sebelum disembunyikan:"))
                                    .font(.caption)

                                Spacer()

                                Picker("", selection: Binding(
                                    get: { vm.autoHideTimeoutSeconds },
                                    set: { vm.setAutoHideTimeoutSeconds($0) }
                                )) {
                                    Text(tr("1 Minute", "1 Menit")).tag(60.0)
                                    Text(tr("3 Minutes", "3 Menit")).tag(180.0)
                                    Text(tr("5 Minutes (Recommended)", "5 Menit (Rekomendasi)")).tag(300.0)
                                    Text(tr("10 Minutes", "10 Menit")).tag(600.0)
                                }
                                .pickerStyle(.menu)
                                .frame(width: 190)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }

                // Section 4: Live Connection Diagnostics
                GroupBox(label: Label(tr("Music Player Diagnostics", "Pemeriksaan Pemutar Musik"), systemImage: "waveform.badge.magnifyingglass").font(.headline)) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Button(action: {
                                isTestingConnection = true
                                Task {
                                    let result = await vm.testMusicPlayerConnection()
                                    connectionMessage = result.message
                                    isTestingConnection = false
                                }
                            }) {
                                if isTestingConnection {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Label(tr("Check Spotify & Apple Music Connection", "Cek Koneksi Spotify & Apple Music"), systemImage: "play.circle")
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(isTestingConnection)

                            Spacer()

                            Circle()
                                .fill(vm.isMusicConnected ? Color.green : Color.orange)
                                .frame(width: 8, height: 8)
                            Text(vm.isMusicConnected ? tr("Connected", "Terhubung") : tr("Waiting for track", "Menunggu Lagu"))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        if let message = connectionMessage {
                            Text(message)
                                .font(.caption)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.04)))

                            if message.contains("-1743") || message.contains("Not authorized") {
                                Button(tr("Open macOS Privacy & Automation Settings…", "Buka Pengaturan Privasi & Otomasi macOS…")) {
                                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                                        NSWorkspace.shared.open(url)
                                    }
                                }
                                .buttonStyle(.link)
                                .font(.caption)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }

                // Section 5: Software Update
                GroupBox(label: Label(tr("Software Update", "Pembaruan Perangkat Lunak"), systemImage: "arrow.triangle.2.circlepath.circle.fill").font(.headline)) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("Dynatify v\(IslandViewModel.appVersion)")
                                        .font(.subheadline.weight(.semibold))
                                    if vm.isUpdateAvailable {
                                        Text(tr("Update Available: v\(vm.latestVersion)", "Update Tersedia: v\(vm.latestVersion)"))
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(Color.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Capsule().fill(Color(hex: "#1DB954")))
                                    }
                                }
                                Text(vm.updateStatusMessage.isEmpty ? tr("Dynatify v\(IslandViewModel.appVersion) is the latest stable release.", "Dynatify v\(IslandViewModel.appVersion) adalah versi rilis stabil.") : vm.updateStatusMessage)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button(action: {
                                vm.checkForUpdates(manual: true)
                            }) {
                                if vm.isCheckingForUpdates {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Label(tr("Check for Updates", "Periksa Pembaruan"), systemImage: "arrow.clockwise")
                                        .font(.caption)
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(vm.isCheckingForUpdates)
                        }

                        if vm.isUpdateAvailable, let downloadURL = vm.updateDownloadURL {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(vm.updateReleaseNotes)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(8)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.04)))

                                HStack {
                                    Button(action: {
                                        NSWorkspace.shared.open(downloadURL)
                                    }) {
                                        Label(tr("Download Update on GitHub", "Unduh Pembaruan di GitHub"), systemImage: "arrow.down.circle.fill")
                                            .font(.caption.weight(.semibold))
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(Color(hex: "#1DB954"))

                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Tab 2: Appearance Settings
    private var appearanceTabView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Section 1: Appearance Mode (Auto / Dark / Light)
                GroupBox(label: Label(tr("UI Appearance Mode (Dark & Light)", "Mode Tampilan UI (Dark & Light)"), systemImage: "circle.righthalf.filled").font(.headline)) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            ForEach(AppearanceMode.allCases) { mode in
                                AppearanceModeCard(mode: mode, lang: vm.appLanguage, isSelected: vm.appearanceMode == mode) {
                                    vm.setAppearanceMode(mode)
                                }
                            }
                        }

                        Text(vm.appearanceMode.subtitle(for: vm.appLanguage))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                // Section 2: Style Selector (Versi 1 s/d 5)
                GroupBox(label: Label(tr("Dynamic Island Style (Version 1 to 5)", "Gaya Tampilan Dynamic Island (Versi 1 s/d 5)"), systemImage: "square.grid.2x2.fill").font(.headline)) {
                    VStack(spacing: 8) {
                        ForEach(IslandStyle.allCases) { style in
                            IslandStyleCard(style: style, lang: vm.appLanguage, isSelected: vm.islandStyle == style) {
                                vm.setIslandStyle(style)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }

                // Visualizer Themes
                GroupBox(label: Label(tr("Waveform & Visualizer Color", "Warna Waveform & Visualizer"), systemImage: "paintpalette").font(.headline)) {
                    HStack(spacing: 12) {
                        ForEach(VisualizerTheme.allCases) { theme in
                            VisualizerThemeItem(theme: theme, isSelected: vm.visualizerTheme == theme) {
                                vm.setVisualizerTheme(theme)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }

                // Adaptive Width Configuration
                GroupBox(label: Label(tr("Adaptive Island Width", "Lebar Island Adaptif"), systemImage: "arrow.left.and.right").font(.headline)) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(tr("Auto-adjust width to match lyric length", "Sesuaikan Lebar Otomatis Mengikuti Panjang Lirik"), isOn: Binding(
                            get: { vm.isAdaptiveWidth },
                            set: { vm.setIsAdaptiveWidth($0) }
                        ))

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(tr("Maximum Width Limit: \(Int(vm.customCompactWidth)) pt", "Batas Lebar Maksimal: \(Int(vm.customCompactWidth)) pt"))
                                    .font(.caption)
                                Spacer()
                            }
                            Slider(
                                value: Binding(
                                    get: { vm.customCompactWidth },
                                    set: { vm.setCustomCompactWidth($0) }
                                ),
                                in: 280...580,
                                step: 10
                            )
                        }
                    }
                    .padding(.vertical, 6)
                }

                // Opacity & Liquid Glass
                GroupBox(label: Label(tr("Transparency & Liquid Glass Effect", "Transparansi & Efek Liquid Glass"), systemImage: "drop.fill").font(.headline)) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(tr("Opacity: \(Int(vm.opacity * 100))%", "Opasitas: \(Int(vm.opacity * 100))%"))
                                .font(.caption)
                            Spacer()
                        }
                        Slider(value: $vm.opacity, in: 0.7...1.0, step: 0.05)
                            .onChange(of: vm.opacity) { _, val in
                                storedOpacity = val
                            }
                    }
                    .padding(.vertical, 6)
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Tab 3: Lyrics & Top Bar Settings
    private var lyricsTabView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Placement mode
                GroupBox(label: Label(tr("Lyric Placement Mode", "Mode Penempatan Lirik"), systemImage: "menubar.dock.rectangle").font(.headline)) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(DisplayLocationMode.allCases) { mode in
                            DisplayLocationModeCard(mode: mode, lang: vm.appLanguage, isSelected: vm.displayLocationMode == mode) {
                                vm.setDisplayLocationMode(mode)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }

                // Sync engine info
                GroupBox(label: Label(tr("Real-Time Lyric Engine", "Mesin Lirik Real-Time"), systemImage: "clock.arrow.2.circlepath").font(.headline)) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(tr("Dynatify uses a high-performance synchronous LRC engine with 50ms polling. Lyrics move instantaneously with zero delay when seeking tracks.", "Dynatify menggunakan mesin LRC sinkron berkecepatan tinggi dengan polling 50ms. Lirik bergerak seketika tanpa delay saat lagu dimajukan atau dimundurkan."))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Divider()

                        HStack {
                            Text(tr("Time Offset Compensation (Sync Offset):", "Kompensasi Offset Waktu (Sync Offset):"))
                                .font(.caption)
                            Spacer()
                            Text(String(format: "%+.1f s", vm.syncOffsetSeconds))
                                .font(.caption.monospacedDigit())
                        }

                        Slider(
                            value: Binding(
                                get: { vm.syncOffsetSeconds },
                                set: { vm.setSyncOffset(seconds: $0) }
                            ),
                            in: -2.0...2.0,
                            step: 0.1
                        )

                        Text(tr("Slide left if lyrics are late, slide right if lyrics are ahead.", "Geser ke kiri jika lirik telat, geser ke kanan jika lirik terlalu cepat."))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                // Next Lyric Lead Time (Lookahead / Early Display)
                GroupBox(label: Label(tr("Next Lyric Lead Time (Lookahead)", "Lead Time Lirik Berikutnya (Lookahead)"), systemImage: "forward.frame.fill").font(.headline)) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(tr("Display next lyric line early:", "Tampilkan lirik berikutnya lebih awal:"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            HStack(spacing: 5) {
                                Image(systemName: vm.nextLyricLeadSeconds == 0 ? "clock" : "bolt.fill")
                                    .font(.caption2)
                                Text(vm.nextLyricLeadSeconds == 0 ? tr("Normal (0.0s)", "Normal (0.0s)") : tr(String(format: "%.1fs Early", vm.nextLyricLeadSeconds), String(format: "%.1fs Lebih Awal", vm.nextLyricLeadSeconds)))
                                    .font(.caption.weight(.bold))
                            }
                            .foregroundStyle(vm.nextLyricLeadSeconds == 0 ? Color.secondary : Color(hex: "#1DB954"))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(vm.nextLyricLeadSeconds == 0 ? Color.primary.opacity(0.08) : Color(hex: "#1DB954").opacity(0.15))
                            )
                        }

                        // Presets
                        HStack(spacing: 8) {
                            leadPresetButton(title: tr("Normal (0s)", "Normal (0s)"), value: 0.0)
                            leadPresetButton(title: "0.3s", value: 0.3)
                            leadPresetButton(title: tr("0.5s (Recommended)", "0.5s (Rekomendasi)"), value: 0.5)
                            leadPresetButton(title: "0.8s", value: 0.8)
                            leadPresetButton(title: "1.0s", value: 1.0)
                        }

                        // Fine-tune Slider
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(tr("Fine-tune Customization (Slider):", "Kustomisasi Halus (Slider):"))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(String(format: tr("%.2f seconds", "%.2f detik"), vm.nextLyricLeadSeconds))
                                    .font(.caption.monospacedDigit())
                            }
                            Slider(
                                value: Binding(
                                    get: { vm.nextLyricLeadSeconds },
                                    set: { vm.setNextLyricLeadSeconds($0) }
                                ),
                                in: 0.0...2.0,
                                step: 0.05
                            )
                            .tint(Color(hex: "#1DB954"))
                        }

                        Text(tr("Even before the current lyric line finishes, the upcoming line appears early by your chosen lead time so you can sing along without missing a beat.", "Walaupun lirik saat ini belum selesai, lirik berikutnya akan tampil lebih awal sesuai detik yang Anda tentukan agar siap dibaca/dinyanyikan."))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                // Next Line Hint
                GroupBox(label: Label(tr("Lyric Sneak Peek", "Bocoran Lirik"), systemImage: "text.bubble").font(.headline)) {
                    Toggle(tr("Show Next Lyric Line Hint on Hover", "Tampilkan Baris Lirik Berikutnya Saat Di-hover"), isOn: $vm.showNextLyricHint)
                        .padding(.vertical, 4)
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Tab 4: Shortcuts Settings (Pillar C)
    private var shortcutsTabView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                GroupBox(label: Label(tr("Global Keyboard Shortcuts (The Magic Triggers)", "Pintasan Keyboard Global (The Magic Triggers)"), systemImage: "keyboard").font(.headline)) {
                    VStack(spacing: 12) {
                        shortcutRow(
                            title: tr("Hide / Show Island (Magic Trigger)", "Sembunyikan / Tampilkan Island (Magic Trigger)"),
                            shortcut: "⌥ Space",
                            description: tr("Press Option + Space anywhere to toggle the Island without touching your mouse.", "Tekan Option + Spasi kapan saja untuk menyembunyikan atau memunculkan Island tanpa menyentuh mouse.")
                        )

                        Divider()

                        shortcutRow(
                            title: tr("Alternative Island Toggle", "Alternatif Toggle Island"),
                            shortcut: "⌘ ⇧ D",
                            description: tr("Command + Shift + D combination to toggle Island visibility.", "Kombinasi Command + Shift + D untuk memunculkan / menyembunyikan Island.")
                        )

                        Divider()

                        shortcutRow(
                            title: tr("Expand / Collapse Island", "Buka / Kecilkan Island (Expand / Collapse)"),
                            shortcut: "⌘ ⇧ E",
                            description: tr("Expand Island into a rich interactive music card with multi-line lyrics and volume controls.", "Buka Island menjadi kartu musik interaktif lengkap dengan lirik berbaris dan kontrol volume.")
                        )

                        Divider()

                        shortcutRow(
                            title: tr("Collapse back to Notch", "Tutup / Ciutkan Kembali ke Notch"),
                            shortcut: "Esc / Click Outside",
                            description: tr("Pressing Escape or clicking anywhere outside the Island automatically collapses it back to the notch.", "Menekan Escape atau mengklik area desktop di luar Island otomatis mengecilkan kembali ke notch.")
                        )

                        Divider()

                        shortcutRow(
                            title: tr("Open Dynatify Control Center", "Buka Control Center / Pengaturan"),
                            shortcut: "⌘ ,",
                            description: tr("Open this preferences dashboard directly from anywhere.", "Membuka jendela dashboard ini langsung dari mana saja.")
                        )
                    }
                    .padding(.vertical, 6)
                }

                // Deep work guidance
                GroupBox(label: Label(tr("Deep Work Philosophy", "Filosofi Deep Work"), systemImage: "lightbulb.fill").font(.headline)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(tr("Dynatify is engineered so you never need to Alt-Tab to your music player while in deep work or coding flow.", "Dynatify dirancang agar kamu tidak perlu lagi beralih aplikasi (Alt-Tab) ke Spotify saat sedang fokus bekerja atau koding."))
                            .font(.caption)

                        Text(tr("• Use 'Top Bar Only' mode if you prefer your notch area 100% free of floating UI.\n• Use '⌥ Space' to peek lyrics for 3 seconds then seamlessly dismiss.", "• Gunakan mode 'Hanya Top Bar' jika ingin ruang layar notch 100% bebas dari elemen mengambang.\n• Gunakan pintasan '⌥ Space' untuk intip lirik 3 detik lalu sembunyikan kembali."))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func shortcutRow(title: String, shortcut: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(shortcut)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(0.08))
                )
        }
    }

    private func leadPresetButton(title: String, value: Double) -> some View {
        let isSelected = abs(vm.nextLyricLeadSeconds - value) < 0.04
        return Button(action: {
            vm.setNextLyricLeadSeconds(value)
        }) {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isSelected ? Color(hex: "#1DB954") : Color.primary.opacity(0.06))
                )
                .foregroundStyle(isSelected ? Color.black : Color.primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Footer
    private var footerBarView: some View {
        HStack {
            Text("Dynatify • by @uwayxt")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer()

            Button(tr("Close Window", "Tutup Jendela")) {
                NSApp.keyWindow?.orderOut(nil)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .keyboardShortcut("w", modifiers: .command)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.02))
    }
}

// MARK: - Subviews for Clean Type Checking
private struct LanguageCard: View {
    let lang: AppLanguage
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                Text(lang.flag)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(lang.displayName)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)

                    Text(lang == .english ? "Worldwide / Default" : "Pasar Indonesia")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(hex: "#1DB954"))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color(hex: "#1DB954").opacity(0.12) : Color.primary.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color(hex: "#1DB954") : Color.primary.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct IslandStyleCard: View {
    let style: IslandStyle
    let lang: AppLanguage
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: style.iconName)
                .font(.title3)
                .frame(width: 28)
                .foregroundStyle(isSelected ? Color(hex: "#1DB954") : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(style.displayName(for: lang))
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                Text(style.subtitle(for: lang))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color(hex: "#1DB954"))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color(hex: "#1DB954").opacity(0.12) : Color.primary.opacity(0.02))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}

private struct AppearanceModeCard: View {
    let mode: AppearanceMode
    let lang: AppLanguage
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? Color(hex: "#1DB954") : Color.secondary)

                Text(mode.title(for: lang))
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color(hex: "#1DB954").opacity(0.12) : Color.primary.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color(hex: "#1DB954") : Color.primary.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct VisualizerThemeItem: View {
    @EnvironmentObject var vm: IslandViewModel
    let theme: VisualizerTheme
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(theme.gradient)
                .frame(width: 26, height: 26)
                .overlay(
                    Circle()
                        .stroke(isSelected ? (vm.isEffectiveDarkMode ? Color.white : Color.black.opacity(0.8)) : Color.clear, lineWidth: 2)
                )

            Text(theme.title)
                .font(.caption2)
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.primary.opacity(0.08) : Color.clear)
        )
        .onTapGesture {
            onSelect()
        }
    }
}

private struct DisplayLocationModeCard: View {
    let mode: DisplayLocationMode
    let lang: AppLanguage
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: mode.icon)
                .font(.title3)
                .frame(width: 26)
                .foregroundStyle(isSelected ? Color(hex: "#1DB954") : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(mode.title(for: lang))
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                Text(mode.subtitle(for: lang))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color(hex: "#1DB954"))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color(hex: "#1DB954").opacity(0.12) : Color.primary.opacity(0.02))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}
