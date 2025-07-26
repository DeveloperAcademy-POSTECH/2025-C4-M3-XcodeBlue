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
    @Published var todayUVProgressRate: Double = 0.0
    @Published var weeklyUVProgressRates: [Double] = []
    @Published var currentWeather: LocationWeather?
    @Published var userProfile: UserProfile?
    @Published var todayTotalSunlightMinutes: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
}
