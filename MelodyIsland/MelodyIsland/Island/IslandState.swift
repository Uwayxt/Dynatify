import Foundation
import SwiftUI

/// The state machine driving island morphing.
enum IslandState: Equatable {
    case closed        // Tiny pill — only pulse dot
    case compact       // Pill format (according to selected IslandStyle)
    case expanded      // Full lyrics & controls HUD
    case dragging      // User repositioning
}

/// Location mode for where lyrics and player are displayed.
enum DisplayLocationMode: String, CaseIterable, Identifiable, Codable {
    case both          = "both"            // Keduanya: Dynamic Island & Top Bar Menu Bar
    case islandOnly    = "island_only"     // Hanya di Dynamic Island (Notch)
    case menuBarOnly   = "menu_bar_only"   // Hanya di Top Bar Menu Bar (Minimalis Layar Bersih)

    var id: String { rawValue }

    var title: String {
        switch self {
        case .both:        return "Keduanya Aktif (Island & Top Bar)"
        case .islandOnly:  return "Hanya Dynamic Island (Notch)"
        case .menuBarOnly: return "Hanya Top Bar (Menu Bar Saja)"
        }
    }

    var subtitle: String {
        switch self {
        case .both:        return "Lirik tampil di notch Dynamic Island sekaligus di Menu Bar atas"
        case .islandOnly:  return "Tampilan eksklusif di bawah notch MacBook Anda"
        case .menuBarOnly: return "Lirik berjalan di Menu Bar atas, notch island disembunyikan"
        }
    }

    var icon: String {
        switch self {
        case .both:        return "rectangle.split.2x1.fill"
        case .islandOnly:  return "macbook"
        case .menuBarOnly: return "menubar.rectangle"
        }
    }
}

/// Layout presets for the compact Dynamic Island.
enum IslandStyle: String, CaseIterable, Identifiable, Codable {
    case directLyrics    = "direct_lyrics"    // Versi 1: Direct Lyric Stream (Screenshot style)
    case splitDual        = "split_dual"        // Versi 2: Dual Island (Pill + Detached Circle)
    case classic          = "classic"           // Versi 3: Classic Track & Artist Info
    case compactMinimal   = "compact_minimal"   // Versi 4: Ultra Minimalist Pill
    case karaokeTicker    = "karaoke_ticker"    // Versi 5: Marquee Glow Bar

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .directLyrics:  return "Versi 1: Live Lyrics Stream"
        case .splitDual:     return "Versi 2: Dual Island (Split Bubble)"
        case .classic:       return "Versi 3: Info Lagu Klasik"
        case .compactMinimal: return "Versi 4: Minimalist Pill"
        case .karaokeTicker: return "Versi 5: Marquee Glow Bar"
        }
    }

    var subtitle: String {
        switch self {
        case .directLyrics:  return "Lirik lagu aktif langsung di baris pil seperti mockup"
        case .splitDual:     return "Kapsul ganda terpisah ala iPhone Dynamic Island"
        case .classic:       return "Cover album, judul lagu, dan nama artis elegan"
        case .compactMinimal: return "Ukuran sangat hemat layar untuk mode deep work"
        case .karaokeTicker: return "Lirik berjalan dengan specular ambient glow"
        }
    }

    var defaultWidth: CGFloat {
        switch self {
        case .directLyrics:  return 360
        case .splitDual:     return 380
        case .classic:       return 260
        case .compactMinimal: return 180
        case .karaokeTicker: return 340
        }
    }

    var defaultHeight: CGFloat {
        switch self {
        case .directLyrics:  return 46
        case .splitDual:     return 46
        case .classic:       return 46
        case .compactMinimal: return 38
        case .karaokeTicker: return 44
        }
    }
}

/// Visualizer color theme options.
enum VisualizerTheme: String, CaseIterable, Identifiable, Codable {
    case amberGold    = "amber_gold"     // Amber / Sunset orange (like user's screenshot)
    case spotifyGreen = "spotify_green"  // Iconic Spotify Green (#1DB954)
    case neonPurple   = "neon_purple"    // Cyberpunk Magenta/Purple
    case electricCyan = "electric_cyan"  // Modern Cyan Blue
    case pureWhite    = "pure_white"     // Minimalist White

    var id: String { rawValue }

    var title: String {
        switch self {
        case .amberGold:    return "Amber Sunset"
        case .spotifyGreen: return "Spotify Emerald"
        case .neonPurple:   return "Neon Magenta"
        case .electricCyan: return "Electric Cyan"
        case .pureWhite:    return "Pure White"
        }
    }

    var color: Color {
        switch self {
        case .amberGold:    return Color(hex: "#FF9F0A")
        case .spotifyGreen: return Color(hex: "#1DB954")
        case .neonPurple:   return Color(hex: "#BF5AF2")
        case .electricCyan: return Color(hex: "#64D2FF")
        case .pureWhite:    return Color.white
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Convenient Extensions
extension IslandStyle {
    var iconName: String {
        switch self {
        case .directLyrics:   return "music.mic"
        case .splitDual:      return "rectangle.split.2x1"
        case .classic:        return "music.quarternote.3"
        case .compactMinimal: return "capsule"
        case .karaokeTicker:  return "waveform.and.person.filled"
        }
    }

    var description: String {
        subtitle
    }
}

extension DisplayLocationMode {
    var description: String {
        subtitle
    }
}

// MARK: - App Language (English Default & Indonesian)
enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case english    = "en"
    case indonesian = "id"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:    return "English (Default)"
        case .indonesian: return "Bahasa Indonesia"
        }
    }

