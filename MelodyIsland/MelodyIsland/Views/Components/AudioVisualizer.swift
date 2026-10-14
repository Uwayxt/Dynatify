import SwiftUI

// MARK: - Audio Visualizer (Dynamic Beat Simulation with Zero-Freeze Timeline Engine)
/// Designed natively for Dynatify • by @uwayxt
struct AudioVisualizer: View {
    var isPlaying: Bool
    var tintColor: Color = Color(hex: "#1DB954")
    var barCount: Int = 4

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.08, paused: !isPlaying)) { timeline in
            let time = isPlaying ? timeline.date.timeIntervalSinceReferenceDate : 0
            HStack(alignment: .bottom, spacing: 2.5) {
                ForEach(0..<barCount, id: \.self) { index in
                    VisualizerBarItem(
                        index: index,
                        totalBars: barCount,
                        isPlaying: isPlaying,
                        time: time,
                        tintColor: tintColor
                    )
                }
            }
            .frame(height: 16)
        }
    }
}

// MARK: - Single Visualizer Bar with Polyrhythmic Spring Physics
private struct VisualizerBarItem: View {
    let index: Int
    let totalBars: Int
    let isPlaying: Bool
    let time: Double
    let tintColor: Color

    private var targetHeight: CGFloat {
        guard isPlaying else { return 3.0 }

        // Multi-frequency harmonic simulation mimicking energetic live audio
        let baseFreq = 5.8 // ~130 BPM tempo feel
        let idx = Double(index)
        let total = Double(max(1, totalBars))

        // Phase offset per bar (staggered peaks like bass/mid/treble)
        let phase = (idx / total) * .pi * 2.2

        // Harmonic 1: Primary rhythmic beat pulse
        let h1 = sin(time * baseFreq + phase)
        // Harmonic 2: Syncopated faster flutter (high-mid / snare energy)
        let h2 = cos(time * (baseFreq * 1.45) + phase * 1.25)
        // Harmonic 3: Slow musical volume swell
        let h3 = sin(time * 2.1 + idx * 1.8)

        // Combined normalized value [0.0 ... 1.0]
        let combined = (h1 * 0.44 + h2 * 0.36 + h3 * 0.20 + 1.0) * 0.5
        let clamped = max(0.0, min(1.0, combined))

        let minHeight: CGFloat = 3.5
        let maxHeight: CGFloat = 16.0

        // Subtle bar variation: outer bars have higher dynamic swing
        let multiplier: CGFloat = (index == 0 || index == totalBars - 1) ? 1.0 : 0.92
        return minHeight + CGFloat(clamped) * (maxHeight - minHeight) * multiplier
    }

    var body: some View {
        Capsule()
            .fill(tintColor)
            .frame(width: 2.5, height: targetHeight)
            .animation(.interactiveSpring(response: 0.12, dampingFraction: 0.68), value: targetHeight)
    }
}

// MARK: - Detached Waveform Circle Bubble (Screenshot Style)
struct WaveformBubbleView: View {
    @EnvironmentObject var vm: IslandViewModel
    var isPlaying: Bool
    var tintColor: Color = Color(hex: "#FF9F0A")

    var body: some View {
        ZStack {
            Circle()
                .fill(vm.islandGlassBackground)
                .overlay {
                    Circle()
                        .strokeBorder(vm.islandBorderGradient, lineWidth: 1)
                }

            AudioVisualizer(isPlaying: isPlaying, tintColor: tintColor, barCount: 5)
        }
        .frame(width: 38, height: 38)
        .shadow(color: vm.islandShadowColor, radius: 8, x: 0, y: 3)
    }
}
