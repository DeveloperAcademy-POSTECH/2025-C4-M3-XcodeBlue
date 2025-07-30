//
//  DashboardUVDoseView.swift
//  TarTanning
//
//  Created by Jun on 7/19/25.
//

import SwiftUI

struct DashboardUVDoseView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var showingTimer: Bool

    private var uvStatusText: String {
        switch viewModel.todayUVProgressRate {
        case 0.0..<0.3:
            return "낮은 수준"
        case 0.3..<0.5:
            return "보통 수준"
        case 0.5..<0.7:
            return "높은 수준"
        default:
            return "주의 수준"
        }
    }

    private var uvStatusColor: Color {
        switch viewModel.todayUVProgressRate {
        case 0.0..<0.3:
            return .blue
        case 0.3..<0.5:
            return .orange
        case 0.5..<0.7:
            return .primaryRed
        default:
            return .primaryRed
        }
    }

    private var uvAdviceText: String {
        switch viewModel.todayUVProgressRate {
        case 0.0..<0.3:
            return "야외 활동에 적합한 수준입니다"
        case 0.3..<0.5:
            return "자외선 차단제 사용을 고려하세요"
        case 0.5..<0.7:
            return "선크림 사용을 권장합니다"
        default:
            return "실내 활동을 고려해보세요"
        }
    }

    var body: some View {
        VStack {
            DashboardUVProgressView(viewModel: viewModel)

            uvDoseInfoSection

            uvStatusSection

            Spacer().frame(height: 24)

            sunscreenButton
        }
        .padding(20)
        .frame(height: 400)
        .background(Color.white00)
        .cornerRadius(20)
    }
}

// MARK: - DashboardUVDoseView Components
extension DashboardUVDoseView {
    fileprivate var uvDoseInfoSection: some View {
        HStack {
            uvDoseInfo(
                title: "오늘 UV 노출량",
                value: String(format: "%.1f", viewModel.todayMEDValue),
                color: uvStatusColor
            )

            Spacer()

            uvDoseInfo(
                title: "최대 UV 노출량",
                value: "\(Int(viewModel.getMaxMED()))",
                color: .primary
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    fileprivate func uvDoseInfo(title: String, value: String, color: Color)
        -> some View
    {
        VStack(alignment: .center, spacing: 4) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            HStack(alignment: .center, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(color)
                Text("J/m²")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }

    fileprivate var uvStatusSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                Text("현재 UV 노출량은 ")
                Text(uvStatusText)
                    .foregroundColor(uvStatusColor)
                    .fontWeight(.bold)
                Text("입니다")
            }
            .font(.system(size: 16, weight: .medium))

            Text(uvAdviceText)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    fileprivate var sunscreenButton: some View {
        Button {
            showingTimer = true
        } label: {
            Label("선크림 잔여 시간 보기", systemImage: "cloud.sun")
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue, lineWidth: 1)
                )
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 32)
    }
}
