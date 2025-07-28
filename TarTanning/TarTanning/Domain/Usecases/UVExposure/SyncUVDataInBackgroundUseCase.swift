//
//  SyncUVDataInBackgroundUseCase.swift
//  TarTanning
//
//  Created by J on 7/28/25.
//

import Foundation
import SwiftData

struct SyncUVDataInBackgroundUseCase {
    let context: ModelContext

    @MainActor
    func execute() async {
        print("🚀 [SyncUVDataInBackgroundUseCase] 실행 시작됨")

        do {
            print("🌤️ [Step 1] 날씨 데이터 동기화 시작")
            let weather = try await SyncWeatherDataUseCase(modelContext: context)
                .syncWeatherData(for: LocationInfo.mockPohang, type: .backgroundSync)
            print("✅ [Step 1] 날씨 데이터 동기화 성공 - 시간별 \(weather.hourlyWeathers.count)개")

            var uvMap: [Int: Double] = [:]
            for hour in weather.hourlyWeathers {
                uvMap[hour.hour] = hour.uvIndex
            }
            print("📊 [Step 1] UV Map 구성 완료: \(uvMap)")

            print("🩺 [Step 2] HealthKit 데이터 동기화 시작")
            try await SyncUVDataFromHealthKitUseCase(modelContext: context)
                .syncTodaySunlightFromHealthKit()
            print("✅ [Step 2] HealthKit 데이터 동기화 완료")

            print("🧮 [Step 3] UV Dose 계산 및 저장 시작")
            try await CalculateAndSaveUVDoseUseCase(modelContext: context)
                .calculateAndSaveTodayUVDose(uvIndexData: uvMap)
            print("✅ [Step 3] UV Dose 계산 및 저장 완료")

            print("🎉 [SyncUVDataInBackgroundUseCase] 전체 백그라운드 작업 완료")

        } catch {
            print("❌ [SyncUVDataInBackgroundUseCase] 백그라운드 UV 싱크 실패: \(error)")
        }
    }
}
