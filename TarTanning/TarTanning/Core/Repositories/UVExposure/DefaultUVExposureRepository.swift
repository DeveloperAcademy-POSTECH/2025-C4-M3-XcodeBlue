//
//  DefaultUVExposureRepository.swift
//  TarTanning
//
//  Created by Jun on 7/22/25.
//

import Foundation
import HealthKit

class DefaultUVExposureRepository: UVExposureRepository {
    private let fetchManager = HealthKitQueryFetchManager()
    private let weatherRepository: WeatherRepository
    
    init(weatherRepository: WeatherRepository) {
        self.weatherRepository = weatherRepository
    }
    
    func getTodayUVExposure() async throws -> DailyUVExpose {
        print("🔍 DEBUG: getTodayUVExposure 시작")
        
        // 1. HealthKit에서 일광시간 데이터 가져오기
        let samples = try await fetchTodaySamplesAsync()
        print("🔍 DEBUG: HealthKit에서 가져온 샘플 수: \(samples.count)")
        
        // 2. 오늘의 날씨 데이터 가져오기 (UV 지수 포함)
        let weather = try await weatherRepository.getCurrentWeather()
        print("🔍 DEBUG: 날씨 데이터 가져옴 - 시간별 UV 지수 개수: \(weather.hourlyWeathers.count)")
        
        // 3. 각 일광시간 샘플에 대해 UV 노출량 계산
        print("🔍 DEBUG: === UV 노출량 계산 시작 ===")
        
        let records = samples.enumerated().compactMap { (index, sample) -> UVExposeRecord? in
            let startHour = Calendar.current.component(.hour, from: sample.startDate)
            let startMinute = Calendar.current.component(.minute, from: sample.startDate)
            let endHour = Calendar.current.component(.hour, from: sample.endDate)
            let endMinute = Calendar.current.component(.minute, from: sample.endDate)
            
            // 해당 시간대의 평균 UV 지수 계산
            let uvIndex = calculateAverageUVIndex(
                from: startHour,
                to: endHour,
                hourlyWeathers: weather.hourlyWeathers
            )
            
            let duration = sample.quantity.doubleValue(for: .minute())
            
            // UV 노출량 계산 (선크림 미적용 가정)
            let uvDose = MEDCalculator.calculateUVDose(
                uvIndex: uvIndex,
                durationMinutes: duration,
                spf: nil
            )
            
            let record = UVExposeRecord(
                startDate: sample.startDate,
                endDate: sample.endDate,
                sunlightExposureDuration: duration,
                isSPFApplied: false
            )
            
            // 계산된 UV 노출량 설정
            record.uvDose = uvDose
            
            // 📊 상세한 계산 로그
            print("🔍 DEBUG: [\(index + 1)] 개별 일광시간 분석:")
            print("   📅 시간: \(startHour):\(String(format: "%02d", startMinute)) - \(endHour):\(String(format: "%02d", endMinute))")
            print("   ⏰ 지속시간: \(duration)분 (= \(duration * 60)초)")
            print("   ☀️ UV지수: \(uvIndex)")
            print("   🧮 계산식: UV지수(\(uvIndex)) × 0.025 × \(duration * 60)초 = \(uvDose) J/m²")
            print("   📊 UV노출량: \(String(format: "%.6f", uvDose)) J/m²")
            print("   ─────────────────────────────")
            
            return record
        }
        
        print("🔍 DEBUG: === UV 노출량 계산 완료 ===")
        
        let daily = DailyUVExpose(date: Date())
        daily.exposureRecords = records
        daily.totalSunlightMinutes = records.reduce(0) { $0 + $1.sunlightExposureDuration }
        daily.totalUVDose = records.reduce(0) { $0 + $1.uvDose }
        
        // 📊 최종 합계 로그
        print("🔍 DEBUG: === 최종 합계 ===")
        print("   📊 총 \(records.count)개 일광시간 기록")
        print("   ⏰ 총 일광시간: \(daily.totalSunlightMinutes)분")
        print("   ☀️ 총 UV 노출량: \(String(format: "%.6f", daily.totalUVDose)) J/m²")
        
        // 개별 기록들의 합계 검증
        let manualSum = records.map { $0.uvDose }.reduce(0, +)
        print("   🧮 수동 합계 검증: \(String(format: "%.6f", manualSum)) J/m²")
        print("   ✅ 합계 일치 여부: \(abs(daily.totalUVDose - manualSum) < 0.000001 ? "일치" : "불일치")")
        print("   ═══════════════════════════")
        
        return daily
    }

