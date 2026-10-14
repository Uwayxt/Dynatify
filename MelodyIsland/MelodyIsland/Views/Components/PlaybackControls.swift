import SwiftUI

// MARK: - Playback Controls
struct PlaybackControls: View {
    @EnvironmentObject var vm: IslandViewModel

    var body: some View {
        HStack(spacing: 24) {
            // Previous
            ControlButton(icon: "backward.fill", size: 16) {
                vm.previousTrack()
            }

            // Play / Pause
            ControlButton(
                icon: (vm.currentTrack?.isPlaying == true) ? "pause.fill" : "play.fill",
                size: 20,
                tint: Color(hex: "#1DB954")
            ) {
                vm.playPause()
            }

            // Next
            ControlButton(icon: "forward.fill", size: 16) {
                vm.nextTrack()
            }
        }
    }
}

// MARK: - Button Press Style
struct IslandButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.86 : 1.0)
            .opacity(configuration.isPressed ? 0.75 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Control Button
struct ControlButton: View {
    @EnvironmentObject var vm: IslandViewModel
    let icon: String
    var size: CGFloat = 16
    var tint: Color? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(tint ?? vm.islandTextColor)
                .frame(width: 36, height: 36)
                .background(Circle().fill(vm.islandSubtleFill))
                .contentShape(Circle())
        }
        .buttonStyle(IslandButtonStyle())
    }
}

// MARK: - Progress Bar (Real-time Scrubbing & Seeking)
struct ProgressBar: View {
    @EnvironmentObject var vm: IslandViewModel
    @State private var isDragging = false
    @State private var dragFraction: Double = 0

    private var fraction: Double {
        guard let track = vm.currentTrack, track.durationSeconds > 0 else { return 0 }
        return isDragging ? dragFraction : min(max(track.positionSeconds / track.durationSeconds, 0), 1)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background Track
                Capsule()
                    .fill(vm.islandSubtleFill)
                    .frame(height: 4)

                // Progress Fill
                Capsule()
                    .fill(Color(hex: "#1DB954"))
                    .frame(width: max(0, min(geo.size.width * fraction, geo.size.width)), height: 4)
            }
            .frame(height: 16)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        isDragging = true
                        dragFraction = max(0, min(val.location.x / geo.size.width, 1))
                        // Real-time lyrics update while dragging!
                        if let track = vm.currentTrack {
                            let dragPos = dragFraction * track.durationSeconds
                            vm.updateActiveLyric(position: dragPos, force: true)
                        }
                    }
                    .onEnded { val in
                        let target = max(0, min(val.location.x / geo.size.width, 1))
                        vm.seek(to: target)
                        isDragging = false
                    }
            )
        }
        .frame(height: 16)
    }
}

// MARK: - Time Label
struct TimeLabel: View {
    @EnvironmentObject var vm: IslandViewModel
    var seconds: Double
    var body: some View {
        Text(formatTime(seconds))
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundStyle(vm.islandSecondaryTextColor)
            .monospacedDigit()
    }
    private func formatTime(_ s: Double) -> String {
        let total = Int(max(0, s))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
