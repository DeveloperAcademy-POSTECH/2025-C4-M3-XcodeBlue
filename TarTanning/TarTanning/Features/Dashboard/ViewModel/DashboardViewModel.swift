//
//  DashboardViewModel.swift
//  TarTanning
//
//  Created by taeni on 7/25/25.
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
final class DashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties (UI State)
    @Published var todayMEDProgress: Double = 0.0
    @Published var weeklyMEDProgress: [Double] = []
    @Published var currentUVIndex: Int = 0
    @Published var currentTemperature: Int = 0
    @Published var todayTotalSunlightMinutes: Int = 0
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    // TODO: - UVExposureService 기능 구현 후 적용
//    private let uvService = UVExposureService.shared
    private var modelContext: ModelContext?
    
    // MARK: - User Settings
    private var userSkinType: SkinType {
        let rawValue = UserDefaults.standard.integer(forKey: "selectedSkinType")
        return SkinType(rawValue: rawValue) ?? .type3
    }
    
    // MARK: - Computed Properties for UI
    var todayMEDPercentage: Int {
        Int(todayMEDProgress * 100)
    }
    
    var uvStatusText: String {
        switch todayMEDProgress {
        case 0.0..<0.3: return "안전"
        case 0.3..<0.5: return "주의"
        case 0.5..<0.7: return "위험"
        default: return "매우 위험"
        }
    }
    
    var uvStatusColor: Color {
        switch todayMEDProgress {
        case 0.0..<0.3: return .blue
        case 0.3..<0.5: return .orange
        case 0.5..<0.7: return .red
        default: return .red
        }
    }
    
    var uvAdviceText: String {
        switch todayMEDProgress {
        case 0.0..<0.3: return "적당한 야외활동을 즐기세요!"
        case 0.3..<0.5: return "자외선 차단제를 사용하세요!"
        case 0.5..<0.7: return "야외활동을 자제하세요!"
        default: return "즉시 실내로 이동하세요!"
        }
    }
    
    // MARK: - Initialization
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Main Data Loading
    func loadDashboardData() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. 오늘의 MED 진행률 가져오기
            
            // TODO: - UVExposureService 기능 구현 후 적용
//            let todayProgress = await uvService.getCurrentMEDProgress()
            
            // 2. 주간 MED 진행률 가져오기
            let weeklyProgress = try await fetchWeeklyMEDProgress()
            
            // 3. 오늘의 일광시간 가져오기
            let todaySunlight = try await fetchTodaySunlightMinutes()
            
            // 4. 현재 날씨 정보 가져오기
            let (uvIndex, temperature) = try await fetchCurrentWeatherInfo()
            
            // UI 업데이트
            // TODO: - UVExposureService 기능 구현 후 적용
            self.todayMEDProgress = 0.3 //임시임
            self.weeklyMEDProgress = weeklyProgress
            self.todayTotalSunlightMinutes = todaySunlight
            self.currentUVIndex = uvIndex
            self.currentTemperature = temperature
            
        } catch {
            errorMessage = "데이터 로딩 실패: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Refresh Data
    func refreshData() async {
        // UV 서비스 수동 업데이트 후 대시보드 데이터 다시 로드
        // TODO: - UVExposureService 기능 구현 후 적용
//        await uvService.manualRefresh()
        await loadDashboardData()
    }
    
    // MARK: - Private Data Fetching Methods
    
    /// 주간 MED 진행률 가져오기 (최근 7일)
    private func fetchWeeklyMEDProgress() async throws -> [Double] {
        guard let context = modelContext else { return [] }
        
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        
        let descriptor = FetchDescriptor<DailyUVExpose>(
            predicate: #Predicate { daily in
                daily.date >= weekAgo && daily.date <= today
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        let weeklyData = try context.fetch(descriptor)
        let maxMED = userSkinType.maxMED
        
        // 최근 7일간의 진행률 계산 (없는 날은 0으로 처리)
        var progressArray: [Double] = []
        
        for dayOffset in (0..<7).reversed() {
            let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            
            if let dailyData = weeklyData.first(where: {
                calendar.isDate($0.date, inSameDayAs: targetDate)
            }) {
                let progress = maxMED > 0 ? dailyData.totalUVDose / maxMED : 0.0
                progressArray.append(progress)
            } else {
                progressArray.append(0.0)
            }
        }
        
        return progressArray
    }
    
    /// 오늘의 총 일광시간 가져오기
    private func fetchTodaySunlightMinutes() async throws -> Int {
        guard let context = modelContext else { return 0 }
        
        let today = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let descriptor = FetchDescriptor<DailyUVExpose>(
            predicate: #Predicate { daily in
                daily.date >= startOfDay && daily.date < endOfDay
            }
        )
        
        if let todayData = try context.fetch(descriptor).first {
            return Int(todayData.totalSunlightMinutes)
        }
        
        return 0
    }
    
    /// 현재 날씨 정보 (UV 지수, 온도) 가져오기 - DailyWeatherCache 사용
    private func fetchCurrentWeatherInfo() async throws -> (uvIndex: Int, temperature: Int) {
        guard let context = modelContext else { return (0, 0) }
        
        // 오늘 날씨 캐시 데이터 찾기
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyWeatherCache>(
            predicate: #Predicate { weather in
                weather.currentDate >= today
            }
        )
        
        // 오늘 날씨 데이터가 있으면 현재 시간의 UV/온도 반환
        if let todayWeather = try context.fetch(descriptor).first {
            return (Int(todayWeather.currentUVIndex), Int(todayWeather.currentTemperature))
        }
        
        // 데이터가 없으면 기본값 반환
        return (0, 0)
    }
    
    // MARK: - User Actions
    
    /// 수동 새로고침 (Pull-to-refresh용)
    func handlePullToRefresh() async {
        await refreshData()
    }
    
    /// 선크림 모드 시작
    func startSunscreenMode() {
        TimerSyncManager.shared.start(duration: 120 * 60) // 2시간
    }
    
    /// 에러 메시지 클리어
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Debugging & Logging
    func logCurrentState() {
        print("=== Dashboard State ===")
        print("오늘 MED 진행률: \(todayMEDPercentage)%")
        print("주간 MED 진행률: \(weeklyMEDProgress.map { Int($0 * 100) })")
        print("현재 UV 지수: \(currentUVIndex)")
        print("현재 온도: \(currentTemperature)°C")
        print("오늘 일광시간: \(todayTotalSunlightMinutes)분")
        print("사용자 피부타입: \(userSkinType.romanNumeral)")
        print("====================")
    }
}

