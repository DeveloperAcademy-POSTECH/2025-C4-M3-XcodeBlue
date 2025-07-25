//
//  GetCurrentLocationWeatherUseCase.swift
//  TarTanning
//
//  Created by taeni on 7/25/25.
//

/**
 목적: 현재 위치의 실시간 날씨 및 UV 정보 제공
 입력: 현재 위치 (위도, 경도)
 출력: UV지수, 온도, 시간별 예보
 비즈니스 로직:

 위치 권한 확인 → WeatherKit 호출
 UV지수 카테고리 분류 (낮음/보통/높음/매우높음/위험)
 */

import Foundation
import SwiftData

final class GetCurrentLocationWeatherUseCase {
    private let weatherManager: WeatherKitManager
    private let modelContext: ModelContext
    
    init(weatherManager: WeatherKitManager = .shared, modelContext: ModelContext) {
        self.weatherManager = weatherManager
        self.modelContext = modelContext
    }
    
    func execute() async throws -> LocationWeather {
        // 1. 날짜 변경 확인
        try await checkDateChange()
        
        // 2. 위치 변경 확인
        try await checkLocationChange()
        
        // 3. 저장된 데이터 반환
        return try await getSavedLocationWeather()
    }
    
    // 날짜 변경 확인 및 처리
    private func checkDateChange() async throws {
        let lastSavedDate = try await getLastSavedDate()
        let today = Date()
        
        if !Calendar.current.isDate(lastSavedDate, inSameDayAs: today) {
            print("📅 날짜 변경 감지: 새로운 UV 데이터 저장")
            try await saveNewUVData()
        }
    }
    
    // 위치 변경 확인 및 처리
    private func checkLocationChange() async throws {
        let savedCity = try await getLastSavedCity()
        let currentCity = LocationInfo.mockSeoul.city // 현재는 mock
        
        if savedCity != currentCity {
            print("📍 위치 변경 감지: \(savedCity) → \(currentCity)")
            try await saveNewUVData()
        }
    }
    
    // 새로운 UV 데이터 저장
    private func saveNewUVData() async throws {
        let mockLocation = LocationInfo.mockSeoul
        
        // 기존 데이터 삭제
        try await deleteOldData()
        
        // 새로운 데이터 저장
        let locationWeather = try await weatherManager.fetchLocationWeather(for: mockLocation)
        modelContext.insert(locationWeather)
        
        try modelContext.save()
        print("✅ 새로운 UV 데이터 저장 완료")
    }
    
    // 저장된 LocationWeather 반환
    private func getSavedLocationWeather() async throws -> LocationWeather {
        let today = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<LocationWeather>(
            predicate: #Predicate {
                $0.date >= startOfDay && $0.date < endOfDay
            }
        )
        let data = try modelContext.fetch(descriptor)
        
        if let locationWeather = data.first {
            return locationWeather
        } else {
            // 저장된 데이터가 없으면 새로 생성
            try await saveNewUVData()
            return try await getSavedLocationWeather()
        }
    }
    
    // 헬퍼 메서드들
    private func getLastSavedDate() async throws -> Date {
        let descriptor = FetchDescriptor<LocationWeather>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let data = try modelContext.fetch(descriptor)
        return data.first?.date ?? Date.distantPast
    }
    
    private func getLastSavedCity() async throws -> String {
        let descriptor = FetchDescriptor<LocationWeather>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let data = try modelContext.fetch(descriptor)
        return data.first?.city ?? "알 수 없음"
    }
    
    private func deleteOldData() async throws {
        let today = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<LocationWeather>(
            predicate: #Predicate {
                $0.date >= startOfDay && $0.date < endOfDay
            }
        )
        let existingData = try modelContext.fetch(descriptor)
        
        for data in existingData {
            modelContext.delete(data)
        }
    }
}
