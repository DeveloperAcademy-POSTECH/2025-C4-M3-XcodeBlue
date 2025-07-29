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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("포항시 날씨 정보")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 0) {
                UVIndexMetricView(viewModel: viewModel)
                
                Divider()
                    .frame(height: 40)
                    .padding(.horizontal, 20)
                
                //            TotalDaylightMetricView(viewModel: viewModel)
                //
                //            Divider()
                //                .frame(height: 40)
                //                .padding(.horizontal, 20)
                
                CurrentTemperatureMetricView(viewModel: viewModel)
                
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
            .cornerRadius(12)
            .opacity(viewModel.isLoading ? 0.6 : 1.0)
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
    }
}

struct UVIndexMetricView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        VStack(spacing: 4) {
            Text("UV 지수")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Group {
                if viewModel.isLoading {
                    Text("--")
                        .foregroundColor(.gray)
                } else if viewModel.currentWeather != nil {
                    Text("\(Int(viewModel.currentUVIndex))")
//                        .foregroundColor(uvIndexColor)
                } else {
                    Text("--")
                        .foregroundColor(.gray)
                }
            }
            .font(.system(size: 24, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
    }

    private var uvIndexColor: Color {
        let uvIndex = viewModel.currentUVIndex
        switch uvIndex {
        case 0...2:
            return .green
        case 3...5:
            return .yellow
        case 6...7:
            return .orange
        case 8...10:
            return .red
        case 11...:
            return .purple
        default:
            return .blue
        }
    }
}

struct TotalDaylightMetricView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        VStack(spacing: 4) {
            Text("총 일조 시간")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Group {
                if viewModel.isLoading {
                    Text("--분")
                        .foregroundColor(.gray)
                } else if viewModel.currentWeather != nil {
                    Text("\(viewModel.todayTotalSunlightMinutes)분")
                        .foregroundColor(.blue)
                } else {
                    Text("--분")
                        .foregroundColor(.gray)
                }
            }
            .font(.system(size: 24, weight: .bold))
        }
        .frame(maxWidth: .infinity)
    }
}

struct CurrentTemperatureMetricView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        VStack(spacing: 4) {
            Text("현재 기온")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Group {
                if viewModel.isLoading {
                    Text("--°")
                        .foregroundColor(.gray)
                } else if viewModel.currentWeather != nil {
                    Text("\(viewModel.currentTemperature)°")
//                        .foregroundColor(temperatureColor)
                } else {
                    Text("--°")
                        .foregroundColor(.gray)
                }
            }
            .font(.system(size: 24, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
    }

    private var temperatureColor: Color {
        let temperature = viewModel.currentTemperature
        switch temperature {
        case ...0:
            return .blue
        case 1...10:
            return .cyan
        case 11...20:
            return .green
        case 21...30:
            return .orange
        case 31...:
            return .red
        default:
            return .blue
        }
    }
}
