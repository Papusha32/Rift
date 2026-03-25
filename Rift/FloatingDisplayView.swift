import SwiftUI

struct FloatingDisplayView: View {
    @ObservedObject var timerManager: TimerManager

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .trim(from: 0, to: CGFloat(1.0 - timerManager.progress))
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 18, height: 18)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timerManager.progress)

            Text(timerManager.timeString)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