    var flag: String {
        switch self {
        case .english:    return "🇺🇸"
        case .indonesian: return "🇮🇩"
        }
    }
}

// MARK: - Appearance Mode (Adaptive Dark & Light Mode)
enum AppearanceMode: String, CaseIterable, Identifiable, Codable {
    case auto   = "auto"
    case dark   = "dark"
    case light  = "light"

    var id: String { rawValue }

    var title: String {
        title(for: .english)
    }

    var subtitle: String {
        subtitle(for: .english)
    }

    func title(for lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.auto, .english):    return "Auto (System Sync)"
        case (.auto, .indonesian): return "Auto (Ikuti Sistem macOS)"
        case (.dark, .english):    return "Dark Mode (Notch Onyx)"
        case (.dark, .indonesian): return "Mode Gelap (Notch Onyx)"
        case (.light, .english):   return "Light Mode (Liquid Pearl)"
        case (.light, .indonesian):return "Mode Terang (Liquid Pearl)"
        }
    }

    func subtitle(for lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.auto, .english):    return "Dynamically adapts to your macOS Dark or Light theme in real time"
        case (.auto, .indonesian): return "Menyesuaikan otomatis dengan tema terang atau gelap macOS Anda"
        case (.dark, .english):    return "Deep onyx glass that seamlessly blends with the physical MacBook notch"
        case (.dark, .indonesian): return "Kaca onyx hitam pekat yang menyatu mulus dengan notch MacBook"
        case (.light, .english):   return "Liquid pearl frosted glass with crisp, ultra-high contrast dark typography"
        case (.light, .indonesian):return "Kaca pearl terang tembus pandang dengan tipografi kontras tinggi"
        }
    }

    var iconName: String {
        switch self {
        case .auto:  return "circle.lefthalf.filled"
        case .dark:  return "moon.stars.fill"
        case .light: return "sun.max.fill"
        }
    }

    var icon: String {
        iconName
    }
}

extension IslandStyle {
    func displayName(for lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.directLyrics, .english):   return "Version 1: Live Lyrics Stream"
        case (.directLyrics, .indonesian):return "Versi 1: Live Lyrics Stream"
        case (.splitDual, .english):      return "Version 2: Dual Island (Split Bubble)"
        case (.splitDual, .indonesian):   return "Versi 2: Dual Island (Split Bubble)"
        case (.classic, .english):        return "Version 3: Classic Track Info"
        case (.classic, .indonesian):     return "Versi 3: Info Lagu Klasik"
        case (.compactMinimal, .english): return "Version 4: Minimalist Pill"
        case (.compactMinimal, .indonesian): return "Versi 4: Minimalist Pill"
        case (.karaokeTicker, .english):  return "Version 5: Marquee Glow Bar"
        case (.karaokeTicker, .indonesian): return "Versi 5: Marquee Glow Bar"
        }
    }

    func subtitle(for lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.directLyrics, .english):   return "Live lyric line displayed right in the compact notch pill"
        case (.directLyrics, .indonesian):return "Lirik lagu aktif langsung di baris pil seperti mockup"
        case (.splitDual, .english):      return "Split dual capsule inspired by iPhone Dynamic Island with audio bubble"
        case (.splitDual, .indonesian):   return "Kapsul ganda terpisah ala iPhone Dynamic Island"
        case (.classic, .english):        return "Crisp album art, track title, and artist name in elegant two-row layout"
        case (.classic, .indonesian):     return "Cover album, judul lagu, dan nama artis elegan"
        case (.compactMinimal, .english): return "Ultra-slim screen footprint designed for deep work focus"
        case (.compactMinimal, .indonesian): return "Ukuran sangat hemat layar untuk mode deep work"
        case (.karaokeTicker, .english):  return "Scrolling lyric stream with specular ambient glow and next line teaser"
        case (.karaokeTicker, .indonesian): return "Lirik berjalan dengan specular ambient glow"
        }
    }
}

extension DisplayLocationMode {
    func title(for lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.both, .english):        return "Both Active (Island & Menu Bar)"
        case (.both, .indonesian):     return "Keduanya Aktif (Island & Top Bar)"
        case (.islandOnly, .english):  return "Dynamic Island Only (Notch)"
        case (.islandOnly, .indonesian):return "Hanya Dynamic Island (Notch)"
        case (.menuBarOnly, .english): return "Top Bar Only (Menu Bar Only)"
        case (.menuBarOnly, .indonesian):return "Hanya Top Bar (Menu Bar Saja)"
        }
    }

    func subtitle(for lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.both, .english):        return "Lyrics stream in Dynamic Island and top menu bar simultaneously"
        case (.both, .indonesian):     return "Lirik tampil di notch Dynamic Island sekaligus di Menu Bar atas"
        case (.islandOnly, .english):  return "Exclusive floating HUD positioned under your MacBook notch"
        case (.islandOnly, .indonesian):return "Tampilan eksklusif di bawah notch MacBook Anda"
        case (.menuBarOnly, .english): return "Lyrics stream in the macOS menu bar, keeping notch completely clear"
        case (.menuBarOnly, .indonesian):return "Lirik berjalan di Menu Bar atas, notch island disembunyikan"
        }
    }
}