    func getWeeklyUVExposure() async throws -> [DailyUVExpose] {
        let calendar = Calendar.current
        let today = Date()
        var weeklyData: [DailyUVExpose] = []

        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            
            // 각 날짜별로 처리
            let samples = try await fetchSamplesAsync(for: date)
            
            // 해당 날짜의 날씨 정보 (실제로는 날짜별 날씨 API 필요)
            // 현재는 오늘 날씨로 대체 (향후 개선 필요)
            let weather = try await weatherRepository.getCurrentWeather()
            
            let records = samples.compactMap { sample -> UVExposeRecord? in
                let startHour = Calendar.current.component(.hour, from: sample.startDate)
                let endHour = Calendar.current.component(.hour, from: sample.endDate)
                
                let uvIndex = calculateAverageUVIndex(
                    from: startHour,
                    to: endHour,
                    hourlyWeathers: weather.hourlyWeathers
                )
                
                let duration = sample.quantity.doubleValue(for: .minute())
                let uvDose = MEDCalculator.calculateUVDose(
                    uvIndex: uvIndex,
                    durationMinutes: duration,
                    spf: nil
                )
                
                let record = UVExposeRecord(
                    startDate: sample.startDate,
                    endDate: sample.endDate,
                    sunlightExposureDuration: duration,
                    isSPFApplied: false
                )
                record.uvDose = uvDose
                
                return record
            }
            
            let daily = DailyUVExpose(date: date)
            daily.exposureRecords = records
            daily.totalSunlightMinutes = records.reduce(0) { $0 + $1.sunlightExposureDuration }
            daily.totalUVDose = records.reduce(0) { $0 + $1.uvDose }
            weeklyData.append(daily)
        }
        
