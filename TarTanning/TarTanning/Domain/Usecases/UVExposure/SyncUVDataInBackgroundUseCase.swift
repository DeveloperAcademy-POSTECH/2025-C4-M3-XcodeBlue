//
//  SyncUVDataInBackgroundUseCase.swift
//  TarTanning
//
//  Created by J on 7/28/25.
//

import Foundation
import SwiftData

@MainActor
struct SyncUVDataInBackgroundUseCase {
    let context: ModelContext

    func execute() async {
        print("🚀 [SyncUVDataInBackgroundUseCase] 백그라운드 UV 동기화 시작")

        do {
            let weather = try await syncWeather()
            try await syncHealthKit()
            try await calculateUVDose()

            try await handleMEDWarning(weather: weather)

            print("🎉 [SyncUVDataInBackgroundUseCase] 전체 백그라운드 작업 완료")
        } catch {
            print("❌ [SyncUVDataInBackgroundUseCase] 실패: \(error)")
        }
    }

    // MARK: - Step 1: Weather
    private func syncWeather() async throws -> LocationWeather {
        print("🌤️ [Step 1] 날씨 동기화 시작")
        let weather = try await SyncWeatherDataUseCase(modelContext: context)
            .syncWeatherData(for: LocationInfo.mockPohang, type: .backgroundSync)

        print("✅ [Step 1] 동기화 성공 - 시간별 \(weather.hourlyWeathers.count)개")
        return weather
    }

    // MARK: - Step 2: HealthKit
    private func syncHealthKit() async throws {
        print("🩺 [Step 2] HealthKit 데이터 동기화")
        try await SyncUVDataFromHealthKitUseCase(modelContext: context).syncTodaySunlightFromHealthKit()
        print("✅ [Step 2] 완료")
    }

    // MARK: - Step 3: UV Dose
    private func calculateUVDose() async throws {
        print("🧮 [Step 3] UV Dose 계산 및 저장")
        try await CalculateAndSaveUVDoseUseCase(modelContext: context).calculateAndSaveTodayUVDose()
        print("✅ [Step 3] 완료")
    }

    // MARK: - Step 4: MED Notification
    private func handleMEDWarning(weather: LocationWeather) async throws {
        print("📢 [Step 4] MED 경고 알림 체크")

        guard let dailyUV = try await GetTodayUVExposureUseCase(modelContext: context).getTodayDailyUVExposure() else {
            print("📭 [Step 4] 오늘 UV 데이터 없음 - 알림 스킵")
            return
        }

        guard let sunrise = weather.sunriseTime,
              let sunset = weather.sunsetTime else {
            print("⚠️ [Step 4] 일출/일몰 정보 없음 - 알림 스킵")
            return
        }

        let now = Date()
        guard now >= sunrise && now <= sunset else {
            print("🌙 [Step 4] 현재 야간 - 알림 스킵")
            return
        }

        let maxMED = GetUserProfileUseCase().getUserProfile().skinType.maxMED
        SendUVWarningNotificationUseCase(
            uvDose: dailyUV.totalUVDose,
            maxMED: maxMED
        ).execute()

        print("✅ [Step 4] MED 경고 알림 처리 완료")
    }
}
