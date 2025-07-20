//
//  DashboardView.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel(
        uvExposureRepository: MockUVExposureRepository(),
        weatherRepository: MockWeatherRepository(),
        userProfileRepository: MockUserProfileRepository(),
        locationRepository: MockLocationRepository()
    )

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack {
                DashboardTitleView()
                DashboardUVDoseView(viewModel: viewModel)
                DashboardSummaryMetricsView()
                DashboardWeeklySummaryView()
            }
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
