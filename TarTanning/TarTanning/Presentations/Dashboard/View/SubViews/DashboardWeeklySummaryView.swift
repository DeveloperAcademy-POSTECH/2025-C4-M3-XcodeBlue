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
                weeklyProgressRates: viewModel.weeklyUVProgressRates
            )
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

    private var weeklyData: [WeeklyDayData] {
        return weeklyProgressRates.enumerated().map { index, progress in
            let dayString = getDayString(for: index)
//            let color = getColor(for: progress)
            let color = Color.primaryRed

            return WeeklyDayData(
                day: dayString,
                progress: progress,
                color: color
            )
        }
    }

    private func getDayString(for index: Int) -> String {
        let calendar = Calendar.current
        let today = Date()

        if let pastDate = calendar.date(
            byAdding: .day,
            value: -(index + 1),
            to: today
        ) {
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

        return "\(index + 1)일전"
    }

    private func getColor(for progress: Double) -> Color {
        switch progress {
        case 0.0..<0.3:
            return .blue
        case 0.3..<0.7:
            return .orange
        case 0.7..<1.0:
            return .red
        default:
            return .red
        }
    }

    var body: some View {
        if weeklyProgressRates.isEmpty
            || weeklyProgressRates.allSatisfy({ $0 == 0 }) {
            EmptyWeeklyDataView()
        } else {
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
}

struct WeeklyDayRowView: View {
    let data: WeeklyDayData

    var body: some View {
        HStack(spacing: 12) {
            // 날짜 텍스트
            Text(data.day)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 60, alignment: .leading)

            // 진행률 바
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                    .cornerRadius(4)

                Rectangle()
                    .fill(data.color)
                    .frame(
                        width: max(0, min(1.0, data.progress))
                            * UIScreen.main.bounds.width * 0.6
                    )
                    .frame(height: 8)
                    .cornerRadius(4)
            }

            // 퍼센트 텍스트
            Text("\(Int(data.progress * 100))%")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
        .frame(height: 32)
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
