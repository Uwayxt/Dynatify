import Foundation
import SwiftUI
import AppKit
import Combine

// MARK: - Track Model
struct Track: Equatable {
    var title: String
    var artist: String
    var album: String
    var durationSeconds: Double
    var positionSeconds: Double
    var isPlaying: Bool
    var volume: Double = 80.0
    var albumArtURL: URL?
    var albumArt: NSImage?
    var playerSource: MusicPlayerSource = .spotify
}

// MARK: - LRC Line Model
struct LRCLine: Identifiable, Equatable {
    let id = UUID()
    let timeSeconds: Double
    let text: String
}

// MARK: - Island ViewModel
@MainActor
final class IslandViewModel: ObservableObject {

    // MARK: Published State
    @Published var islandState: IslandState = .compact
    @Published var currentTrack: Track?
    @Published var lyrics: [LRCLine] = []
    @Published var activeLyricIndex: Int = 0
    @Published var isHovered: Bool = false
    @Published var opacity: Double = 1.0
    @Published var isMusicConnected: Bool = false
    @Published var isDemoMode: Bool = false
    @Published var islandStyle: IslandStyle = .directLyrics
    @Published var visualizerTheme: VisualizerTheme = .spotifyGreen
    @Published var showNextLyricHint: Bool = false
    @Published var hasPassedIntro: Bool = false

    // MARK: - Adaptive Dark & Light Mode
    @Published var appearanceMode: AppearanceMode = .auto

    // MARK: - App Language (English Default & Indonesian)
    @Published var appLanguage: AppLanguage = .english

    // MARK: - Auto-Update State & Versioning
    static let appVersion = "1.2.0"
    static let buildNumber = "120"
    @Published var isCheckingForUpdates: Bool = false
    @Published var latestVersion: String = "1.2.0"
    @Published var isUpdateAvailable: Bool = false
    @Published var updateReleaseNotes: String = ""
    @Published var updateDownloadURL: URL? = nil
    @Published var lastUpdateCheckDate: Date? = nil
    @Published var updateStatusMessage: String = "Dynatify versi v1.2.0 terinstal dan mutakhir."

    // MARK: - 3 Pillars & Smart Triggers (Dynatify)
    @Published var isIslandActive: Bool = true
    @Published var isIslandVisible: Bool = true
    @Published var autoShowOnPlay: Bool = true
    @Published var autoHideOnPause: Bool = true
    @Published var autoHideTimeoutSeconds: Double = 300.0 // 5 minutes default
    @Published var showDockIcon: Bool = false
    @Published var syncOffsetSeconds: Double = 0.0

    // MARK: - Next Lyric Lead Time (Lookahead / Early Display)
    @Published var nextLyricLeadSeconds: Double = 0.5

    // MARK: Adaptive & Customizable Width
    @Published var isAdaptiveWidth: Bool = true
    @Published var customCompactWidth: Double = 420.0
    @Published var currentCompactWidth: CGFloat = 360.0
    @Published var displayLocationMode: DisplayLocationMode = .both

    // MARK: Services & Timers
    private let playerService = MusicPlayerService()
    private let lyricsService = LyricsService()
    private var pollingTask: Task<Void, Never>?
    private var highPrecisionTimer: AnyCancellable?
    private var pauseAutoHideTask: Task<Void, Never>?
    private var lastTickTime: TimeInterval = 0
    private var lastTrackKey: String = ""

