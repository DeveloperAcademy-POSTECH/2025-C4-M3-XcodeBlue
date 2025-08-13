//
//  HomeViewModel.swift
//  TarTanning
//
//  Created by taeni on 7/25/25.
//

import Foundation
import SwiftData

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var locationWeather: LocationWeather?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var savedDataCount: Int = 0
    
    private let getCurrentLocationWeatherUseCase: GetCurrentLocationWeatherUseCase
    
    init(modelContext: ModelContext) {
        self.getCurrentLocationWeatherUseCase = GetCurrentLocationWeatherUseCase(modelContext: modelContext)
    }
    
    func loadWeatherData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔄 Home 날씨 데이터 로딩 시작...")
            
            // UseCase를 통해 데이터 로드 (날짜/위치 변경 확인 포함)
            let weather = try await getCurrentLocationWeatherUseCase.execute()
            
            // 저장된 데이터 개수 확인
            await updateSavedDataCount()
            
            DispatchQueue.main.async {
                self.locationWeather = weather
                self.isLoading = false
                
                print("✅ Home 날씨 데이터 로딩 완료")
                print("📊 도시: \(weather.city)")
                print("📅 날짜: \(weather.date.formatted())")
                print("🌅 일출: \(weather.sunriseTime?.formatted() ?? "N/A")")
                print("🌇 일몰: \(weather.sunsetTime?.formatted() ?? "N/A")")
                print("⏰ 시간별 예보: \(weather.hourlyWeathers.count)개")
            }
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            print("❌ Home 날씨 데이터 로드 실패: \(error)")
        }
    }
    
    // MARK: - SwiftData 관리 (UseCase 위임)
    
    private func updateSavedDataCount() async {
        let count = await getCurrentLocationWeatherUseCase.getSavedDataCount()
        DispatchQueue.main.async {
            self.savedDataCount = count
        }
    }
    
    func getAllSavedData() async -> [LocationWeather] {
        return await getCurrentLocationWeatherUseCase.getAllSavedData()
    }
    
    func getTodayData() async -> [LocationWeather] {
        return await getCurrentLocationWeatherUseCase.getTodayData()
    }
    
    func clearAllData() async {
        await getCurrentLocationWeatherUseCase.clearAllData()
        await updateSavedDataCount()
    }
} 