//
//  HealthKitTestViewModel.swift
//  TarTanning
//
//  Created by taeni on 7/15/25.
//

import HealthKit
import SwiftUI

@MainActor
final class HealthKitTestViewModel: ObservableObject {
    // Managers
    private let authManager = HealthKitAuthorizationManager()
    private let backgroundManager = HealthKitBackgroundManager()
    private let dataQueryManager = HealthKitDataQueryManager()
    private let queryManager = HealthKitQueryManager()
    
    @Published var isAuthorized = false
    @Published var isBackgroundEnabled = false
    @Published var todaysDaylight: Double = 0
    @Published var weeklyTrend: [DaylightStatistic] = []
    @Published var monthlyTrend: [DaylightStatistic] = []
    @Published var latestSample: HKQuantitySample?
    @Published var statusMessage = "HealthKit 매니저 테스트 준비 완료"
    @Published var isLoading = false
    @Published var customRangeMinutes: Double = 0
    
    // Computed properties for UI
    var currentAuthStatus: HealthKitAuthStatus {
        authManager.authorizationStatus
    }
    
    var isHealthKitAvailable: Bool {
        authManager.isHealthDataAvailable
    }
    
    init() {
        setupDelegates()
        // 앱 시작 시 권한 상태 확인
        checkAuthorizationStatus()
    }
    
    private func setupDelegates() {
        authManager.delegate = self
        backgroundManager.delegate = self
        dataQueryManager.delegate = self
        queryManager.delegate = self
    }
    
    func checkAuthorizationStatus() {
        statusMessage = "권한 상태 확인 중..."
        authManager.checkAuthorizationStatusWithCompletion()
    }
    
    func testAuthorization() {
        isLoading = true
        statusMessage = "HealthKit 권한 요청 중..."
        Task {
            await authManager.requestAuthorization()
        }
    }
    
    func testBackgroundDelivery() {
        guard let daylightType = HKQuantityType.quantityType(forIdentifier: .timeInDaylight) else {
            statusMessage = "일광 타입을 가져올 수 없습니다"
            return
        }
        
        isLoading = true
        statusMessage = "백그라운드 전송 활성화 중..."
        Task {
            await backgroundManager.enableBackgroundDelivery(for: daylightType, frequency: .immediate)
        }
    }
    
    func testTodaysDataFromDataManager() {
        isLoading = true
        statusMessage = "오늘의 일광 데이터 가져오는 중 (DataQueryManager)..."
        Task {
            await dataQueryManager.fetchTodaysDaylightExposure()
        }
    }
    
    func testTodaysDataFromQueryManager() {
        isLoading = true
        statusMessage = "오늘의 일광 데이터 가져오는 중 (QueryManager)..."
        Task {
            await queryManager.fetchTodaysDaylightExposure()
        }
    }
    
    func testWeeklyTrendFromDataManager() {
        isLoading = true
        statusMessage = "주간 트렌드 가져오는 중 (DataQueryManager)..."
        Task {
            await dataQueryManager.fetchWeeklyDaylightTrend()
        }
    }
    
    func testWeeklyTrendFromQueryManager() {
        isLoading = true
        statusMessage = "주간 트렌드 가져오는 중 (QueryManager)..."
        Task {
            await queryManager.fetchWeeklyDaylightTrend()
        }
    }
    
    func testMonthlyTrend() {
        isLoading = true
        statusMessage = "월간 트렌드 가져오는 중..."
        Task {
            await queryManager.fetchMonthlyDaylightTrend()
        }
    }
    
    func testLatestSample() {
        isLoading = true
        statusMessage = "최신 샘플 가져오는 중..."
        Task {
            await queryManager.fetchLatestDaylightSample()
        }
    }
    
    func testCustomDateRange() {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -3, to: endDate)!
        
        isLoading = true
        statusMessage = "사용자 정의 날짜 범위 가져오는 중 (최근 3일)..."
        Task {
            await queryManager.fetchDaylightExposure(from: startDate, to: endDate)
        }
    }
    
    func setupObserver() {
        guard let daylightType = HKQuantityType.quantityType(forIdentifier: .timeInDaylight) else {
            statusMessage = "일광 타입을 가져올 수 없습니다"
            return
        }
        
        statusMessage = "관찰자 쿼리 설정 중..."
        backgroundManager.setupObserverQuery(for: daylightType)
        statusMessage = "관찰자 쿼리 설정 완료"
    }
    
    func disableBackgroundDelivery() {
        guard let daylightType = HKQuantityType.quantityType(forIdentifier: .timeInDaylight) else {
            statusMessage = "일광 타입을 가져올 수 없습니다"
            return
        }
        
        isLoading = true
        statusMessage = "백그라운드 전송 비활성화 중..."
        Task {
            await backgroundManager.disableBackgroundDelivery(for: daylightType)
        }
    }
    
    func stopObservers() {
        backgroundManager.stopAllObserverQueries()
        statusMessage = "모든 관찰자 쿼리 중지됨"
    }
    
    func clearResults() {
        todaysDaylight = 0
        weeklyTrend = []
        monthlyTrend = []
        latestSample = nil
        customRangeMinutes = 0
        statusMessage = "모든 결과가 초기화됨"
    }
}

// MARK: - Delegate Extensions
extension HealthKitTestViewModel: HealthKitAuthorizationManagerDelegate {
    func healthKitAuthorizationDidSucceed() {
        isLoading = false
        isAuthorized = true
        statusMessage = "권한 승인 성공"
    }
    
