import SwiftUI

// MARK: - Single Lyric Line View
struct LyricLine: View {
    @EnvironmentObject var vm: IslandViewModel
    let line: LRCLine
    let isActive: Bool
    let index: Int
    let activeIndex: Int

    private var distance: Int { abs(index - activeIndex) }

    private var textOpacity: Double {
        if isActive { return 0.95 }
        switch distance {
        case 1: return 0.50
        case 2: return 0.28
        default: return 0.15
        }
    }

    private var textSize: CGFloat {
        isActive ? 18 : 15
    }

    private var textWeight: Font.Weight {
        isActive ? .bold : .regular
    }

    var body: some View {
        Text(line.text)
            .font(.system(size: textSize, weight: textWeight, design: .rounded))
            .foregroundStyle(vm.islandTextColor.opacity(textOpacity))
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .padding(.horizontal, 12)
            .padding(.vertical, isActive ? 4 : 2)
            .scaleEffect(isActive ? 1.02 : 1.0)
            .animation(.smooth(duration: 0.3), value: isActive)
            .animation(.smooth(duration: 0.3), value: textOpacity)
    }
}