    init() {
        // Load preferences
        if UserDefaults.standard.object(forKey: "isIslandActive") != nil {
            self.isIslandActive = UserDefaults.standard.bool(forKey: "isIslandActive")
        } else {
            self.isIslandActive = true
        }

        if UserDefaults.standard.object(forKey: "autoShowOnPlay") != nil {
            self.autoShowOnPlay = UserDefaults.standard.bool(forKey: "autoShowOnPlay")
        } else {
            self.autoShowOnPlay = true
        }

        if UserDefaults.standard.object(forKey: "autoHideOnPause") != nil {
            self.autoHideOnPause = UserDefaults.standard.bool(forKey: "autoHideOnPause")
        } else {
            self.autoHideOnPause = true
        }

        let savedTimeout = UserDefaults.standard.double(forKey: "autoHideTimeoutSeconds")
        self.autoHideTimeoutSeconds = savedTimeout > 0 ? savedTimeout : 300.0

        self.showDockIcon = UserDefaults.standard.bool(forKey: "showDockIcon")
        self.syncOffsetSeconds = UserDefaults.standard.double(forKey: "syncOffsetSeconds")

        if UserDefaults.standard.object(forKey: "nextLyricLeadSeconds") != nil {
            self.nextLyricLeadSeconds = UserDefaults.standard.double(forKey: "nextLyricLeadSeconds")
        } else {
            self.nextLyricLeadSeconds = 0.5
        }

        if let savedStyleRaw = UserDefaults.standard.string(forKey: "islandStyle"),
           let savedStyle = IslandStyle(rawValue: savedStyleRaw) {
            self.islandStyle = savedStyle
        } else {
            self.islandStyle = .directLyrics
        }

        if let savedThemeRaw = UserDefaults.standard.string(forKey: "visualizerTheme"),
           let savedTheme = VisualizerTheme(rawValue: savedThemeRaw) {
            self.visualizerTheme = savedTheme
        } else {
            self.visualizerTheme = .spotifyGreen
        }

        let savedWidth = UserDefaults.standard.double(forKey: "customCompactWidth")
        if savedWidth > 200 {
            self.customCompactWidth = savedWidth
        } else {
            self.customCompactWidth = 420.0
        }

        if UserDefaults.standard.object(forKey: "isAdaptiveWidth") != nil {
            self.isAdaptiveWidth = UserDefaults.standard.bool(forKey: "isAdaptiveWidth")
        } else {
            self.isAdaptiveWidth = true
        }

        if let savedLocationRaw = UserDefaults.standard.string(forKey: "displayLocationMode"),
           let savedLocation = DisplayLocationMode(rawValue: savedLocationRaw) {
            self.displayLocationMode = savedLocation
        } else {
            self.displayLocationMode = .both
        }

        if let savedAppearanceRaw = UserDefaults.standard.string(forKey: "appearanceMode"),
           let savedMode = AppearanceMode(rawValue: savedAppearanceRaw) {
            self.appearanceMode = savedMode
        } else {
            self.appearanceMode = .auto
        }

        if let savedLangRaw = UserDefaults.standard.string(forKey: "appLanguage"),
           let savedLang = AppLanguage(rawValue: savedLangRaw) {
            self.appLanguage = savedLang
        } else {
            self.appLanguage = .english
        }

        // Setup distributed notifications
        setupDistributedNotifications()

        // Start high-precision 50ms real-time interpolation engine
        startHighPrecisionTimer()

        // Quiet background check for updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.checkForUpdates(manual: false)
        }
    }

    private func setupDistributedNotifications() {
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let info = notification.userInfo
            let name = info?["Name"] as? String
            let artist = info?["Artist"] as? String
            let album = info?["Album"] as? String
            let state = info?["Player State"] as? String
            let duration = (info?["Duration"] as? Double) ?? Double((info?["Duration"] as? Int) ?? 0)
            let position = (info?["Playback Position"] as? Double) ?? 0.0

            Task { @MainActor [weak self] in
                self?.applyPlaybackState(
                    name: name,
                    artist: artist,
                    album: album,
                    state: state,
                    durationMs: duration,
                    positionSec: position,
                    source: .spotify
                )
            }
        }

        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let info = notification.userInfo
            let name = info?["Name"] as? String
            let artist = info?["Artist"] as? String
            let album = info?["Album"] as? String
            let state = info?["Player State"] as? String
            let totalTime = Double((info?["Total Time"] as? Int) ?? 0)
            let position = (info?["Player Position"] as? Double) ?? 0.0

            Task { @MainActor [weak self] in
                self?.applyPlaybackState(
                    name: name,
                    artist: artist,
                    album: album,
                    state: state,
                    durationMs: totalTime,
                    positionSec: position,
                    source: .appleMusic
                )
            }
        }
    }

    // MARK: - Direct Distributed Notification Handling (Zero-Permission, Real-Time)
    func applyPlaybackState(
        name: String?,
        artist: String?,
        album: String?,
        state: String?,
        durationMs: Double,
        positionSec: Double,
        source: MusicPlayerSource
    ) {
        let rawState = (state ?? "").lowercased()
        let isPlaying = (rawState == "playing")

        guard let title = name, !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            if rawState == "stopped" {
                self.isMusicConnected = false
                self.currentTrack = nil
                self.lyrics = []
                self.lastTrackKey = ""
                self.hasPassedIntro = false
                self.recomputeCompactWidth()
                self.handleSmartPlaybackTrigger(isPlaying: false)
            }
            return
        }

        let artistStr = artist ?? ""
        let albumStr = album ?? ""
        let duration = durationMs > 1000 ? durationMs / 1000.0 : durationMs
        let position = positionSec

        self.isMusicConnected = true

        let trackKey = "\(title)|\(artistStr)"
        if trackKey != lastTrackKey {
            lastTrackKey = trackKey
            hasPassedIntro = false
            let newTrack = Track(
                title: title,
                artist: artistStr,
                album: albumStr,
                durationSeconds: duration,
                positionSeconds: position,
                isPlaying: isPlaying,
                volume: self.currentTrack?.volume ?? 80.0,
                albumArtURL: nil,
                albumArt: nil,
                playerSource: source
            )
            self.currentTrack = newTrack
            Task {
                await self.playerService.setCachedTrack(newTrack)
                await self.fetchLyrics(for: newTrack)
                if self.currentTrack?.albumArt == nil {
                    if let art = await MusicPlayerService.fetchAlbumArtFromiTunes(title: title, artist: artistStr) {
                        self.currentTrack?.albumArt = art
                    }
                }
            }
            recomputeCompactWidth()
        } else {
            self.currentTrack?.isPlaying = isPlaying
            if duration > 0 { self.currentTrack?.durationSeconds = duration }

            let curPos = self.currentTrack?.positionSeconds ?? 0
            let diff = position - curPos

            if !isPlaying {
                self.currentTrack?.positionSeconds = position
                updateActiveLyric(position: position, force: true)
            } else if abs(diff) > 1.8 {
                // User seeked manually (> 1.8s change)
                self.currentTrack?.positionSeconds = position
                lastTickTime = Date().timeIntervalSince1970
                if position < 1.0 { hasPassedIntro = false }
                updateActiveLyric(position: position, force: true)
            } else if diff > 0.6 {
                // Poller is ahead of local clock, gently advance
                self.currentTrack?.positionSeconds = position
                updateActiveLyric(position: position)
            } else {
                // Monotonic forward progression: do not snap backwards on AppleScript/notification latency!
                updateActiveLyric(position: curPos)
            }
        }

        handleSmartPlaybackTrigger(isPlaying: isPlaying)
    }

    // MARK: - Helper Text
    var hasActiveMusic: Bool {
        currentTrack != nil
    }

    var isIntroOrInterlude: Bool {
        guard !lyrics.isEmpty, let track = currentTrack else { return false }
        if hasPassedIntro { return false }
        let effectivePos = track.positionSeconds + syncOffsetSeconds + nextLyricLeadSeconds
        if let first = lyrics.first, effectivePos < first.timeSeconds {
            return true
        }
        return false
    }

    var currentLyricDisplayKey: String {
        guard let track = currentTrack else { return "empty" }
        let base = "\(track.title)_\(track.artist)"
        if isIntroOrInterlude {
            return "\(base)_intro"
        }
        return "\(base)_\(activeLyricIndex)"
    }

    var currentLyricText: String {
        guard let track = currentTrack else {
            return appLanguage == .english ? "No music playing" : "Tidak ada musik yang diputar"
        }
        if !lyrics.isEmpty && !isIntroOrInterlude && lyrics.indices.contains(activeLyricIndex) {
            let line = lyrics[activeLyricIndex].text.trimmingCharacters(in: .whitespaces)
            return line.isEmpty ? "♪ …" : line
        }
        return "\(track.title) • \(track.artist)"
    }

    var menuBarLyricText: String {
        guard let track = currentTrack else {
            return "Dynatify"
        }
        let icon = track.isPlaying ? "♫" : "⏸"
        if !lyrics.isEmpty && !isIntroOrInterlude && lyrics.indices.contains(activeLyricIndex) {
            let line = lyrics[activeLyricIndex].text.trimmingCharacters(in: .whitespaces)
            if !line.isEmpty {
                let maxLen = 42
                let cleanLine = line.count > maxLen ? String(line.prefix(maxLen - 1)) + "…" : line
                return "\(cleanLine)  \(icon)"
            }
        }
        let titleArtist = "\(track.title) • \(track.artist)"
        let maxLen = 35
        let clean = titleArtist.count > maxLen ? String(titleArtist.prefix(maxLen - 1)) + "…" : titleArtist
        return "\(clean)  \(icon)"
    }

    var nextLyricText: String? {
        guard !lyrics.isEmpty else { return nil }
        let nextIndex = activeLyricIndex + 1
        guard lyrics.indices.contains(nextIndex) else { return nil }
        let text = lyrics[nextIndex].text.trimmingCharacters(in: .whitespaces)
        return text.isEmpty ? nil : text
    }

    // MARK: - Adaptive Width Calculation
    func recomputeCompactWidth() {
        let maxAllowed = CGFloat(max(260, customCompactWidth))

        if !isAdaptiveWidth {
            if currentCompactWidth != maxAllowed {
                withIslandAnimation { self.currentCompactWidth = maxAllowed }
            }
            return
        }

        // Base padding (artwork 30 + visualizer 28 + spacing & margins = ~100pt)
        let baseChrome: CGFloat = 105
        let text = currentLyricText as NSString
        let font = NSFont.systemFont(ofSize: 13, weight: .medium)
        let textSize = text.size(withAttributes: [.font: font])
        let computed = baseChrome + textSize.width + 24

        let target = max(260, min(computed, maxAllowed))
        if abs(currentCompactWidth - target) > 3 {
            withIslandAnimation {
                self.currentCompactWidth = target
            }
        }
    }

    func setCustomCompactWidth(_ width: Double) {
        customCompactWidth = width
        UserDefaults.standard.set(width, forKey: "customCompactWidth")
        recomputeCompactWidth()
    }

    func setIsAdaptiveWidth(_ adaptive: Bool) {
        isAdaptiveWidth = adaptive
        UserDefaults.standard.set(adaptive, forKey: "isAdaptiveWidth")
        recomputeCompactWidth()
    }

    // MARK: - High-Precision 50ms Real-Time Interpolation (Zero Delay)
    private func startHighPrecisionTimer() {
        lastTickTime = Date().timeIntervalSince1970
        highPrecisionTimer = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tickInterpolation()
            }
    }

    private func tickInterpolation() {
        let now = Date().timeIntervalSince1970
        let delta = now - lastTickTime
        lastTickTime = now

        guard let track = currentTrack, track.isPlaying else { return }

        // Advance playback position in real time
        let newPos = track.positionSeconds + delta
        currentTrack?.positionSeconds = newPos
        updateActiveLyric(position: newPos)
    }

    // MARK: - Monitoring (0.7s Background Sync)
    func startMonitoring() {
        pollingTask = Task {
            while !Task.isCancelled {
                if !isDemoMode {
                    await fetchActivePlayerState()
                }
                try? await Task.sleep(for: .milliseconds(700))
            }
        }
    }

    func stopMonitoring() {
        pollingTask?.cancel()
    }

    // MARK: - Fetch Real Player State
    func fetchActivePlayerState() async {
        let result = await playerService.getCurrentTrack()
        switch result {
        case .success(let track):
            isMusicConnected = true
            let trackKey = "\(track.title)|\(track.artist)"

            if trackKey != lastTrackKey {
                // New track detected
                lastTrackKey = trackKey
                hasPassedIntro = false
                currentTrack = track
                await fetchLyrics(for: track)
                recomputeCompactWidth()
            } else {
                let curPos = currentTrack?.positionSeconds ?? 0
                let polledPos = track.positionSeconds
                let diff = polledPos - curPos
                let isPlaying = track.isPlaying

                if !isPlaying {
                    currentTrack?.positionSeconds = polledPos
                    updateActiveLyric(position: polledPos, force: true)
                } else if abs(diff) > 1.8 {
                    // Genuine user seek (> 1.8s) forward or backward
                    currentTrack?.positionSeconds = polledPos
                    lastTickTime = Date().timeIntervalSince1970
                    if polledPos < 1.0 { hasPassedIntro = false }
                    updateActiveLyric(position: polledPos, force: true)
                } else if diff > 0.6 {
                    // Poller is ahead of local clock, gently advance
                    currentTrack?.positionSeconds = polledPos
                    updateActiveLyric(position: polledPos)
                } else {
                    // Continuous playback: local 50ms clock is authoritative. Never drag backwards!
                    updateActiveLyric(position: curPos)
                }

                currentTrack?.durationSeconds = track.durationSeconds
                currentTrack?.isPlaying = track.isPlaying
                currentTrack?.volume = track.volume
                if currentTrack?.albumArt == nil && track.albumArt != nil {
                    currentTrack?.albumArt = track.albumArt
                }
            }

            handleSmartPlaybackTrigger(isPlaying: currentTrack?.isPlaying == true)

        case .failure:
            let isRunning = MusicPlayerService.isSpotifyRunning || MusicPlayerService.isAppleMusicRunning
            if !isRunning {
                isMusicConnected = false
                currentTrack = nil
                lyrics = []
                lastTrackKey = ""
                hasPassedIntro = false
                recomputeCompactWidth()
                handleSmartPlaybackTrigger(isPlaying: false)
            } else {
                // Keep existing track if player is still running (prevent flickering on transient AppleScript glitches)
                isMusicConnected = (currentTrack != nil)
            }
        }
    }

    // MARK: - Smart Auto-Trigger (Auto-Show & Auto-Hide on Pause)
    private func handleSmartPlaybackTrigger(isPlaying: Bool) {
        if isPlaying {
            // Cancel any pending pause timer
            pauseAutoHideTask?.cancel()
            pauseAutoHideTask = nil

            // Auto-show if enabled, master is active, and currently hidden
            if autoShowOnPlay && isIslandActive && !isIslandVisible {
                withIslandAnimation {
                    self.isIslandVisible = true
                }
            }
        } else {
            // Paused: if autoHideOnPause is enabled and island is visible, start countdown
            if autoHideOnPause && isIslandVisible && pauseAutoHideTask == nil && autoHideTimeoutSeconds > 0 {
                let delay = autoHideTimeoutSeconds
                pauseAutoHideTask = Task { @MainActor in
                    try? await Task.sleep(for: .seconds(delay))
                    if !Task.isCancelled {
                        // If still paused or no active music, hide island
                        if self.currentTrack?.isPlaying != true {
                            withIslandAnimation {
                                self.isIslandVisible = false
                            }
                        }
                    }
                    self.pauseAutoHideTask = nil
                }
            }
        }
    }

    // MARK: - Lyrics
    private func fetchLyrics(for track: Track) async {
        let result = await lyricsService.fetchLyrics(
            title: track.title,
            artist: track.artist,
            durationSeconds: track.durationSeconds
        )
        switch result {
        case .success(let lines):
            self.lyrics = lines
            self.activeLyricIndex = 0
            self.hasPassedIntro = false
            self.updateActiveLyric(position: track.positionSeconds, force: true)
        case .failure:
            self.lyrics = []
            self.activeLyricIndex = 0
            self.hasPassedIntro = false
        }
        recomputeCompactWidth()
    }

    func updateActiveLyric(position: Double, force: Bool = false) {
        guard !lyrics.isEmpty else { return }
        // Effective position includes sync offset AND early lookahead lead time for the next lyric
        let adjustedPosition = max(0, position + syncOffsetSeconds + nextLyricLeadSeconds)

        if let first = lyrics.first {
            if adjustedPosition >= first.timeSeconds {
                hasPassedIntro = true
            } else if position < 1.0 {
                hasPassedIntro = false
            }
        }

        var candidateIdx = 0
        for (i, line) in lyrics.enumerated() {
            if line.timeSeconds <= adjustedPosition {
                candidateIdx = i
            } else {
                break
            }
        }

        let targetIdx: Int
        if currentTrack?.isPlaying == true && !force {
            targetIdx = max(activeLyricIndex, candidateIdx)
        } else {
            targetIdx = candidateIdx
        }

        if targetIdx != activeLyricIndex || force {
            activeLyricIndex = targetIdx
            recomputeCompactWidth()
        }
    }

    func setNextLyricLeadSeconds(_ seconds: Double) {
        let clamped = max(0.0, min(seconds, 3.0))
        self.nextLyricLeadSeconds = clamped
        UserDefaults.standard.set(clamped, forKey: "nextLyricLeadSeconds")
        if let track = currentTrack {
            updateActiveLyric(position: track.positionSeconds, force: true)
        }
    }

    // MARK: - 3 Pillars & Control Actions (Dynatify)
    func setIslandActive(_ active: Bool) {
        withIslandAnimation {
            self.isIslandActive = active
            if active {
                self.isIslandVisible = true
            } else {
                self.isIslandVisible = false
            }
        }
        UserDefaults.standard.set(active, forKey: "isIslandActive")
    }

    func toggleIsland() {
        guard isIslandActive else {
            setIslandActive(true)
            return
        }
        withIslandAnimation {
            self.isIslandVisible.toggle()
        }
    }

    func setAutoHideOnPause(_ enable: Bool) {
        self.autoHideOnPause = enable
        UserDefaults.standard.set(enable, forKey: "autoHideOnPause")
        if !enable {
            pauseAutoHideTask?.cancel()
            pauseAutoHideTask = nil
        }
    }

    func setAutoShowOnPlay(_ enable: Bool) {
        self.autoShowOnPlay = enable
        UserDefaults.standard.set(enable, forKey: "autoShowOnPlay")
    }

    func setAutoHideTimeoutSeconds(_ seconds: Double) {
        self.autoHideTimeoutSeconds = seconds
        UserDefaults.standard.set(seconds, forKey: "autoHideTimeoutSeconds")
    }

    func setShowDockIcon(_ show: Bool) {
        self.showDockIcon = show
        UserDefaults.standard.set(show, forKey: "showDockIcon")
        NSApp.setActivationPolicy(show ? .regular : .accessory)
        if show {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func setSyncOffset(seconds: Double) {
        self.syncOffsetSeconds = seconds
        UserDefaults.standard.set(seconds, forKey: "syncOffsetSeconds")
        if let track = currentTrack {
            updateActiveLyric(position: track.positionSeconds, force: true)
        }
    }

    // Quick Action 1: Test Island Animation
    func testIslandAnimation() {
        guard isIslandActive else {
            isIslandActive = true
            isIslandVisible = true
            return
        }
        withIslandAnimation {
            self.isIslandVisible = true
            self.islandState = .expanded
        }
        Task {
            try? await Task.sleep(for: .milliseconds(2500))
            withIslandAnimation {
                self.islandState = .compact
            }
        }
    }

    // Quick Action 2: Reset Island Position
    func resetIslandPosition() {
        recomputeCompactWidth()
    }

    // MARK: - Controls (Real Playback)
    func playPause() {
        currentTrack?.isPlaying.toggle()
        Task {
            await playerService.sendCommand(.playPause)
            try? await Task.sleep(for: .milliseconds(250))
            await fetchActivePlayerState()
        }
    }

    func nextTrack() {
        Task {
            await playerService.sendCommand(.next)
            try? await Task.sleep(for: .milliseconds(350))
            await fetchActivePlayerState()
        }
    }

    func previousTrack() {
        Task {
            await playerService.sendCommand(.previous)
            try? await Task.sleep(for: .milliseconds(350))
            await fetchActivePlayerState()
        }
    }

    func seek(to fraction: Double) {
        guard let track = currentTrack, track.durationSeconds > 0 else { return }
        let newPos = max(0, min(fraction * track.durationSeconds, track.durationSeconds))
        currentTrack?.positionSeconds = newPos
        lastTickTime = Date().timeIntervalSince1970
        if newPos < 1.0 { hasPassedIntro = false }
        updateActiveLyric(position: newPos, force: true)
        recomputeCompactWidth()

        Task {
            await playerService.seek(toSeconds: newPos)
        }
    }

    func setVolume(to volume: Double) {
        currentTrack?.volume = volume
        Task {
            await playerService.setVolume(to: volume)
        }
    }

    // MARK: - Style & Theme Switchers
    func setIslandStyle(_ style: IslandStyle) {
        withIslandAnimation {
            self.islandStyle = style
        }
        UserDefaults.standard.set(style.rawValue, forKey: "islandStyle")
        recomputeCompactWidth()
    }

    func setVisualizerTheme(_ theme: VisualizerTheme) {
        withIslandAnimation {
            self.visualizerTheme = theme
        }
        UserDefaults.standard.set(theme.rawValue, forKey: "visualizerTheme")
    }

    func setDisplayLocationMode(_ mode: DisplayLocationMode) {
        withIslandAnimation {
            self.displayLocationMode = mode
        }
        UserDefaults.standard.set(mode.rawValue, forKey: "displayLocationMode")
    }

    func setAppearanceMode(_ mode: AppearanceMode) {
        withIslandAnimation {
            self.appearanceMode = mode
        }
        UserDefaults.standard.set(mode.rawValue, forKey: "appearanceMode")
    }

    func setAppLanguage(_ lang: AppLanguage) {
        withIslandAnimation {
            self.appLanguage = lang
        }
        UserDefaults.standard.set(lang.rawValue, forKey: "appLanguage")
    }

    // MARK: - Adaptive Dark & Light Styling Tokens
    var isEffectiveDarkMode: Bool {
        switch appearanceMode {
        case .auto:
            return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        case .dark:
            return true
        case .light:
            return false
        }
    }

    var islandTextColor: Color {
        isEffectiveDarkMode ? Color.white.opacity(0.95) : Color.black.opacity(0.90)
    }

    var islandSecondaryTextColor: Color {
        isEffectiveDarkMode ? Color.white.opacity(0.55) : Color.black.opacity(0.55)
    }

    var islandGlassBackground: Color {
        isEffectiveDarkMode ? Color.black.opacity(0.85) : Color.white.opacity(0.88)
    }

    var islandSubtleFill: Color {
        isEffectiveDarkMode ? Color.white.opacity(0.12) : Color.black.opacity(0.06)
    }

    var islandBorderGradient: LinearGradient {
        if isEffectiveDarkMode {
            return LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.20), location: 0),
                    .init(color: .white.opacity(0.04), location: 0.4),
                    .init(color: .black.opacity(0.20), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.85), location: 0),
                    .init(color: .black.opacity(0.05), location: 0.4),
                    .init(color: .black.opacity(0.18), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    var islandShadowColor: Color {
        isEffectiveDarkMode ? Color.black.opacity(0.38) : Color.black.opacity(0.14)
    }

    // MARK: - Auto Update Engine
    func checkForUpdates(manual: Bool = false) {
        guard !isCheckingForUpdates else { return }
        isCheckingForUpdates = true
        updateStatusMessage = "Memeriksa pembaruan..."

        Task {
            do {
                guard let url = URL(string: "https://api.github.com/repos/uwayxt/Dynatify/releases/latest") else {
                    self.isCheckingForUpdates = false
                    return
                }
                var req = URLRequest(url: url)
                req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
                req.setValue("Dynatify-App", forHTTPHeaderField: "User-Agent")
                req.timeoutInterval = 8.0

                let (data, response) = try await URLSession.shared.data(for: req)
                guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 else {
                    self.isCheckingForUpdates = false
                    self.updateStatusMessage = "Dynatify versi v\(Self.appVersion) adalah versi stabil terbaru."
                    return
                }

                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let tagName = json["tag_name"] as? String {
                    let cleanTag = tagName.replacingOccurrences(of: "v", with: "").trimmingCharacters(in: .whitespaces)
                    let current = Self.appVersion

                    self.latestVersion = cleanTag
                    self.updateReleaseNotes = (json["body"] as? String) ?? "Pembaruan stabilitas dan performa Dynatify."
                    if let htmlUrl = json["html_url"] as? String, let u = URL(string: htmlUrl) {
                        self.updateDownloadURL = u
                    } else {
                        self.updateDownloadURL = URL(string: "https://github.com/uwayxt/Dynatify/releases")
                    }

                    if cleanTag.compare(current, options: .numeric) == .orderedDescending {
                        self.isUpdateAvailable = true
                        self.updateStatusMessage = "Pembaruan v\(cleanTag) tersedia!"
                    } else {
                        self.isUpdateAvailable = false
                        self.updateStatusMessage = "Dynatify sudah dalam versi terbaru (v\(current))."
                    }
                }
                self.lastUpdateCheckDate = Date()
                self.isCheckingForUpdates = false
            } catch {
                self.isCheckingForUpdates = false
                self.updateStatusMessage = manual ? "Gagal memeriksa pembaruan: periksa koneksi." : "Dynatify v\(Self.appVersion) up to date."
            }
        }
    }

    // MARK: - State helpers
    func expand() {
        guard islandState != .expanded else { return }
        withIslandAnimation { self.islandState = .expanded }
    }

    func collapse() {
        guard islandState != .compact else { return }
        withIslandAnimation { self.islandState = .compact }
    }

    // MARK: - Diagnostics
    func testMusicPlayerConnection() async -> (success: Bool, message: String) {
        let spotifyOn = MusicPlayerService.isSpotifyRunning
        let musicOn = MusicPlayerService.isAppleMusicRunning

        if !spotifyOn && !musicOn {
            return (false, "Spotify dan Apple Music belum dibuka. Buka salah satu aplikasi pemutar lalu putar lagu.")
        }
        let result = await playerService.getCurrentTrack()
        switch result {
        case .success(let track):
            let player = track.playerSource.rawValue
            let status = track.isPlaying ? "Sedang Memutar" : "Dijeda (Paused)"
            return (true, "Terhubung ke \(player)! Status: \(status) • '\(track.title)' oleh \(track.artist) (Posisi: \(Int(track.positionSeconds))s / \(Int(track.durationSeconds))s).")
        case .failure(let err):
            return (false, "Pemutar musik terdeteksi namun tidak ada lagu aktif: \(err.localizedDescription)")
        }
    }
}

// MARK: - Animation Helper
func withIslandAnimation(_ block: @escaping () -> Void) {
    withAnimation(.spring(response: 0.35, dampingFraction: 0.78, blendDuration: 0.1)) {
        block()
    }
}
