////
////  DashboardUVDoseView.swift
////  TarTanning
////
////  Created by Jun on 7/19/25.
////
//
//import SwiftUI
//
//struct DashboardUVDoseView: View {
//    @ObservedObject var viewModel: DashboardViewModel
//    @State private var showTimerView = false
//    
//    private var uvStatusText: String {
//        switch viewModel.todayUVProgressRate {
//        case 0.0..<0.3:
//            return "안전"
//        case 0.3..<0.5:
//            return "주의"
//        case 0.5..<0.7:
//            return "위험"
//        default:
//            return "매우 위험"
//        }
//    }
//    
//    private var uvStatusColor: Color {
//        switch viewModel.todayUVProgressRate {
//        case 0.0..<0.3:
//            return .blue
//        case 0.3..<0.5:
//            return .orange
//        case 0.5..<0.7:
//            return .red
//        default:
//            return .red
//        }
//    }
//    
//    private var uvAdviceText: String {
//        switch viewModel.todayUVProgressRate {
//        case 0.0..<0.3:
//            return "적당한 야외활동을 즐기세요!"
//        case 0.3..<0.5:
//            return "자외선 차단제를 사용하세요!"
//        case 0.5..<0.7:
//            return "야외활동을 자제하세요!"
//        default:
//            return "즉시 실내로 이동하세요!"
//        }
//    }
//
//    var body: some View {
//        Group {
//            if showTimerView {
////                TimerView(isPresented: $showTimerView)
//            } else {
//                VStack(spacing: 24) {
//                    DashboardUVProgressView(viewModel: viewModel)
//                    
//                    VStack {
//                        HStack(spacing: 0) {
//                            Text("지금은 자외선으로부터 ")
//                            Text(uvStatusText)
//                                .foregroundColor(uvStatusColor)
//                            Text("해요!")
//                        }
//                        Text(uvAdviceText)
//                    }
//                    
//                    Button {
//                        showTimerView = true
//                    } label: {
//                        Label("선크림 모드", systemImage: "cloud.sun")
//                            .padding(.horizontal, 20)
//                            .padding(.vertical, 8)
//                            .background(
//                                RoundedRectangle(cornerRadius: 20)
//                                    .stroke(
//                                        style: StrokeStyle(lineWidth: 1)
//                                    )
//                            )
//                    }
//                }
//            }
//        }
//    }
//}
//
//#Preview {
//    DashboardUVDoseView(viewModel: DashboardViewModel(
//        uvExposureRepository: MockUVExposureRepository(),
//        weatherRepository: MockWeatherRepository(),
//        userProfileRepository: MockUserProfileRepository(),
//        locationRepository: MockLocationRepository()
//    ))
//}
