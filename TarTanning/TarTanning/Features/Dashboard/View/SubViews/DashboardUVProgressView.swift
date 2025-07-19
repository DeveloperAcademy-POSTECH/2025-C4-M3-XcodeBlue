//
//  DashboardUVProgressView.swift
//  TarTanning
//
//  Created by Jun on 7/19/25.
//

import SwiftUI

struct DashboardUVProgressView: View {
    private let currentMEDRate: CGFloat = 0.73
    private let currentMEDColor: UIColor = .orange
    private let progressSize: CGFloat = 200
    private let progressHeight: CGFloat = 110

    var body: some View {
        ZStack {
            TotalMEDProgressBarView()
                .frame(width: progressSize, height: progressHeight)

            CurrentMEDProgressBarView(
                progressRate: currentMEDRate,
                progressColor: currentMEDColor
            )
            .frame(width: progressSize, height: progressHeight)

            CurrentMEDTextView()
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
    var body: some View {
        VStack(spacing: 4) {
            Text("MED")
                .font(.system(size: 15))
                .foregroundColor(.gray.opacity(0.5))
            Text("73%")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.orange)
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
        let endAngle = startAngle + (progressRate * .pi)
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

#Preview {
    DashboardUVProgressView()
        .background(Color.white)
        .padding()
}
