import AppKit

/// Borderless, floating, non-activating panel that hosts the Dynamic Island.
final class IslandPanel: NSPanel {

    /// Transparent padding around the pill to allow the drop shadow and hover scaling
    /// to smoothly fade to zero alpha without being clipped by the window frame boundaries.
    static let shadowPadding: CGFloat = 24.0

    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        configure()
    }

    private func configure() {
        isFloatingPanel = true
        level = .statusBar              // Floats above normal windows
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false               // Shadow rendered cleanly by SwiftUI with shadowPadding room
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isMovable = false
        ignoresMouseEvents = false
        acceptsMouseMovedEvents = true
        hidesOnDeactivate = false
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }


    // MARK: - Dynamic Frame Updates (With Custom & Adaptive Width)
    func updateFrame(for state: IslandState, style: IslandStyle = .directLyrics, customWidth: CGFloat? = nil, animated: Bool = true) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let hasNotch = screen.safeAreaInsets.top > 0

        let contentWidth: CGFloat
        let contentHeight: CGFloat

        switch state {
        case .closed:
            contentWidth = 44
            contentHeight = 28
        case .compact:
            contentWidth = customWidth ?? style.defaultWidth
            contentHeight = style.defaultHeight
        case .expanded, .dragging:
            contentWidth = 380
            contentHeight = 410
        }

        let baseTopMargin: CGFloat = hasNotch ? (screen.safeAreaInsets.top + 4) : 28
        let userOffset = UserDefaults.standard.double(forKey: "islandYOffset")
        let effectiveTopMargin = max(0, baseTopMargin + userOffset)

        // Pill visual coordinates
        let pillX = screenFrame.midX - (contentWidth / 2)
        let pillY = screenFrame.maxY - effectiveTopMargin - contentHeight

        // Window frame enlarged by shadowPadding to prevent shadow clipping
        let pad = Self.shadowPadding
        let targetRect = NSRect(
            x: pillX - pad,
            y: pillY - pad,
            width: contentWidth + (pad * 2),
            height: contentHeight + (pad * 2)
        )

        if self.frame.equalTo(targetRect) { return }

        if animated {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.32
                ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                self.animator().setFrame(targetRect, display: true)
            }
        } else {
            setFrame(targetRect, display: true)
        }
    }
}
