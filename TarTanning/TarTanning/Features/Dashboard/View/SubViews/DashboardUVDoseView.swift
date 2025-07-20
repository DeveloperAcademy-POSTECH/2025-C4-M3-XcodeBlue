//
//  DashboardUVDoseView.swift
//  TarTanning
//
//  Created by Jun on 7/19/25.
//

import SwiftUI

struct DashboardUVDoseView: View {
    let viewModel: DashboardViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            DashboardUVProgressView(viewModel: viewModel)
            
            VStack {
                HStack(spacing: 0) {
                    Text("지금은 자외선으로부터 ")
                    Text("주의")
                        .foregroundColor(.orange)  // 색변경 필요
                    Text("해요!")
                }
                Text("100%가 되면 야외활동을 자제하세요!")
            }
            
            Button {
                print("선크림 모드 ON")
            } label: {
                Label("선크림 모드", systemImage: "cloud.sun")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                style: StrokeStyle(lineWidth: 1)
                            )
                    )
            }
            
        }
    }
}

#Preview {
    DashboardUVDoseView(viewModel: DashboardViewModel(
        uvExposureRepository: MockUVExposureRepository(),
        weatherRepository: MockWeatherRepository(),
        userProfileRepository: MockUserProfileRepository(),
        locationRepository: MockLocationRepository()
    ))
}
