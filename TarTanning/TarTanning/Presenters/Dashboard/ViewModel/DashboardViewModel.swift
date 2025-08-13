//
//  DashboardViewModel.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import Combine
import Foundation
import SwiftData
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentWeather: LocationWeather?
    @Published var todayTotalSunlightMinutes: Int = 0
    @Published var todayUVExposure: DailyUVExpose?
    @Published var todayMEDValue: Double = 0.0
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies
    let modelContext: ModelContext

    // MARK: - Private Properties
    private var currentLocation = LocationInfo.mockPohang
    private var cancellables = Set<AnyCancellable>()
    private var isHealthKitSyncing = false
    private var lastHealthKitSyncTime: Date = Date.distantPast

    // 캐시된 사용자 프로필 (중복 호출 방지)
    private var cachedUserProfile: UserProfile?

    // WatchConnectivity 관련 private properties
    private var lastWatchSyncTime: Date = Date.distantPast
    private let watchSyncDebounceInterval: TimeInterval = 1.0

    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext

        // HealthKit 관찰 시작
        HealthKitQueryFetchManager.shared.startObservingHealthKitUpdates()
    }

    deinit {
        // HealthKit 관찰 중지
        Task { @MainActor in
            HealthKitQueryFetchManager.shared.stopObservingHealthKitUpdates()
        }

        // 알림 구독 해제
        NotificationCenter.default.removeObserver(self)

        // Combine 구독 해제
        cancellables.removeAll()
    }

    // MARK: - Computed Properties
    var currentCityName: String {
        return currentWeather?.city ?? currentLocation.city
    }

    // MARK: - WatchConnectivity Integration
    #if os(iOS)
        private func setupWatchConnectivityMessageHandling() {
            WatchConnectivityManager.shared.messageFromWatchPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] message in
                    self?.handleWatchMessage(message)
                }
                .store(in: &cancellables)

            print(
                "📱 [DashboardViewModel] Watch message handling setup completed"
            )
        }

        private func handleWatchMessage(_ message: [String: Any]) {
            // 대시보드 데이터 동기화 요청 처리
            if message["request_dashboard_sync"] as? Bool == true {
                print(
                    "📱 [DashboardViewModel] Received dashboard sync request from Watch"
                )
                return
            }

            // 기타 메시지 처리 (필요 시 확장)
            print(
                "📱 [DashboardViewModel] Received unhandled message from Watch: \(message)"
            )
        }
    #endif

    // MARK: - Weather Feature Methods

    /// 날씨 데이터 로드
    func loadWeatherData() {
        isLoading = true
        errorMessage = nil

        print(
            "🔄 [DashboardViewModel] Loading weather data for \(currentLocation.city)"
        )

    }

    /// 비동기 날씨 데이터 로드 (async/await 버전)
    @MainActor func loadWeatherDataAsync() async {
        isLoading = true
        errorMessage = nil

        print(
            "🔄 [DashboardViewModel] Loading weather data async for \(currentLocation.city)"
        )
    }

    // MARK: - UV Exposure Feature Methods

    /// UV 노출량 데이터 로드
    func loadUVExposureData() {
        print("🔄 [DashboardViewModel] Loading UV exposure data")
    }

    /// UV Dose 재계산 (기존 데이터에 대한 UV Dose 업데이트)
    func recalculateUVDose() {
        print("🧮 [DashboardViewModel] Recalculating UV dose from SwiftData")
    }

    // MARK: - Dashboard Orchestration Methods

    /// 모든 대시보드 데이터 로드 (Weather + UV Exposure)
    func loadAllDashboardData() {
        Task { @MainActor in
            // 1. 날씨 데이터 먼저 로드 (UV Dose 계산을 위해 필요)
            await loadWeatherDataAsync()

            // 2. UV 노출량 데이터 로드 (이미 UV Dose 계산 포함)
            loadUVExposureData()
        }
    }
    
    /// 특정 날짜의 UV 진행률 계산
    private func getUVProgressRate(for date: Date, maxMED: Double) -> Double {
        // SwiftData에서 해당 날짜의 DailyUVExpose 조회
        let descriptor = FetchDescriptor<DailyUVExpose>()

        do {
            let allDailyData = try modelContext.fetch(descriptor)
            let targetDaily = allDailyData.first { daily in
                Calendar.current.isDate(daily.date, inSameDayAs: date)
            }

            guard let dailyUV = targetDaily else { return 0.0 }

            let progressRate = dailyUV.totalUVDose / maxMED
            return min(max(progressRate, 0.0), 1.0)

        } catch {
            print(
                "❌ [DashboardViewModel] Failed to fetch UV progress for \(date): \(error)"
            )
            return 0.0
        }
    }
    
    // MARK: - Private Helper Methods

    /// 일출/일몰 시간으로 일광시간 계산
    private func calculateTotalSunlightMinutes() {
        guard let weather = currentWeather,
            let sunrise = weather.sunriseTime,
            let sunset = weather.sunsetTime
        else {
            todayTotalSunlightMinutes = 0
            return
        }

        let sunlightDuration = sunset.timeIntervalSince(sunrise)
        todayTotalSunlightMinutes = Int(sunlightDuration / 60)  // 분 단위로 변환
    }
    // MARK: - Debug & Utility Methods

    /// 상세 SwiftData 상태 로그 출력
    func logDetailedSwiftDataStatus() {
        Task { @MainActor in
            do {
                let locationDescriptor = FetchDescriptor<LocationWeather>()
                let hourlyDescriptor = FetchDescriptor<HourlyWeather>()
                let dailyDescriptor = FetchDescriptor<DailyUVExpose>()
                let recordDescriptor = FetchDescriptor<UVExposeRecord>()

                let allLocationData = try modelContext.fetch(locationDescriptor)
                let allHourlyData = try modelContext.fetch(hourlyDescriptor)
                let allDailyData = try modelContext.fetch(dailyDescriptor)
                let allRecordData = try modelContext.fetch(recordDescriptor)

                print("\n📊 [DashboardViewModel] 상세 SwiftData 상태:")
                print("==========================================")
                print("🌍 LocationWeather: \(allLocationData.count)개")
                print("⏰ HourlyWeather: \(allHourlyData.count)개")
                print("📅 DailyUVExpose: \(allDailyData.count)개")
                print("📝 UVExposeRecord: \(allRecordData.count)개")

                // 현재 날씨 상태
                if let current = currentWeather {
                    print("\n🌤️ 현재 날씨:")
                    print("   • 도시: \(current.city)")
                    print(
                        "   • 날짜: \(current.date.formatted(date: .abbreviated, time: .omitted))"
                    )
                    print("   • 시간별 데이터: \(current.hourlyWeathers.count)개")
                    print(
                        "   • 연결 상태: \(WatchConnectivityManager.shared.isReachable ? "연결됨" : "연결 안됨")"
                    )
                }

                // 관계 검증
                print("\n🔗 관계 검증:")
                for location in allLocationData {
                    let orphanedHourly = allHourlyData.filter {
                        $0.locationWeather?.id != location.id
                    }
                    if !orphanedHourly.isEmpty {
                        print("⚠️ 고아 HourlyWeather 발견: \(orphanedHourly.count)개")
                    }

                    let duplicateHours = Dictionary(
                        grouping: location.hourlyWeathers,
                        by: { $0.hour }
                    )
                    .filter { $0.value.count > 1 }
                    if !duplicateHours.isEmpty {
                        print("⚠️ 중복 시간 발견: \(duplicateHours.keys.sorted())")
                    }
                }

                print("\n✅ SwiftData 상태 확인 완료")

            } catch {
                print("❌ SwiftData 상태 확인 실패: \(error)")
            }
        }
    }
}
