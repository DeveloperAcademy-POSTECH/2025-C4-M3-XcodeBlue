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
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var currentUVIndex: Int {
        guard let currentHour = Calendar.current.dateComponents([.hour], from: Date()).hour else { return 0 }
        return Int(currentWeather?.hourlyWeathers.first { $0.hour == currentHour }?.uvIndex ?? 0)
    }
    
    var totalDaylightMinutes: Int {
        Int(currentWeather?.hourlyWeathers.reduce(0) { $0 + ($1.uvIndex > 0 ? 1 : 0) } ?? 0)
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
        
        do {
            async let userProfileTask = userProfileRepository.getUserProfile()
            async let weatherTask = weatherRepository.getCurrentWeather()
            async let todayProgressTask = uvExposureRepository.getTodayUVProgressRate(userSkinType: .type3)
            async let weeklyProgressTask = uvExposureRepository.getWeeklyUVProgressRates(userSkinType: .type3)
            
            let (userProfile, weather, todayProgress, weeklyProgress) = try await (userProfileTask, weatherTask, todayProgressTask, weeklyProgressTask)
            
            self.userProfile = userProfile
            self.currentWeather = weather
            self.todayUVProgressRate = todayProgress
            self.weeklyUVProgressRates = weeklyProgress
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        await loadDashboardData()
    }
}
