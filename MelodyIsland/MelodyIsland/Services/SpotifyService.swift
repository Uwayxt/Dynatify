import Foundation
import AppKit

// MARK: - Active Music Player Source
enum MusicPlayerSource: String, Codable {
    case spotify = "Spotify"
    case appleMusic = "Apple Music"
}

// MARK: - Playback Command
enum PlaybackCommand {
    case playPause, next, previous
}

// MARK: - Unified Music Player Service (Spotify & Apple Music)
actor MusicPlayerService {

    private var lastArtURL: URL?
    private var cachedAlbumArt: NSImage?
    private(set) var activeSource: MusicPlayerSource = .spotify

    private var lastValidTrack: Track?

    func setCachedTrack(_ track: Track) {
        self.lastValidTrack = track
    }

    // MARK: - Running App Checks
    static var isSpotifyRunning: Bool {
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: "com.spotify.client").first else {
            return false
        }
        return !app.isTerminated
    }

    static var isAppleMusicRunning: Bool {
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").first else {
            return false
        }
        return !app.isTerminated
    }

    // MARK: - Fetch Current Track
    func getCurrentTrack() async -> Result<Track, Error> {
        return await Task.detached(priority: .userInitiated) { [weak self] () -> Result<Track, Error> in
            let spotifyActive = Self.isSpotifyRunning
            let musicActive = Self.isAppleMusicRunning

            guard spotifyActive || musicActive else {
                return .failure(PlayerError.noPlayerRunning)
            }

            // 1. Try reading user-session bridge state if available
            if let bridgeTrack = await self?.readStateBridge() {
                if let strongSelf = self {
                    await strongSelf.setCachedTrack(bridgeTrack)
                }
                return .success(bridgeTrack)
            }

            var script = ""
            if Self.isSpotifyRunning {
                script = """
                tell application "Spotify"
                    set pState to (player state as string)
                    if pState is not "stopped" then
                        set tName to name of current track
                        set tArtist to artist of current track
                        set tAlbum to album of current track
                        set tDur to (duration of current track) / 1000
                        set tPos to player position
                        set tVol to sound volume
                        set isPlaying to (pState is "playing")
                        set artURL to ""
                        try
                            set artURL to artwork url of current track
                        end try
                        return "SPOTIFY|||" & tName & "|||" & tArtist & "|||" & tAlbum & "|||" & (tDur as string) & "|||" & (tPos as string) & "|||" & (isPlaying as string) & "|||" & artURL & "|||" & (tVol as string)
                    end if
                end tell
                return "NONE"
                """
            } else if Self.isAppleMusicRunning {
                script = """
                tell application "Music"
                    set pState to (player state as string)
                    if pState is not "stopped" then
                        set tTrack to current track
                        set tName to name of tTrack
                        set tArtist to artist of tTrack
                        set tAlbum to album of tTrack
                        set tDur to duration of tTrack
                        set tPos to player position
                        set tVol to sound volume
                        set isPlaying to (pState is "playing")
                        return "APPLE_MUSIC|||" & tName & "|||" & tArtist & "|||" & tAlbum & "|||" & (tDur as string) & "|||" & (tPos as string) & "|||" & (isPlaying as string) & "||||||" & (tVol as string)
                    end if
                end tell
                return "NONE"
                """
            } else {
                return .failure(PlayerError.noPlayerRunning)
            }

            var raw = ""
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                let result = appleScript.executeAndReturnError(&error)
                if error == nil, let val = result.stringValue {
                    raw = val
                }
            }

            // Fallback to /usr/bin/osascript process if NSAppleScript encountered error or -1743 permission block
            if raw.isEmpty || raw == "NONE" {
                if let fallback = Self.runOsascript(script: script), !fallback.isEmpty {
                    raw = fallback
                }
            }

            if raw == "NONE" || raw.isEmpty {
                // If AppleScript returned empty/blocked but player is active, use last known track
                if let cached = await self?.lastValidTrack {
                    return .success(cached)
                }
                return .failure(PlayerError.noMusicPlaying)
            }

            let parts = raw.components(separatedBy: "|||")
            guard parts.count >= 8 else {
                if let cached = await self?.lastValidTrack {
                    return .success(cached)
                }
                return .failure(PlayerError.parseFailed)
            }

            let playerType = parts[0] == "APPLE_MUSIC" ? MusicPlayerSource.appleMusic : MusicPlayerSource.spotify
            let title = parts[1].trimmingCharacters(in: .whitespaces)
            let artist = parts[2].trimmingCharacters(in: .whitespaces)
            let album = parts[3].trimmingCharacters(in: .whitespaces)

            // Resilient decimal parsing (replacing comma with dot for Indonesian/European macOS locales)
            let duration = Self.parseNumber(parts[4])
            let position = Self.parseNumber(parts[5])
            let isPlaying = parts[6].trimmingCharacters(in: .whitespaces).lowercased() == "true"
            let artURLString = parts[7].trimmingCharacters(in: .whitespaces)
            let artURL = URL(string: artURLString)
            let volume = parts.count >= 9 ? Self.parseNumber(parts[8]) : 80.0

            var artImage: NSImage? = nil
            if let strongSelf = self {
                if let artURL = artURL {
                    artImage = await strongSelf.loadAlbumArt(for: artURL)
                }
                if artImage == nil {
                    artImage = await Self.fetchAlbumArtFromiTunes(title: title, artist: artist)
                }
            }

            let track = Track(
                title: title,
                artist: artist,
                album: album,
                durationSeconds: duration,
                positionSeconds: position,
                isPlaying: isPlaying,
                volume: volume,
                albumArtURL: artURL,
                albumArt: artImage,
                playerSource: playerType
            )

            if let strongSelf = self {
                await strongSelf.setActiveSource(playerType)
                await strongSelf.setCachedTrack(track)
            }

            return .success(track)
        }.value
    }

    // MARK: - State Bridge Reader
    private func readStateBridge() async -> Track? {
        let statePath = "/tmp/dynatify_state.json"
        guard FileManager.default.fileExists(atPath: statePath),
              let data = try? Data(contentsOf: URL(fileURLWithPath: statePath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        if let stopped = json["stopped"] as? Bool, stopped {
            return nil
        }

        guard let title = json["title"] as? String, !title.isEmpty,
              let artist = json["artist"] as? String else {
            return nil
        }

        let album = (json["album"] as? String) ?? ""
        let duration = (json["duration"] as? Double) ?? 0.0
        let position = (json["position"] as? Double) ?? 0.0
        let isPlaying = (json["isPlaying"] as? Bool) ?? false
        let volume = (json["volume"] as? Double) ?? 80.0
        let sourceStr = (json["source"] as? String) ?? "Spotify"
        let source: MusicPlayerSource = (sourceStr == "Apple Music") ? .appleMusic : .spotify
        let artURLStr = (json["artworkURL"] as? String) ?? ""
        let artURL = URL(string: artURLStr)

        var artImage: NSImage? = nil
        if let artURL = artURL {
            artImage = await loadAlbumArt(for: artURL)
        }
        if artImage == nil {
            artImage = await Self.fetchAlbumArtFromiTunes(title: title, artist: artist)
        }

        return Track(
            title: title,
            artist: artist,
            album: album,
            durationSeconds: duration,
            positionSeconds: position,
            isPlaying: isPlaying,
            volume: volume,
            albumArtURL: artURL,
            albumArt: artImage,
            playerSource: source
        )
    }

    private func setActiveSource(_ src: MusicPlayerSource) {
        self.activeSource = src
    }

    private func loadAlbumArt(for url: URL) async -> NSImage? {
        if url == lastArtURL, let cached = cachedAlbumArt {
            return cached
        }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let img = NSImage(data: data) else {
            return nil
        }
        self.lastArtURL = url
        self.cachedAlbumArt = img
        return img
    }

    // MARK: - High-Res iTunes Album Art Fallback
    static func fetchAlbumArtFromiTunes(title: String, artist: String) async -> NSImage? {
        let cleanTitle = title.components(separatedBy: "(").first?.components(separatedBy: "-").first?.trimmingCharacters(in: .whitespaces) ?? title
        let query = "\(cleanTitle) \(artist)"
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://itunes.apple.com/search?term=\(encoded)&entity=song&limit=1") else {
            return nil
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = json["results"] as? [[String: Any]],
               let first = results.first,
               let artStr = first["artworkUrl100"] as? String {
                let highResStr = artStr.replacingOccurrences(of: "100x100bb.jpg", with: "600x600bb.jpg")
                if let artURL = URL(string: highResStr),
                   let (imgData, _) = try? await URLSession.shared.data(from: artURL),
                   let img = NSImage(data: imgData) {
                    return img
                }
            }
        } catch {}
        return nil
    }

    // MARK: - Playback Commands
    func sendCommand(_ command: PlaybackCommand) async {
        let appName = (activeSource == .appleMusic) ? "Music" : "Spotify"
        let action: String
        let cmdName: String
        switch command {
        case .playPause: action = "playpause"; cmdName = "playpause"
        case .next: action = "next track"; cmdName = "next"
        case .previous: action = "previous track"; cmdName = "previous"
        }
        let script = "tell application \"\(appName)\" to \(action)"
        await Task.detached(priority: .userInitiated) {
            Self.executeScript(script)
            try? cmdName.write(toFile: "/tmp/dynatify_cmd", atomically: true, encoding: .utf8)
        }.value
    }

    // MARK: - Seek to Position
    func seek(toSeconds pos: Double) async {
        let appName = (activeSource == .appleMusic) ? "Music" : "Spotify"
        let posStr = String(format: "%.2f", locale: Locale(identifier: "en_US"), pos)
        let script = "tell application \"\(appName)\" to set player position to \(posStr)"
        await Task.detached(priority: .userInitiated) {
            Self.executeScript(script)
            try? "seek:\(posStr)".write(toFile: "/tmp/dynatify_cmd", atomically: true, encoding: .utf8)
        }.value
    }

    // MARK: - Volume Control
    func setVolume(to volume: Double) async {
        let appName = (activeSource == .appleMusic) ? "Music" : "Spotify"
        let volInt = Int(max(0, min(volume, 100)))
        let script = "tell application \"\(appName)\" to set sound volume to \(volInt)"
        await Task.detached(priority: .userInitiated) {
            Self.executeScript(script)
            try? "vol:\(volInt)".write(toFile: "/tmp/dynatify_cmd", atomically: true, encoding: .utf8)
        }.value
    }

    // MARK: - Script Execution with Fallback
    static func executeScript(_ script: String) {
        var err: NSDictionary?
        let res = NSAppleScript(source: script)?.executeAndReturnError(&err)
        if err != nil || res == nil {
            _ = runOsascript(script: script)
        }
    }

    static func runOsascript(script: String) -> String? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        p.arguments = ["-e", script]
        let pipe = Pipe()
        let errPipe = Pipe()
        p.standardOutput = pipe
        p.standardError = errPipe
        do {
            try p.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            p.waitUntilExit()
            let result = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let errStr = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let msg = "exitCode: \(p.terminationStatus), stdout: '\(result ?? "")', stderr: '\(errStr)'\n"
            try? msg.write(toFile: "/tmp/dynatify_debug.log", atomically: true, encoding: .utf8)
            return result
        } catch {
            let msg = "runOsascript error: \(error)\n"
            try? msg.write(toFile: "/tmp/dynatify_debug.log", atomically: true, encoding: .utf8)
            return nil
        }
    }

    // MARK: - Helper: Parse float across all locales
    static func parseNumber(_ str: String) -> Double {
        let clean = str.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        return Double(clean) ?? 0.0
    }
}

// MARK: - Errors
enum PlayerError: LocalizedError {
    case noPlayerRunning
    case noMusicPlaying
    case scriptFailed(String)
    case parseFailed

    var errorDescription: String? {
        switch self {
        case .noPlayerRunning: return "Spotify atau Apple Music tidak sedang dibuka."
        case .noMusicPlaying: return "Tidak ada lagu yang sedang diputar."
        case .scriptFailed(let msg): return "AppleScript error: \(msg)"
        case .parseFailed: return "Gagal membaca data dari pemutar musik."
        }
    }
}