// MARK: - Extensions for UI Helpers

extension DashboardViewModel {
    
    /// 주간 데이터가 있는지 확인
    var hasWeeklyData: Bool {
        !weeklyMEDProgress.isEmpty && weeklyMEDProgress.contains { $0 > 0 }
    }
    
    /// 오늘 데이터가 있는지 확인
    var hasTodayData: Bool {
        todayMEDProgress > 0 || todayTotalSunlightMinutes > 0
    }
    
    /// 로딩 상태가 아닌지 확인
    var isDataReady: Bool {
        !isLoading
    }
    
    /// 주간 요약용 데이터 구조체 배열
    var weeklyDisplayData: [WeeklyDayData] {
        return weeklyMEDProgress.enumerated().map { index, progress in
            let dayString = index == 6 ? "오늘" : "\(6-index)일 전"
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
        case 0.0..<0.3: return (.blue, "😆")
        case 0.3..<0.7: return (.orange, "🙂")
        case 0.7..<1.0: return (.red, "😔")
        default: return (.black, "🔥")
        }
    }
}

// MARK: - Additional Weather Helpers

extension DashboardViewModel {
    
    /// 특정 시간의 UV 지수 가져오기 (UVExposureService에서 사용)
    func getUVIndex(at hour: Int) async -> Double {
        guard let context = modelContext else { return 0.0 }
        
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyWeatherCache>(
            predicate: #Predicate { weather in
                weather.currentDate >= today
            }
        )
        
        do {
            if let todayWeather = try context.fetch(descriptor).first {
                return todayWeather.uvIndex(at: hour)
            }
        } catch {
            print("UV 지수 조회 실패: \(error)")
        }
        
        return 0.0
    }
    
    /// 시간 범위의 평균 UV 지수 가져오기
    func getAverageUVIndex(from startHour: Int, to endHour: Int) async -> Double {
        guard let context = modelContext else { return 0.0 }
        
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyWeatherCache>(
            predicate: #Predicate { weather in
                weather.currentDate >= today
            }
        )
        
        do {
            if let todayWeather = try context.fetch(descriptor).first {
                return todayWeather.averageUVIndex(from: startHour, to: endHour)
            }
        } catch {
            print("평균 UV 지수 조회 실패: \(error)")
        }
        
        return 0.0
    }
    
    /// 오늘 날씨 캐시가 있는지 확인
    var hasTodayWeatherCache: Bool {
        guard let context = modelContext else { return false }
        
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyWeatherCache>(
            predicate: #Predicate { weather in
                weather.currentDate >= today
            }
        )
        
        do {
            let results = try context.fetch(descriptor)
            return !results.isEmpty
        } catch {
            return false
        }
    }
    
    /// 현재 도시 정보 가져오기
    var currentCity: String {
        guard let context = modelContext else { return "알 수 없음" }
        
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyWeatherCache>(
            predicate: #Predicate { weather in
                weather.currentDate >= today
            }
        )
        
        do {
            if let todayWeather = try context.fetch(descriptor).first {
                return todayWeather.city
            }
        } catch {
            print("도시 정보 조회 실패: \(error)")
        }
        
        return "알 수 없음"
    }
    
    /// 일출/일몰 시간 정보
    var sunTimes: (sunrise: Date?, sunset: Date?) {
        guard let context = modelContext else { return (nil, nil) }
        
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyWeatherCache>(
            predicate: #Predicate { weather in
                weather.currentDate >= today
            }
        )
        
        do {
            if let todayWeather = try context.fetch(descriptor).first {
                return (todayWeather.sunrise, todayWeather.sunset)
            }
        } catch {
            print("일출/일몰 정보 조회 실패: \(error)")
        }
        
        return (nil, nil)
    }
}
