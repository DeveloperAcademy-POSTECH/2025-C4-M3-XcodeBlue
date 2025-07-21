//
//  DashboardWeeklySummaryView.swift
//  TarTanning
//
//  Created by Jun on 7/19/25.
//

import SwiftUI

struct DashboardWeeklySummaryView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            WeeklySummaryTitleView()
            WeeklySummaryDataView(weeklyProgressRates: viewModel.weeklyUVProgressRates)
        }
    }
}

struct WeeklySummaryTitleView: View {
    var body: some View {
        Text("주간 요약")
            .foregroundColor(.blue)
    }
}

struct WeeklySummaryDataView: View {
    let weeklyProgressRates: [Double]
    
    private var weeklyData: [WeeklyDayData] {
        return weeklyProgressRates.enumerated().map { index, progress in
            let dayString = "\(index + 1) 일전"
            let (color, emoji) = getColorAndEmoji(for: progress)
            
            return WeeklyDayData(
                day: dayString,
                progress: progress,
                color: color,
                emoji: emoji
            )
        }
    }
    
    private func getColorAndEmoji(for progress: Double) -> (Color, String) {
        switch progress {
        case 0.0..<0.3:
            return (.blue, "😆")
        case 0.3..<0.7:
            return (.orange, "🙂")
        case 0.7..<1.0:
            return (.red, "😔")
        default:
            return (.black, "🔥")
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(weeklyData, id: \.day) { data in
                WeeklyDayRowView(data: data)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct WeeklyDayRowView: View {
    let data: WeeklyDayData
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Text(data.day)
                    .foregroundColor(.primary)
                    .frame(width: geometry.size.width * 0.2, alignment: .leading)
                
                Circle()
                    .fill(data.color.opacity(0.2))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text(data.emoji)
                    )
                    .frame(width: geometry.size.width * 0.15, alignment: .center)
                
                VStack(spacing: 2) {
                    Text("\(Int(data.progress * 100))%")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                            .cornerRadius(3)
                        
                        Rectangle()
                            .fill(data.color)
                            .frame(width: max(0, min(1.0, data.progress)) * (geometry.size.width * 0.65))
                            .frame(height: 6)
                            .cornerRadius(3)
                    }
                }
                .frame(width: geometry.size.width * 0.65)
            }
        }
        .frame(height: 40)
    }
}

struct WeeklyDayData {
    let day: String
    let progress: Double
    let color: Color
    let emoji: String
}

#Preview {
    DashboardWeeklySummaryView(viewModel: DashboardViewModel(
        uvExposureRepository: MockUVExposureRepository(),
        weatherRepository: MockWeatherRepository(),
        userProfileRepository: MockUserProfileRepository(),
        locationRepository: MockLocationRepository()
    ))
}
