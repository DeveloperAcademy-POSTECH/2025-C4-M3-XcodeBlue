//
//  DashboardSummaryMetricsView.swift
//  TarTanning
//
//  Created by Jun on 7/19/25.
//

import SwiftUI

struct DashboardSummaryMetricsView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            UVIndexMetricView(viewModel: viewModel)
            
            Divider()
                .frame(height: 40)
                .padding(.horizontal, 20)
            
            TotalDaylightMetricView(viewModel: viewModel)
            
            Divider()
                .frame(height: 40)
                .padding(.horizontal, 20)
            
            CurrentTemperatureMetricView(viewModel: viewModel)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(12)
        .onAppear {
            print("🔍 DEBUG: DashboardSummaryMetricsView onAppear")
            print("🔍 DEBUG: currentUVIndex = \(viewModel.currentUVIndex)")
            print("🔍 DEBUG: todayTotalSunlightMinutes = \(viewModel.todayTotalSunlightMinutes)")
            print("🔍 DEBUG: currentTemperature = \(viewModel.currentTemperature)")
        }
    }
}

struct UVIndexMetricView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(viewModel.currentUVIndex)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.blue)
            
            Text("UV 지수")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TotalDaylightMetricView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(viewModel.todayTotalSunlightMinutes)분")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.blue)
            
            Text("총 일광 시간")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CurrentTemperatureMetricView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(viewModel.currentTemperature)°C")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.blue)
            
            Text("현재 기온")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
#Preview {
    DashboardSummaryMetricsView(viewModel: DashboardViewModel(uvExposureRepository: MockUVExposureRepository(), weatherRepository: MockWeatherRepository(), userProfileRepository: MockUserProfileRepository(), locationRepository: MockLocationRepository()))
        .background(Color.gray.opacity(0.1))
        .padding()
}