        return weeklyData.reversed()
    }

    func getTodayUVProgressRate(userSkinType: SkinType) async throws -> Double {
        let todayExposure = try await getTodayUVExposure()
        let maxMED = userSkinType.maxMED
        guard maxMED > 0 else { return 0.0 }
        
        let progressRate = todayExposure.totalUVDose / maxMED
        print("🔍 DEBUG: UV 진행률 계산 - UV Dose: \(todayExposure.totalUVDose), Max MED: \(maxMED), 진행률: \(progressRate)")
        
        return progressRate
    }

    func getWeeklyUVProgressRates(userSkinType: SkinType) async throws -> [Double] {
        let weeklyExposure = try await getWeeklyUVExposure()
        let maxMED = userSkinType.maxMED
        return weeklyExposure.map { daily in
            guard maxMED > 0 else { return 0.0 }
            return daily.totalUVDose / maxMED
        }
    }

    func saveDailyUVExposure(_ dailyExposure: DailyUVExpose) async throws {
        // SwiftData context.insert(dailyExposure)
        // try? context.save()
    }

    func getDailyUVExposure(for date: Date) async throws -> DailyUVExpose? {
        let samples = try await fetchSamplesAsync(for: date)
        let weather = try await weatherRepository.getCurrentWeather()
        
        let records = samples.compactMap { sample -> UVExposeRecord? in
            let startHour = Calendar.current.component(.hour, from: sample.startDate)
            let endHour = Calendar.current.component(.hour, from: sample.endDate)
            
            let uvIndex = calculateAverageUVIndex(
                from: startHour,
                to: endHour,
                hourlyWeathers: weather.hourlyWeathers
            )
            
            let duration = sample.quantity.doubleValue(for: .minute())
            let uvDose = MEDCalculator.calculateUVDose(
                uvIndex: uvIndex,
                durationMinutes: duration,
                spf: nil
            )
            
            let record = UVExposeRecord(
                startDate: sample.startDate,
                endDate: sample.endDate,
                sunlightExposureDuration: duration,
                isSPFApplied: false
            )
            record.uvDose = uvDose
            
            return record
        }
        
        let daily = DailyUVExpose(date: date)
        daily.exposureRecords = records
        daily.totalSunlightMinutes = records.reduce(0) { $0 + $1.sunlightExposureDuration }
        daily.totalUVDose = records.reduce(0) { $0 + $1.uvDose }
        return daily
    }

    func updateDailyUVExposure(for date: Date) async throws {
        // SwiftData에서 해당 날짜의 DailyUVExpose를 갱신
    }

    // MARK: - Helper Methods
    
    /// 시간 범위에 대한 평균 UV 지수 계산
    private func calculateAverageUVIndex(
        from startHour: Int,
        to endHour: Int,
        hourlyWeathers: [HourlyWeather]
    ) -> Double {
        let hours = startHour == endHour ? [startHour] : Array(startHour...endHour)
        
        print("🔍 DEBUG: UV지수 조회 - 대상 시간: \(hours)")
        
        let uvIndexes = hours.compactMap { hour in
            let hourlyWeather = hourlyWeathers.first { $0.hour == hour }
            let uvIndex = hourlyWeather?.uvIndex ?? 0.0
            print("🔍 DEBUG: \(hour)시 UV지수: \(uvIndex)")
            return uvIndex > 0 ? uvIndex : nil
        }
        
        guard !uvIndexes.isEmpty else {
            print("🔍 DEBUG: ⚠️ 해당 시간대에 UV 지수 정보가 없음")
            return 0.0
        }
        
        let averageUV = uvIndexes.reduce(0, +) / Double(uvIndexes.count)
        print("🔍 DEBUG: 평균 UV지수 계산: \(uvIndexes) → 평균: \(averageUV)")
        
        return averageUV
    }
    
    private func fetchTodaySamplesAsync() async throws -> [HKQuantitySample] {
        try await fetchSamplesAsync(for: Date())
    }

    private func fetchSamplesAsync(for date: Date) async throws -> [HKQuantitySample] {
        print("🔍 DEBUG: fetchSamplesAsync 시작 - 날짜: \(date)")
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        print("🔍 DEBUG: 검색 범위 - 시작: \(startOfDay), 종료: \(endOfDay)")
        
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                let delegate = HealthKitQueryDelegate { result in
                    switch result {
                    case .success(let samples):
                        print("🔍 DEBUG: HealthKit 쿼리 성공 - 샘플 수: \(samples.count)")
                        for (index, sample) in samples.enumerated() {
                            let duration = sample.quantity.doubleValue(for: .minute())
                            print("🔍 DEBUG: 샘플 \(index + 1) - 시작: \(sample.startDate), 종료: \(sample.endDate), 시간: \(duration)분")
                        }
                        continuation.resume(returning: samples)
                    case .failure(let error):
                        print("🔍 DEBUG: HealthKit 쿼리 실패 - 에러: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
                
                self.fetchManager.delegate = delegate
                await self.fetchManager.fetchSamples(from: startOfDay, to: endOfDay)
            }
        }
    }
}

// MARK: - Improved Delegate
private class HealthKitQueryDelegate: HealthKitQueryFetchManagerDelegate {
    private let completion: (Result<[HKQuantitySample], Error>) -> Void
    
    init(completion: @escaping (Result<[HKQuantitySample], Error>) -> Void) {
        self.completion = completion
    }
    
    func fetchManagerDidFetchSamples(_ samples: [HKQuantitySample]) {
        completion(.success(samples))
    }
    
    func fetchManagerDidFail(with error: HealthKitError) {
        completion(.failure(error))
    }
}