    func healthKitAuthorizationDidFail(with error: Error) {
        isLoading = false
        isAuthorized = false
        statusMessage = "권한 승인 실패: \(error.localizedDescription)"
    }
    
    func healthKitAuthorizationStatusDidUpdate(_ status: HealthKitAuthStatus) {
        switch status {
        case .notDetermined:
            statusMessage = "권한 상태: 아직 요청하지 않음"
        case .denied:
            statusMessage = "권한 상태: 사용자가 거부함 - 설정에서 변경 가능"
        case .authorized:
            statusMessage = "권한 상태: 허용됨"
        case .notAvailable:
            statusMessage = "권한 상태: HealthKit 사용 불가"
        }
        
        isAuthorized = status == .authorized
    }
}

extension HealthKitTestViewModel: HealthKitBackgroundManagerDelegate {
    func backgroundDeliveryDidEnable(for type: HKObjectType) {
        isLoading = false
        isBackgroundEnabled = true
        statusMessage = "\(type)에 대한 백그라운드 전송 활성화됨"
    }
    
    func backgroundDeliveryDidDisable(for type: HKObjectType) {
        isLoading = false
        isBackgroundEnabled = false
        statusMessage = "\(type)에 대한 백그라운드 전송 비활성화됨"
    }
    
    func observerQueryDidUpdate(for type: HKSampleType) {
        statusMessage = "\(type)에 대한 관찰자 쿼리 업데이트됨 - 새 데이터 감지됨"
        Task {
            await queryManager.fetchLatestDaylightSample()
        }
    }
    
    func healthKitBackgroundServiceDidFail(with error: HealthKitError) {
        isLoading = false
        statusMessage = "백그라운드 서비스 실패: \(error.localizedDescription)"
    }
}

extension HealthKitTestViewModel: HealthKitDataQueryManagerDelegate {
    func dataQueryDidFetchTodaysDaylight(_ minutes: Double) {
        isLoading = false
        todaysDaylight = minutes
        statusMessage = "DataQueryManager - 오늘의 일광 노출: \(String(format: "%.1f", minutes)) 분"
    }
    
    func dataQueryDidFetchWeeklyTrend(_ statistics: [DaylightStatistic]) {
        isLoading = false
        weeklyTrend = statistics
        let totalMinutes = statistics.reduce(0) { $0 + $1.minutes }
        statusMessage = "DataQueryManager - 주간 트렌드: \(statistics.count)일, 총합: \(String(format: "%.1f", totalMinutes)) 분"
    }
    
    func dataQueryDidFail(with error: HealthKitError) {
        isLoading = false
        statusMessage = "DataQueryManager 실패: \(error.localizedDescription)"
    }
}

extension HealthKitTestViewModel: HealthKitQueryManagerDelegate {
    func queryServiceDidFetchTodaysDaylight(_ minutes: Double) {
        isLoading = false
        todaysDaylight = minutes
        statusMessage = "QueryManager - 오늘의 일광 노출: \(String(format: "%.1f", minutes)) 분"
    }
    
    func queryServiceDidFetchDaylightExposure(_ minutes: Double, from startDate: Date, to endDate: Date) {
        isLoading = false
        customRangeMinutes = minutes
        statusMessage = "사용자 정의 기간 (\(DateFormatter.shortDate.string(from: startDate)) - \(DateFormatter.shortDate.string(from: endDate))): \(String(format: "%.1f", minutes)) 분"
    }
    
    func queryServiceDidFetchLatestSample(_ sample: HKQuantitySample?) {
        isLoading = false
        latestSample = sample
        if let sample = sample {
            let minutes = sample.quantity.doubleValue(for: HKUnit.minute())
            statusMessage = "최신 샘플: \(String(format: "%.1f", minutes)) 분 (\(DateFormatter.shortDateTime.string(from: sample.startDate)))"
        } else {
            statusMessage = "샘플을 찾을 수 없음"
        }
    }
    
    func queryServiceDidFetchWeeklyTrend(_ statistics: [DaylightStatistic]) {
        isLoading = false
        weeklyTrend = statistics
        let totalMinutes = statistics.reduce(0) { $0 + $1.minutes }
        statusMessage = "QueryManager - 주간 트렌드: \(statistics.count)일, 총합: \(String(format: "%.1f", totalMinutes)) 분"
    }
    
    func queryServiceDidFetchMonthlyTrend(_ statistics: [DaylightStatistic]) {
        isLoading = false
        monthlyTrend = statistics
        let totalMinutes = statistics.reduce(0) { $0 + $1.minutes }
        statusMessage = "월간 트렌드: \(statistics.count)일, 총합: \(String(format: "%.1f", totalMinutes)) 분"
        
    }
    
    func queryServiceDidFetchMultipleDateRanges(_ statistics: [DaylightStatistic]) {
        isLoading = false
        let totalMinutes = statistics.reduce(0) { $0 + $1.minutes }
        statusMessage = "복수 날짜 범위: \(statistics.count)개 기간, 총합: \(String(format: "%.1f", totalMinutes)) 분"
    }
    
    func queryServiceDidFail(with error: HealthKitError) {
        isLoading = false
        statusMessage = "QueryManager 실패: \(error.localizedDescription)"
    }
}
