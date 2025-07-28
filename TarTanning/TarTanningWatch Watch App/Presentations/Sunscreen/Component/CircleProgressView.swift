import SwiftUI

struct CircleProgressView: View {
    var remainingTime: TimeInterval
    var totalDuration: TimeInterval
    var lineWidth: CGFloat = 8
    var backgroundColor: Color = Color.white.opacity(0.3)
    var progressColor: Color = Color.blue
    var showTimeDisplay: Bool = true

    var body: some View {
        ZStack {
            BackgroundCircle(backgroundColor: backgroundColor, lineWidth: lineWidth)

            ProgressCircle(progress: progress, progressColor: progressColor, lineWidth: lineWidth)

            if showTimeDisplay {
                RemainingTimeText(remainingTime: remainingTime)
            }
        }
        .frame(width: 120, height: 120)
    }

    struct BackgroundCircle: View {
        let backgroundColor: Color
        let lineWidth: CGFloat

        var body: some View {
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)
        }
    }

    struct ProgressCircle: View {
        let progress: Double
        let progressColor: Color
        let lineWidth: CGFloat

        var body: some View {
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
        }
    }

    struct RemainingTimeText: View {
        let remainingTime: TimeInterval

        var body: some View {
            let (hours, minutes) = secondsToHoursAndMinutes(remainingTime)

            Text(String(format: "%02d:%02d", hours, minutes)) // 시:분 형식
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.suncreenExplainText)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: remainingTime)
                .minimumScaleFactor(0.8)
        }

        /// 초 단위 TimeInterval을 시/분으로 변환하는 헬퍼 함수
        private func secondsToHoursAndMinutes(_ seconds: TimeInterval) -> (Int, Int) {
            let totalSeconds = Int(seconds)
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            return (hours, minutes)
        }
    }

    private var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return max(0, min(1, remainingTime / totalDuration))
    }
}

#Preview {
    CircleProgressView(
        remainingTime: 45 * 60, // 45분
        totalDuration: 120 * 60 // 2시간
    )
}
