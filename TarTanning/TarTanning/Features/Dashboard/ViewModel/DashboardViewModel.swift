//
//  DashboardViewModel.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import Foundation
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    private let uvExposureRepository: UVExposureRepository
    private let weatherRepository: WeatherRepository
    private let userProfileRepository: UserProfileRepository
    private let locationRepository: LocationRepository
    
    @Published var todayUVProgressRate: Double = 0.0
    @Published var weeklyUVProgressRates: [Double] = []
    @Published var currentWeather: LocationWeather?
    @Published var userProfile: UserProfile?
    @Published var todayTotalSunlightMinutes: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var currentUVIndex: Double {
        guard let currentHour = Calendar.current.dateComponents([.hour], from: Date()).hour else { return 0 }
        return currentWeather?.hourlyWeathers.first { $0.hour == currentHour }?.uvIndex ?? 0
    }
    
    var currentTemperature: Int {
        guard let currentHour = Calendar.current.dateComponents([.hour], from: Date()).hour else { return 0 }
        return Int(currentWeather?.hourlyWeathers.first { $0.hour == currentHour }?.temperature ?? 0)
    }
    
    init(
        uvExposureRepository: UVExposureRepository,
        weatherRepository: WeatherRepository,
        userProfileRepository: UserProfileRepository,
        locationRepository: LocationRepository
    ) {
        self.uvExposureRepository = uvExposureRepository
        self.weatherRepository = weatherRepository
        self.userProfileRepository = userProfileRepository
        self.locationRepository = locationRepository
    }
    
    func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        print("🔍 DEBUG: loadDashboardData 시작")
        
        do {
            // ✅ async let 제거하고 순차적으로 호출
            let userProfile = try await userProfileRepository.getUserProfile()
            let weather = try await weatherRepository.getCurrentWeather()
            let todayExposure = try await uvExposureRepository.getTodayUVExposure()
            let todayProgress = try await uvExposureRepository.getTodayUVProgressRate(userSkinType: userProfile.skinType)
            let weeklyProgress = try await uvExposureRepository.getWeeklyUVProgressRates(userSkinType: userProfile.skinType)
            
            print("🔍 DEBUG: todayProgress = \(todayProgress)")
            print("🔍 DEBUG: weeklyProgress = \(weeklyProgress)")
            print("🔍 DEBUG: todayExposure.totalSunlightMinutes = \(todayExposure.totalSunlightMinutes)")
            
            self.userProfile = userProfile
            self.currentWeather = weather
            self.todayUVProgressRate = todayProgress
            self.weeklyUVProgressRates = weeklyProgress
            self.todayTotalSunlightMinutes = Int(todayExposure.totalSunlightMinutes)
            
            // 현재 시간 정보
            let now = Date()
            let currentHour = Calendar.current.component(.hour, from: now)
            let currentMinute = Calendar.current.component(.minute, from: now)
            let uv = weather.hourlyWeathers.first { $0.hour == currentHour }?.uvIndex ?? -1

            print("🕒 현재 날짜: \(now)")
            print("🕒 현재 시각: \(currentHour)시 \(currentMinute)분")
            print("📍 mockSeoul 위치: \(weather.locationInfo.city) (\(weather.locationInfo.latitude), \(weather.locationInfo.longitude))")
            print("🌞 현재 시간의 UV지수: \(uv)")
            print("====================")
            
        } catch {
            print("🔍 DEBUG: error = \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        await loadDashboardData()
    }
}
