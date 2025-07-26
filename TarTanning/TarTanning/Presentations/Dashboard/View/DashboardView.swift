//
//  DashboardView.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: DashboardViewModel
    @State private var showingDebugSheet = false
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            DashboardTitleView(viewModel: viewModel)
            DashboardSummaryMetricsView(viewModel: viewModel)
            
            Spacer()
            
            // 로딩 상태 표시
            if viewModel.isLoading {
                ProgressView("날씨 정보 로딩 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // 에러 메시지 표시
            if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text(errorMessage)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    Button("다시 시도") {
                        viewModel.loadWeatherData()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            
            // 디버그 버튼 (개발용)
            #if DEBUG
            Button("SwiftData 로그 확인") {
                showingDebugSheet = true
            }
            .font(.caption)
            .foregroundColor(.secondary)
            #endif
        }
        .padding()
        .onAppear {
            viewModel.loadAllDashboardData()
        }
        .sheet(isPresented: $showingDebugSheet) {
            SwiftDataDebugView(viewModel: viewModel)
        }
    }
}

// MARK: - Debug View
struct SwiftDataDebugView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var locationWeathers: [LocationWeather] = []
    @State private var hourlyWeathers: [HourlyWeather] = []
    @State private var refreshTrigger = 0
    
    var body: some View {
        NavigationView {
            List {
                Section("LocationWeather (\(locationWeathers.count)개)") {
                    ForEach(locationWeathers, id: \.id) { location in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(location.city)")
                                .font(.headline)
                            Text("ID: \(location.id)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("날짜: \(location.date.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                            Text("시간별 데이터: \(location.hourlyWeathers.count)개")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 2)
                    }
                }
                
                Section("HourlyWeather (\(hourlyWeathers.count)개)") {
                    ForEach(hourlyWeathers.sorted { $0.hour < $1.hour }, id: \.date) { hourly in
                        HStack {
                            Text("\(hourly.hour)시")
                                .font(.headline)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading) {
                                Text("온도: \(Int(hourly.temperature))°")
                                Text("UV: \(String(format: "%.1f", hourly.uvIndex))")
                            }
                            .font(.caption)
                            
                            Spacer()
                            
                            Text(hourly.locationWeather?.city ?? "연결안됨")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("액션") {
                    Button("데이터 새로고침") {
                        refreshData()
                    }
                    
                    Button("상세 로그 출력") {
                        viewModel.logDetailedSwiftDataStatus()
                    }
                    
                    Button("모든 데이터 삭제", role: .destructive) {
                        viewModel.clearAllData()
                        refreshData()
                    }
                }
            }
            .navigationTitle("SwiftData 확인")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") { dismiss() }
                }
            }
            .onAppear {
                refreshData()
            }
            .onChange(of: refreshTrigger) { _ in
                refreshData()
            }
        }
    }
    
    private func refreshData() {
        Task {
            do {
                let locationDescriptor = FetchDescriptor<LocationWeather>()
                let locations = try viewModel.modelContext.fetch(locationDescriptor)
                
                let hourlyDescriptor = FetchDescriptor<HourlyWeather>()
                let hourlys = try viewModel.modelContext.fetch(hourlyDescriptor)
                
                await MainActor.run {
                    self.locationWeathers = locations
                    self.hourlyWeathers = hourlys
                }
            } catch {
                print("❌ 데이터 새로고침 실패: \(error)")
            }
        }
    }
}
