//
//  DashboardSummaryMetricsView.swift
//  TarTanning
//
//  Created by Jun on 7/19/25.
//

import SwiftUI

struct DashboardSummaryMetricsView: View {
    private let uvIndex: Int = 9
    private let totalDaylightMinutes: Int = 30
    private let currentTemperature: Int = 28
    
    var body: some View {
        HStack(spacing: 0) {
            UVIndexMetricView(value: uvIndex)
            
            Divider()
                .frame(height: 40)
                .padding(.horizontal, 20)
            
            TotalDaylightMetricView(value: totalDaylightMinutes)
            
            Divider()
                .frame(height: 40)
                .padding(.horizontal, 20)
            
            CurrentTemperatureMetricView(value: currentTemperature)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct UVIndexMetricView: View {
    let value: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(value)")
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
    let value: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(value)분")
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
    let value: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(value)°C")
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
    DashboardSummaryMetricsView()
        .background(Color.gray.opacity(0.1))
        .padding()
}
