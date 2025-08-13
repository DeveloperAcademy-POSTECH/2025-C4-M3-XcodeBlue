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
        VStack(alignment: .leading, spacing: 8) {
            WeeklySummaryTitleView()
            WeeklySummaryDataView(
                weeklyProgressRates: viewModel.weeklyUVProgressRates)
        }
    }
}

struct WeeklySummaryTitleView: View {
    var body: some View {
        HStack {
            Text("주간 요약")
                .font(.headline)
                .fontWeight(.semibold)
            Spacer()
        }
    }
}

struct WeeklySummaryDataView: View {
    let weeklyProgressRates: [Double]
    
    private var isEmpty: Bool {
        weeklyProgressRates.isEmpty || weeklyProgressRates.allSatisfy { $0 == 0 }
    }
    
    private var weeklyData: [WeeklyDayData] {
        weeklyProgressRates.enumerated().map { index, progress in
            WeeklyDayData(
                day: getDayString(for: index),
                progress: progress,
                color: getColor(for: progress)
            )
        }
    }

    var body: some View {
        if isEmpty {
            EmptyWeeklyDataView()
        } else {
            weeklyDataContent
        }
    }
}

struct WeeklyDayRowView: View {
    let data: WeeklyDayData
    
    private let progressBarHeight: CGFloat = 8
    private let rowHeight: CGFloat = 32
    
    var body: some View {
        HStack(spacing: 12) {
            dayLabel
            progressBar
            percentageLabel
        }
        .frame(height: rowHeight)
    }
}

struct EmptyWeeklyDataView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("아직 주간 데이터가 없어요.")
                .font(.title3)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct WeeklyDayData {
    let day: String
    let progress: Double
    let color: Color
}

// MARK: - WeeklySummaryDataView Components
private extension WeeklySummaryDataView {
    var weeklyDataContent: some View {
        VStack(spacing: 8) {
            ForEach(weeklyData, id: \.day) { data in
                WeeklyDayRowView(data: data)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    func getDayString(for index: Int) -> String {
        let calendar = Calendar.current
        let today = Date()

        guard let pastDate = calendar.date(byAdding: .day, value: -(index + 1), to: today) else {
            return "\(index + 1)일전"
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")

        // 어제인지 확인
        if calendar.isDateInYesterday(pastDate) {
            return "어제"
        }

        // 요일 반환
        formatter.dateFormat = "EEEE"
        return formatter.string(from: pastDate)
    }

    func getColor(for progress: Double) -> Color {
        switch progress {
        case 0.0..<0.3:
            return .blue
        case 0.3..<0.7:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - WeeklyDayRowView Components
private extension WeeklyDayRowView {
    var dayLabel: some View {
        Text(data.day)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.primary)
            .frame(width: 60, alignment: .leading)
    }
    
    var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 배경 바
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: progressBarHeight)
                    .cornerRadius(4)
                
                // 진행률 바 (100% 초과해도 크기는 고정)
                Rectangle()
                    .fill(data.color)
                    .frame(
                        width: min(geometry.size.width, geometry.size.width * min(1.0, data.progress))
                    )
                    .frame(height: progressBarHeight)
                    .cornerRadius(4)
            }
        }
        .frame(height: progressBarHeight)
    }
    
    var percentageLabel: some View {
        Text("\(Int(data.progress * 100))%")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.secondary)
            .frame(width: 40, alignment: .trailing)
    }
}
