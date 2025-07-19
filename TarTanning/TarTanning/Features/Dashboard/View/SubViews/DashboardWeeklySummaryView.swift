//
//  DashboardWeeklySummaryView.swift
//  TarTanning
//
//  Created by Jun on 7/19/25.
//

import SwiftUI

struct DashboardWeeklySummaryView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            WeeklySummaryTitleView()
            WeeklySummaryDataView()
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
    private let weeklyData: [WeeklyDayData] = [
        WeeklyDayData(day: "오늘", progress: 0.32, color: .orange, emoji: "😊"),
        WeeklyDayData(day: "1일전", progress: 0.0, color: .gray, emoji: "😐"),
        WeeklyDayData(day: "2일전", progress: 0.89, color: .red, emoji: "😔"),
        WeeklyDayData(day: "3일전", progress: 0.89, color: .red, emoji: "😔"),
        WeeklyDayData(day: "4일전", progress: 0.24, color: .blue, emoji: "😊"),
        WeeklyDayData(day: "5일전", progress: 0.12, color: .blue, emoji: "😊"),
        WeeklyDayData(day: "6일전", progress: 0.05, color: .blue, emoji: "😊")
    ]
    
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
    DashboardWeeklySummaryView()
        .padding()
}
