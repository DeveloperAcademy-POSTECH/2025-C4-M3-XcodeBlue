//
//  DashboardView.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: DashboardViewModel

    @StateObject private var timerManager = SunscreenViewModel.shared
    @State private var showingTimer = false

    @State private var showingDebugSheet = false

    init(modelContext: ModelContext) {
        _viewModel = StateObject(
            wrappedValue: DashboardViewModel(modelContext: modelContext)
        )
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: true) {
                VStack(spacing: 20) {
                    VStack{
                        DashboardTitleView(viewModel: viewModel)
                        if showingTimer {
                            DashboardTimerView(isPresented: $showingTimer)
                        } else {
                            DashboardUVDoseView(
                                viewModel: viewModel,
                                showingTimer: $showingTimer
                            )
                        }
                    }
                    DashboardSummaryMetricsView(viewModel: viewModel)

                    DashboardWeeklySummaryView(viewModel: viewModel)

                    Spacer()

                    // 디버그 버튼 (개발용)
//                    #if DEBUG
//                        debugButton
//                    #endif
                }
                .padding(.horizontal, 20)
            }
            .background(Color.white01)
            .navigationTitle("대시보드")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            viewModel.loadAllDashboardData()
            showingTimer = timerManager.isActive
        }
        .onReceive(
            timerManager.$isActive.debounce(
                for: .milliseconds(1000),
                scheduler: RunLoop.main
            )
        ) { newValue in
            showingTimer = newValue
        }
        .sheet(isPresented: $showingDebugSheet) {
            debugSheet
        }
    }
}

// MARK: - DashboardView Debug Extension
#if DEBUG
    extension DashboardView {
        var debugButton: some View {
            Button("SwiftData 로그 확인") {
                showingDebugSheet = true
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }

        var debugSheet: some View {
            SwiftDataDebugView(viewModel: viewModel)
        }
    }
#endif

// MARK: - Debug View
struct SwiftDataDebugView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss
    @State var locationWeathers: [LocationWeather] = []
    @State var hourlyWeathers: [HourlyWeather] = []
    @State var dailyUVExposes: [DailyUVExpose] = []
    @State var uvExposeRecords: [UVExposeRecord] = []
    @State var refreshTrigger = 0

    var body: some View {
        NavigationView {
            List {
                LocationWeatherSection(locationWeathers: locationWeathers)

                HourlyWeatherSection(hourlyWeathers: hourlyWeathers)

                DailyUVExposeSection(dailyUVExposes: dailyUVExposes)

                UVExposeRecordSection(uvExposeRecords: uvExposeRecords)

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
        }
    }

    private func refreshData() {
        Task {
            do {
                // Weather 데이터
                let locationDescriptor = FetchDescriptor<LocationWeather>()
                let locations = try viewModel.modelContext.fetch(
                    locationDescriptor
                )

                let hourlyDescriptor = FetchDescriptor<HourlyWeather>()
                let hourlys = try viewModel.modelContext.fetch(hourlyDescriptor)

                // UV 노출량 데이터
                let dailyUVDescriptor = FetchDescriptor<DailyUVExpose>()
                let dailyUVs = try viewModel.modelContext.fetch(
                    dailyUVDescriptor
                )

                let uvRecordDescriptor = FetchDescriptor<UVExposeRecord>()
                let uvRecords = try viewModel.modelContext.fetch(
                    uvRecordDescriptor
                )

                await MainActor.run {
                    self.locationWeathers = locations
                    self.hourlyWeathers = hourlys
                    self.dailyUVExposes = dailyUVs
                    self.uvExposeRecords = uvRecords
                }

                print("📊 [SwiftDataDebugView] 데이터 새로고침 완료:")
                print("   - LocationWeather: \(locations.count)개")
                print("   - HourlyWeather: \(hourlys.count)개")
                print("   - DailyUVExpose: \(dailyUVs.count)개")
                print("   - UVExposeRecord: \(uvRecords.count)개")

            } catch {
                print("❌ 데이터 새로고침 실패: \(error)")
            }
        }
    }
}

// MARK: - Supporting Views

struct LocationWeatherSection: View {
    let locationWeathers: [LocationWeather]

    var body: some View {
        Section("LocationWeather (\(locationWeathers.count)개)") {
            ForEach(locationWeathers, id: \.id) { location in
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(location.city)")
                        .font(.headline)
                    Text("ID: \(location.id)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(
                        "날짜: \(location.date.formatted(date: .abbreviated, time: .omitted))"
                    )
                    .font(.caption)
                    Text("시간별 데이터: \(location.hourlyWeathers.count)개")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 2)
            }
        }
    }
}

struct HourlyWeatherSection: View {
    let hourlyWeathers: [HourlyWeather]

    var body: some View {
        Section("HourlyWeather (\(hourlyWeathers.count)개)") {
            ForEach(hourlyWeathers.sorted { $0.hour < $1.hour }, id: \.date) {
                hourly in
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
    }
}

struct DailyUVExposeSection: View {
    let dailyUVExposes: [DailyUVExpose]

    var body: some View {
        Section("DailyUVExpose (\(dailyUVExposes.count)개)") {
            ForEach(dailyUVExposes.sorted { $0.date > $1.date }, id: \.date) {
                daily in
                DailyUVExposeRowView(daily: daily)
            }
        }
    }
}

struct UVExposeRecordSection: View {
    let uvExposeRecords: [UVExposeRecord]

    var body: some View {
        Section("UVExposeRecord (\(uvExposeRecords.count)개)") {
            ForEach(
                uvExposeRecords.sorted { $0.startDate > $1.startDate },
                id: \.startDate
            ) { record in
                UVExposeRecordRowView(record: record)
            }
        }
    }
}

struct DailyUVExposeRowView: View {
    let daily: DailyUVExpose

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(
                "날짜: \(daily.date.formatted(date: .abbreviated, time: .omitted))"
            )
            .font(.headline)
            Text(
                "총 일광시간: \(String(format: "%.1f", daily.totalSunlightMinutes))분"
            )
            .font(.caption)
            .foregroundColor(.blue)
            Text("총 UV Dose: \(String(format: "%.2f", daily.totalUVDose))")
                .font(.caption)
                .foregroundColor(.orange)
            Text("기록 개수: \(daily.exposureRecords.count)개")
                .font(.caption)
                .foregroundColor(.green)
        }
        .padding(.vertical, 2)
    }
}

struct UVExposeRecordRowView: View {
    let record: UVExposeRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(
                    "\(record.startDate.formatted(date: .omitted, time: .shortened))"
                )
                .font(.headline)
                Text("~")
                Text(
                    "\(record.endDate.formatted(date: .omitted, time: .shortened))"
                )
                .font(.headline)
            }

            HStack {
                Text(
                    "일광시간: \(String(format: "%.1f", record.sunlightExposureDuration))분"
                )
                .font(.caption)
                .foregroundColor(.blue)

                Spacer()

                Text("UV Dose: \(String(format: "%.2f", record.uvDose))")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            HStack {
                Text("SPF 적용: \(record.isSPFApplied ? "예" : "아니오")")
                    .font(.caption)
                    .foregroundColor(.purple)

                Spacer()

                Text(
                    "날짜: \(record.startDate.formatted(date: .abbreviated, time: .omitted))"
                )
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
