//
//  DashboardViewModel+Debug.swift
//  TarTanning
//
//  Created by taeni on 7/28/25.
//

import Foundation
import SwiftData

// MARK: - Debug Feature Extension
extension DashboardViewModel {
    
    /// HealthKit 데이터 동기화 (디버그용)
    func syncHealthKitDataForDebug() async throws {
        try await syncUVDataFromHealthKitUseCase().syncTodaySunlightFromHealthKit()
    }
    
    /// UV Dose 계산 (디버그용)
    func calculateUVDoseForDebug() async throws {
        // 매개변수 제거
        try await calculateAndSaveUVDoseUseCase().calculateAndSaveTodayUVDose()
    }
    
    /// 모든 데이터 삭제 (디버그용)
    func clearAllData() {
        Task {
            do {
                try await syncWeatherDataUseCase().clearAllData()
                
                await MainActor.run {
                    self.currentWeather = nil
                    self.todayTotalSunlightMinutes = 0
                    print("🗑️ [DashboardViewModel] All data cleared")
                }
            } catch {
                print("❌ [DashboardViewModel] Failed to clear data: \(error)")
            }
        }
    }
    
    /// SwiftData 상세 상태 로그 (디버그용)
    func logDetailedSwiftDataStatus() {
        Task {
            do {
                print("📊 ===== SwiftData 상세 상태 =====")
                
                // LocationWeather 데이터
                let locationDescriptor = FetchDescriptor<LocationWeather>()
                let allLocationData = try modelContext.fetch(locationDescriptor)
                
                print("📍 LocationWeather 총 개수: \(allLocationData.count)")
                
                for (index, location) in allLocationData.enumerated() {
                    print("\n📍 LocationWeather[\(index)]:")
                    print("   • ID: \(location.id)")
                    print("   • 도시: \(location.city)")
                    print("   • 위도: \(location.latitude)")
                    print("   • 경도: \(location.longitude)")
                    print("   • 날짜: \(location.date.formatted(date: .abbreviated, time: .omitted))")
                    print("   • 일출: \(location.sunriseTime?.formatted(date: .omitted, time: .shortened) ?? "N/A")")
                    print("   • 일몰: \(location.sunsetTime?.formatted(date: .omitted, time: .shortened) ?? "N/A")")
                    print("   • 연결된 시간별 데이터: \(location.hourlyWeathers.count)개")
                }
                
                // HourlyWeather 데이터
                let hourlyDescriptor = FetchDescriptor<HourlyWeather>()
                let allHourlyData = try modelContext.fetch(hourlyDescriptor)
                
                print("\n🕐 HourlyWeather 총 개수: \(allHourlyData.count)")
                
                let sortedHourlyData = allHourlyData.sorted { $0.date < $1.date }
                
                for (index, hourly) in sortedHourlyData.enumerated() {
                    print("\n🕐 HourlyWeather[\(index)]:")
                    print("   • 시간: \(hourly.hour)시 (\(hourly.date.formatted(date: .omitted, time: .shortened)))")
                    print("   • 온도: \(hourly.temperature)°")
                    print("   • UV 지수: \(hourly.uvIndex)")
                    print("   • 연결된 위치: \(hourly.locationWeather?.city ?? "연결 안됨")")
                }
                
                // 관계 검증
                print("\n🔗 관계 검증:")
                for location in allLocationData {
                    let orphanedHourly = allHourlyData.filter { $0.locationWeather?.id != location.id }
                    if !orphanedHourly.isEmpty {
                        print("⚠️ 고아 HourlyWeather 발견: \(orphanedHourly.count)개")
                    }
                    
                    let duplicateHours = Dictionary(grouping: location.hourlyWeathers, by: { $0.hour })
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
