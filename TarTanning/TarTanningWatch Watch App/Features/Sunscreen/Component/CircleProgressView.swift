//
//  CircleProgressView.swift
//  TarTanning
//
//  Created by taeni on 7/19/25.
//

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
            VStack {
                Text(remainingTime.timeDisplayString)
                    .font(.title3)
                    .foregroundColor(.suncreenExplainText)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: remainingTime)
                    .minimumScaleFactor(0.8)
            }
        }
    }
    
    private var progress: Double {
        guard totalDuration > 0 else { return 0 }
        let elapsed = totalDuration - remainingTime
        return max(0, min(1, elapsed / totalDuration))
    }
    
}

#Preview {
    CircleProgressView(
        remainingTime: 45 * 60, // 45분
        totalDuration: 120 * 60 // 2시간
    )
}
