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
            return "안전"
        case 0.3..<0.5:
            return "주의"
        case 0.5..<0.7:
            return "위험"
        default:
            return "매우 위험"
        }
    }
    
    private var uvStatusColor: Color {
        switch viewModel.todayUVProgressRate {
        case 0.0..<0.3:
            return .blue
        case 0.3..<0.5:
            return .orange
        case 0.5..<0.7:
            return .red
        default:
            return .red
        }
    }
    
    private var uvAdviceText: String {
        switch viewModel.todayUVProgressRate {
        case 0.0..<0.3:
            return "적당한 야외활동을 즐기세요!"
        case 0.3..<0.5:
            return "자외선 차단제를 사용하세요!"
        case 0.5..<0.7:
            return "야외활동을 자제하세요!"
        default:
            return "즉시 실내로 이동하세요!"
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            // UV 진행률 원형 프로그레스
            DashboardUVProgressView(viewModel: viewModel)
            
            // UV 상태 및 조언
            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    Text("지금은 자외선으로부터 ")
                    Text(uvStatusText)
                        .foregroundColor(uvStatusColor)
                    Text("해요!")
                }
                .font(.system(size: 16, weight: .medium))
                
                Text(uvAdviceText)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // UV Dose 상세 정보
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("오늘 UV 노출량")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.4f", viewModel.todayMEDValue))")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.orange)
                            .onAppear {
                                print("📊 [DashboardUVDoseView] Today MED Value: \(String(format: "%.4f", viewModel.todayMEDValue))")
                            }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("최대 허용량")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("\(Int(viewModel.getMaxMED()))")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
                
                // 진행률 바
                ProgressView(value: viewModel.todayUVProgressRate)
                    .progressViewStyle(LinearProgressViewStyle(tint: uvStatusColor))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
            )
            
            // 선크림 모드 버튼
            Button {
                showingTimer = true
            } label: {
                Label("선크림 모드", systemImage: "cloud.sun")
                    .font(.system(size: 16, weight: .medium))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 20)
    }
}
