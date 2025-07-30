//
//  DashboardUVProgressView.swift
//  TarTanning
//
//  Created by Jun on 7/19/25.
//

import SwiftUI

struct DashboardUVProgressView: View {
    @ObservedObject var viewModel: DashboardViewModel

    private let progressSize: CGFloat = 200
    private let progressHeight: CGFloat = 110
    private var currentMEDRate: CGFloat {
        // ProgressView는 0.0 ~ 1.0 범위로 제한하되, 100%를 넘으면 1.0으로 표시
        let progressRate = viewModel.todayUVProgressRate
        return CGFloat(min(progressRate, 1.0))
    }
    private var currentMEDColor: UIColor {
        switch viewModel.todayUVProgressRate {
        case 0.0..<0.3:
            return .systemBlue
        case 0.3..<0.5:
            return .orange
        case 0.5..<0.7:
            return .primaryRed
        case 0.7..<1.0:
            return .primaryRed
        default:
            return .systemRed // 100% 이상일 때도 빨간색
        }
    }

    var body: some View {
        ZStack {
            TotalMEDProgressBarView()
                .frame(width: progressSize, height: progressHeight)

            CurrentMEDProgressBarView(
                progressRate: currentMEDRate,
                progressColor: currentMEDColor
            )
            .frame(width: progressSize, height: progressHeight)

            CurrentMEDTextView(viewModel: viewModel)
        }
    }
}

struct TotalMEDProgressBarView: View {
    var body: some View {
        TotalMEDProgressBarUIViewRepresentable()
    }
}

struct CurrentMEDProgressBarView: View {
    let progressRate: CGFloat
    let progressColor: UIColor

    var body: some View {
        CurrentMEDProgressBarUIViewRepresentable(
            progressRate: progressRate,
            progressColor: progressColor
        )
    }
}

struct CurrentMEDTextView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    // 로그 중복 방지를 위한 static 변수들
    private static var lastLoggedMEDValue: Double = -1
    private static var lastLoggedMaxMED: Double = -1
    
    private var progressPercentage: Int {
        let maxMED = viewModel.getMaxMED()
        let percentage = Int((viewModel.todayMEDValue / maxMED) * 100)
        
        // 디버깅 로그는 값이 변경되었을 때만 출력
        if viewModel.todayMEDValue != Self.lastLoggedMEDValue || maxMED != Self.lastLoggedMaxMED {
            print("🔍 [CurrentMEDTextView] MED calculation updated:")
            print("   • todayMEDValue: \(String(format: "%.6f", viewModel.todayMEDValue)) J/m²")
            print("   • maxMED: \(String(format: "%.6f", maxMED)) J/m²")
            print("   • percentage: \(percentage)%")
            
            // 추가 디버깅: 값이 너무 작은지 확인
            if viewModel.todayMEDValue < 0.001 {
                print("⚠️ [CurrentMEDTextView] WARNING: todayMEDValue is very small")
            }
            
            Self.lastLoggedMEDValue = viewModel.todayMEDValue
            Self.lastLoggedMaxMED = maxMED
        }
        
        return percentage
    }
    
    private var progressColor: Color {
        let maxMED = viewModel.getMaxMED()
        let progressRate = viewModel.todayMEDValue / maxMED
        
        switch progressRate {
        case 0.0..<0.3:
            return .blue
        case 0.3..<0.5:
            return .orange
        case 0.5..<0.7:
            return .red
        case 0.7..<1.0:
            return .red
        default:
            return .red // 100% 이상일 때도 빨간색
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("UV 노출량")
                .font(.system(size: 15))
                .foregroundColor(.gray.opacity(0.5))
            Text("\(progressPercentage)%")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(progressColor)
        }
        .padding(.top, 60)
    }
}

class TotalMEDProgressBarUIView: UIView {
    private let centerPoint = CGPoint(x: 100, y: 100)
    private let radius: CGFloat = 90
    private let lineWidth: CGFloat = 10
    private let startAngle: CGFloat = .pi
    private let endAngle: CGFloat = 2 * .pi

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        let path = UIBezierPath(
            arcCenter: centerPoint,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )

        UIColor.clear.setFill()
        UIColor.systemGray4.setStroke()
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        path.stroke()
        path.fill()
    }
}

class CurrentMEDProgressBarUIView: UIView {
    var progressRate: CGFloat
    var progressColor: UIColor

    private let centerPoint = CGPoint(x: 100, y: 100)
    private let radius: CGFloat = 90
    private let lineWidth: CGFloat = 10
    private let startAngle: CGFloat = .pi

    init(frame: CGRect, progressRate: CGFloat, progressColor: UIColor) {
        self.progressRate = progressRate
        self.progressColor = progressColor
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        // 100%를 넘으면 반원을 완전히 채움
        let maxProgress = min(progressRate, 1.0)
        let endAngle = startAngle + (maxProgress * .pi)
        let path = UIBezierPath(
            arcCenter: centerPoint,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )

        UIColor.clear.setFill()
        progressColor.setStroke()
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        path.stroke()
        path.fill()
    }
}

struct TotalMEDProgressBarUIViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> TotalMEDProgressBarUIView {
        TotalMEDProgressBarUIView(
            frame: CGRect(x: 0, y: 0, width: 200, height: 200)
        )
    }

    func updateUIView(_ uiView: TotalMEDProgressBarUIView, context: Context) {
    }
}

struct CurrentMEDProgressBarUIViewRepresentable: UIViewRepresentable {
    var progressRate: CGFloat
    var progressColor: UIColor

    func makeUIView(context: Context) -> CurrentMEDProgressBarUIView {
        CurrentMEDProgressBarUIView(
            frame: CGRect(x: 0, y: 0, width: 200, height: 200),
            progressRate: progressRate,
            progressColor: progressColor
        )
    }

    func updateUIView(_ uiView: CurrentMEDProgressBarUIView, context: Context) {
        uiView.progressRate = progressRate
        uiView.progressColor = progressColor
        uiView.setNeedsDisplay()
    }
}
