import AppKit
import SwiftUI
import Combine
import ApplicationServices

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSWindowDelegate {
    var islandPanel: IslandPanel?
    var statusItem: NSStatusItem?
    var mainWindow: NSWindow?
    let islandViewModel = IslandViewModel()

    private var cancellables = Set<AnyCancellable>()
    private var isExplicitQuit = false
    private var outsideClickMonitor: Any?
    private var globalKeyMonitor: Any?
    private var localKeyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure App Icon is explicitly set for macOS Dock
        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let iconImage = NSImage(contentsOf: iconURL) {
            NSApp.applicationIconImage = iconImage
        } else if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "png"),
                  let iconImage = NSImage(contentsOf: iconURL) {
            NSApp.applicationIconImage = iconImage
        }

        // Start as regular app with focus so macOS can present the Automation authorization prompt
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Request automation permission for Spotify and Apple Music
        requestPermissionsIfNeeded()

        setupMenuBar()
        setupIslandPanel()
        setupGlobalShortcut()
        setupOutsideClickMonitor()
        setupViewModelBindings()

        islandViewModel.startMonitoring()

        // Pillar A: Open Main App Window (Control Center) on launch
        openMainWindow()

        // Transition to accessory (menu bar only) if user preference has Dock Icon disabled
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard let self = self else { return }
            if !self.islandViewModel.showDockIcon {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }

    private func requestPermissionsIfNeeded() {
        _ = requestAppleEventsPermission(for: "com.spotify.client")
        _ = requestAppleEventsPermission(for: "com.apple.Music")
    }

    private func requestAppleEventsPermission(for bundleID: String) -> OSStatus {
        var targetDesc = AEDesc()
        let status = bundleID.withCString { cStr in
            AECreateDesc(DescType(typeApplicationBundleID), cStr, strlen(cStr), &targetDesc)
        }
        guard status == noErr else { return OSStatus(status) }
        defer { AEDisposeDesc(&targetDesc) }
        return AEDeterminePermissionToAutomateTarget(&targetDesc, typeWildCard, typeWildCard, true)
    }

    // MARK: - Prevent Accidental App Termination
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // App stays alive in Menu Bar and Notch even when windows are closed
        return false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if isExplicitQuit {
            return .terminateNow
        }
        return .terminateCancel
    }

    @objc func quitApp() {
        isExplicitQuit = true
        islandViewModel.stopMonitoring()
        if let monitor = outsideClickMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = globalKeyMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = localKeyMonitor { NSEvent.removeMonitor(monitor) }
        NSApp.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        islandViewModel.stopMonitoring()
    }

    // MARK: - ViewModel Bindings
    private func setupViewModelBindings() {
        // Bind Dock Icon preference
        islandViewModel.$showDockIcon
            .receive(on: DispatchQueue.main)
            .sink { show in
                NSApp.setActivationPolicy(show ? .regular : .accessory)
                if show {
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
            .store(in: &cancellables)

        // Bind visibility & display mode to panel
        Publishers.CombineLatest3(islandViewModel.$isIslandActive, islandViewModel.$isIslandVisible, islandViewModel.$displayLocationMode)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (isActive, isVisible, mode) in
                guard let self = self else { return }
                if isActive && isVisible && mode != .menuBarOnly {
                    self.islandPanel?.orderFront(nil)
                } else {
                    self.islandPanel?.orderOut(nil)
                }
                self.updateMenuBarLyricText()
            }
            .store(in: &cancellables)
    }

    // MARK: - Menu Bar Setup (Variable Length for Real-Time Lyrics)
    private func setupMenuBar() {
        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        }
        guard let button = statusItem?.button else { return }
        button.target = self
        button.font = NSFont.systemFont(ofSize: 12.5, weight: .medium)

        let menu = NSMenu()
        menu.delegate = self
        statusItem?.menu = menu

        updateMenuBarLyricText()

        // Bind real-time menu bar lyric updates
        islandViewModel.$activeLyricIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBarLyricText()
            }
            .store(in: &cancellables)

        islandViewModel.$currentTrack
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBarLyricText()
            }
            .store(in: &cancellables)

        islandViewModel.$hasPassedIntro
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBarLyricText()
            }
            .store(in: &cancellables)
    }

    func updateMenuBarLyricText() {
        guard let button = statusItem?.button else { return }

        switch islandViewModel.displayLocationMode {
        case .both, .menuBarOnly:
            if islandViewModel.hasActiveMusic {
                button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: nil)
                button.imagePosition = .imageLeading
                button.title = " " + islandViewModel.menuBarLyricText
            } else {
                button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Dynatify")
                button.imagePosition = .imageLeading
                button.title = " Dynatify"
            }
        case .islandOnly:
            button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Dynatify")
            button.imagePosition = .imageOnly
            button.title = ""
        }
    }

    // MARK: - Dynamic Menu Population (NSMenuDelegate)
    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()

        // Credit Header
        let titleItem = NSMenuItem(title: "Dynatify • by @uwayxt", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        // Song Info
        if let track = islandViewModel.currentTrack {
            let trackItem = NSMenuItem(title: "🎵 \(track.title) — \(track.artist) (\(track.playerSource.rawValue))", action: nil, keyEquivalent: "")
            trackItem.isEnabled = false
            menu.addItem(trackItem)

            if !islandViewModel.lyrics.isEmpty && islandViewModel.lyrics.indices.contains(islandViewModel.activeLyricIndex) {
                let currentLine = islandViewModel.lyrics[islandViewModel.activeLyricIndex].text.trimmingCharacters(in: .whitespaces)
                if !currentLine.isEmpty {
                    let lyricItem = NSMenuItem(title: "💬 \"\(currentLine)\"", action: nil, keyEquivalent: "")
                    lyricItem.isEnabled = false
                    menu.addItem(lyricItem)
                }
            }

            if let next = islandViewModel.nextLyricText {
                let nextPrefix = tr("⏩ Next lyric: ", "⏩ Lirik berikut: ")
                let nextItem = NSMenuItem(title: "\(nextPrefix)\"\(next)\"", action: nil, keyEquivalent: "")
                nextItem.isEnabled = false
                menu.addItem(nextItem)
            }
        } else {
            let noSongTitle = tr("💤 No music playing", "💤 Tidak ada musik yang diputar")
            let noSongItem = NSMenuItem(title: noSongTitle, action: nil, keyEquivalent: "")
            noSongItem.isEnabled = false
            menu.addItem(noSongItem)
        }

        menu.addItem(.separator())

        // Quick Controls
        if islandViewModel.hasActiveMusic {
            let isPlaying = islandViewModel.currentTrack?.isPlaying == true
            let playPauseTitle = isPlaying ? tr("⏸ Pause", "⏸ Jeda (Pause)") : tr("▶️ Play", "▶️ Putar (Play)")
            let playPauseItem = NSMenuItem(title: playPauseTitle, action: #selector(menuPlayPause), keyEquivalent: " ")
            playPauseItem.target = self
            menu.addItem(playPauseItem)

            let nextTitle = tr("⏭ Next Track", "⏭ Lagu Berikutnya")
            let nextItem = NSMenuItem(title: nextTitle, action: #selector(menuNextTrack), keyEquivalent: "")
            nextItem.target = self
            menu.addItem(nextItem)

            let prevTitle = tr("⏮ Previous Track", "⏮ Lagu Sebelumnya")
            let prevItem = NSMenuItem(title: prevTitle, action: #selector(menuPrevTrack), keyEquivalent: "")
            prevItem.target = self
            menu.addItem(prevItem)

            menu.addItem(.separator())
        }

        // Toggle Island Visibility
        let toggleTitle = islandViewModel.isIslandVisible
            ? tr("👁️ Hide Dynamic Island", "👁️ Sembunyikan Island (Hide)")
            : tr("👁️ Show Dynamic Island", "👁️ Munculkan Island (Show)")
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleIsland), keyEquivalent: " ")
        toggleItem.keyEquivalentModifierMask = [.option]
        toggleItem.target = self
        menu.addItem(toggleItem)

        // Submenu: Display Location Mode (Both, Island Only, Top Bar Only)
        let modeSubmenu = NSMenu()
        for mode in DisplayLocationMode.allCases {
            let item = NSMenuItem(title: mode.title(for: islandViewModel.appLanguage), action: #selector(selectModeFromMenu(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mode
            item.state = (islandViewModel.displayLocationMode == mode) ? .on : .off
            modeSubmenu.addItem(item)
        }
        let modeMenuItem = NSMenuItem(title: tr("Lyric Placement Mode", "Mode Penempatan Lirik"), action: nil, keyEquivalent: "")
        modeMenuItem.submenu = modeSubmenu
        menu.addItem(modeMenuItem)

        // Submenu: Island Styles (Versi 1 s/d 5)
        let styleSubmenu = NSMenu()
        for style in IslandStyle.allCases {
            let item = NSMenuItem(title: style.displayName(for: islandViewModel.appLanguage), action: #selector(selectStyleFromMenu(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = style
            item.state = (islandViewModel.islandStyle == style) ? .on : .off
            styleSubmenu.addItem(item)
        }
        let styleMenuItem = NSMenuItem(title: tr("Dynamic Island Style", "Gaya Tampilan Island"), action: nil, keyEquivalent: "")
        styleMenuItem.submenu = styleSubmenu
        menu.addItem(styleMenuItem)

        // Submenu: Visualizer Colors
        let themeSubmenu = NSMenu()
        for theme in VisualizerTheme.allCases {
            let item = NSMenuItem(title: theme.title, action: #selector(selectThemeFromMenu(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = theme
            item.state = (islandViewModel.visualizerTheme == theme) ? .on : .off
            themeSubmenu.addItem(item)
        }
        let themeMenuItem = NSMenuItem(title: tr("Waveform Color", "Warna Waveform"), action: nil, keyEquivalent: "")
        themeMenuItem.submenu = themeSubmenu
        menu.addItem(themeMenuItem)

        // Submenu: Next Lyric Lead Time (Lookahead)
        let leadSubmenu = NSMenu()
        let leadPresets: [(String, Double)] = [
            (tr("Normal (0.0s)", "Normal (0.0s)"), 0.0),
            (tr("0.3s Early", "0.3s Lebih Awal"), 0.3),
            (tr("0.5s Early (Recommended)", "0.5s Lebih Awal (Rekomendasi)"), 0.5),
            (tr("0.8s Early", "0.8s Lebih Awal"), 0.8),
            (tr("1.0s Early", "1.0s Lebih Awal"), 1.0)
        ]
        for (label, val) in leadPresets {
            let item = NSMenuItem(title: label, action: #selector(selectLeadTimeFromMenu(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = val
            let isSelected = abs(islandViewModel.nextLyricLeadSeconds - val) < 0.04
            item.state = isSelected ? .on : .off
            leadSubmenu.addItem(item)
        }
        let leadMenuItem = NSMenuItem(title: tr("Next Lyric Lead Time", "Lead Time Lirik Berikutnya"), action: nil, keyEquivalent: "")
        leadMenuItem.submenu = leadSubmenu
        menu.addItem(leadMenuItem)

        // Submenu: Language Selector (English Default / Indonesian)
        let langSubmenu = NSMenu()
        for lang in AppLanguage.allCases {
            let item = NSMenuItem(title: "\(lang.flag) \(lang.displayName)", action: #selector(selectLanguageFromMenu(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = lang
            item.state = (islandViewModel.appLanguage == lang) ? .on : .off
            langSubmenu.addItem(item)
        }
        let langMenuItem = NSMenuItem(title: tr("Language (Bahasa)", "Bahasa (Language)"), action: nil, keyEquivalent: "")
        langMenuItem.submenu = langSubmenu
        menu.addItem(langMenuItem)

        menu.addItem(.separator())

        // Toggle Expand / Collapse
        let expandTitle = islandViewModel.islandState == .expanded
            ? tr("Collapse to Notch", "Kecilkan ke Notch (Collapse)")
            : tr("Expand Dynamic Island", "Buka Dynamic Island (Expand)")
        let expandItem = NSMenuItem(title: expandTitle, action: #selector(toggleExpand), keyEquivalent: "e")
        expandItem.keyEquivalentModifierMask = [.command, .shift]
        expandItem.target = self
        menu.addItem(expandItem)

        // Control Center Window (Pillar A)
        let openSettingsItem = NSMenuItem(title: tr("Open Dynatify Control Center…", "Buka Control Center Dynatify…"), action: #selector(openMainWindow), keyEquivalent: ",")
        openSettingsItem.target = self
        menu.addItem(openSettingsItem)

        menu.addItem(.separator())

        // Explicit Quit
        let quitItem = NSMenuItem(title: tr("Quit Dynatify", "Keluar dari Dynatify"), action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func tr(_ en: String, _ id: String) -> String {
        islandViewModel.appLanguage == .english ? en : id
    }

    @objc private func selectLanguageFromMenu(_ sender: NSMenuItem) {
        guard let lang = sender.representedObject as? AppLanguage else { return }
        islandViewModel.setAppLanguage(lang)
    }

    @objc private func menuPlayPause() {
        islandViewModel.playPause()
    }

    @objc private func menuNextTrack() {
        islandViewModel.nextTrack()
    }

    @objc private func menuPrevTrack() {
        islandViewModel.previousTrack()
    }

    @objc private func selectModeFromMenu(_ sender: NSMenuItem) {
        guard let mode = sender.representedObject as? DisplayLocationMode else { return }
        islandViewModel.setDisplayLocationMode(mode)
    }

    @objc private func selectStyleFromMenu(_ sender: NSMenuItem) {
        guard let style = sender.representedObject as? IslandStyle else { return }
        islandViewModel.setIslandStyle(style)
    }

    @objc private func selectThemeFromMenu(_ sender: NSMenuItem) {
        guard let theme = sender.representedObject as? VisualizerTheme else { return }
        islandViewModel.setVisualizerTheme(theme)
    }

    @objc private func selectLeadTimeFromMenu(_ sender: NSMenuItem) {
        guard let seconds = sender.representedObject as? Double else { return }
        islandViewModel.setNextLyricLeadSeconds(seconds)
    }

    @objc func toggleExpand() {
        if islandViewModel.islandState == .expanded {
            islandViewModel.collapse()
        } else {
            islandViewModel.expand()
        }
    }

    @objc func toggleIsland() {
        islandViewModel.toggleIsland()
    }

    // MARK: - Pillar A: The Main App Window (Control Center Dashboard)
    @objc func openMainWindow() {
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 580, height: 650),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Dynatify Control Center • by @uwayxt"
        window.center()
        window.contentView = NSHostingView(
            rootView: ControlCenterView()
                .environmentObject(islandViewModel)
        )
        window.isReleasedWhenClosed = false
        window.delegate = self
        self.mainWindow = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // NSWindowDelegate: Intercept close button to hide window without quitting app
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }

    func showAbout() {
        openMainWindow()
    }

    // MARK: - Island Panel Setup
    private func setupIslandPanel() {
        let panel = IslandPanel()
        let hostingView = NSHostingView(
            rootView: IslandRootView()
                .environmentObject(islandViewModel)
        )
        // Disable automatic window sizing constraints from NSHostingView
        // This completely prevents _postWindowNeedsUpdateConstraints exceptions when resizing
        hostingView.sizingOptions = []
        panel.contentView = hostingView
        panel.updateFrame(for: islandViewModel.islandState, style: islandViewModel.islandStyle, customWidth: islandViewModel.currentCompactWidth, animated: false)

        if islandViewModel.isIslandActive && islandViewModel.isIslandVisible && islandViewModel.displayLocationMode != .menuBarOnly {
            panel.orderFront(nil)
        }
        self.islandPanel = panel

        // Subscribe to state, style, and adaptive width changes safely
        Publishers.CombineLatest3(islandViewModel.$islandState, islandViewModel.$islandStyle, islandViewModel.$currentCompactWidth)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (newState, newStyle, newWidth) in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if self.islandViewModel.isIslandActive && self.islandViewModel.isIslandVisible && self.islandViewModel.displayLocationMode != .menuBarOnly {
                        self.islandPanel?.updateFrame(for: newState, style: newStyle, customWidth: newWidth, animated: true)
                    }
                }
            }
            .store(in: &cancellables)

        // Also subscribe to appearance mode changes to refresh panel
        islandViewModel.$appearanceMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.islandPanel?.contentView?.needsLayout = true
                    self.islandPanel?.contentView?.needsDisplay = true
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Auto-Collapse On Outside Click
    private func setupOutsideClickMonitor() {
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self, self.islandViewModel.islandState == .expanded else { return }
                guard let panel = self.islandPanel, panel.isVisible else { return }
                let mouseLoc = NSEvent.mouseLocation
                let pad = IslandPanel.shadowPadding
                let pillRect = panel.frame.insetBy(dx: pad, dy: pad)
                if !pillRect.contains(mouseLoc) {
                    self.islandViewModel.collapse()
                }
            }
        }
    }

    // MARK: - Pillar C: Global Keyboard Shortcuts (Magic Trigger)
    private func setupGlobalShortcut() {
        // Global monitor (when other apps are frontmost)
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }

        // Local monitor (when Dynatify is frontmost)
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyEvent(event) == true {
                return nil
            }
            return event
        }
    }

    @discardableResult
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        let keyCode = event.keyCode
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // 1. Escape key (keyCode 53): collapse expanded island back to notch
        if keyCode == 53 && islandViewModel.islandState == .expanded {
            DispatchQueue.main.async {
                self.islandViewModel.collapse()
            }
            return true
        }

        // 2. Option + Space (keyCode 49 with .option): Toggle Island Visibility (The Magic Trigger)
        if keyCode == 49 && flags.contains(.option) {
            DispatchQueue.main.async {
                self.islandViewModel.toggleIsland()
            }
            return true
        }

        // 3. Cmd + Shift + D (keyCode 2 with .command and .shift): Toggle Island Visibility
        if keyCode == 2 && flags.contains([.command, .shift]) {
            DispatchQueue.main.async {
                self.islandViewModel.toggleIsland()
            }
            return true
        }

        // 4. Cmd + Shift + E (keyCode 14 with .command and .shift): Toggle Expand/Collapse
        if keyCode == 14 && flags.contains([.command, .shift]) {
            DispatchQueue.main.async {
                self.toggleExpand()
            }
            return true
        }

        return false
    }
}
