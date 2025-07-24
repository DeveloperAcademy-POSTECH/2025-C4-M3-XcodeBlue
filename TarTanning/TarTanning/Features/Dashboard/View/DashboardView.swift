//
//  DashboardView.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel(
        uvExposureRepository: DefaultUVExposureRepository(
            weatherRepository: DefaultWeatherRepository()
        ),
        weatherRepository: DefaultWeatherRepository(),
        userProfileRepository: MockUserProfileRepository(),
        locationRepository: MockLocationRepository()
    )

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack {
                DashboardTitleView()
                DashboardUVDoseView(viewModel: viewModel)
                DashboardSummaryMetricsView(viewModel: viewModel)
                DashboardWeeklySummaryView(viewModel: viewModel)
            }
            .navigationTitle("대시 보드").navigationBarTitleDisplayMode(.large)
            .padding(20)
        }
        .task {
            await viewModel.loadDashboardData()
        }
    }
}

#Preview {
    DashboardView()
}
