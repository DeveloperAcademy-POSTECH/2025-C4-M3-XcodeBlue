//
//  UVExposureRepository.swift
//  TarTanning
//
//  Created by Jun on 7/20/25.
//

import Foundation

protocol UVExposureRepository {
    // ✅ Dashboard에서 사용하는 핵심 메서드들
    func getTodayUVExposure() async throws -> DailyUVExpose
    func getWeeklyUVExposure() async throws -> [DailyUVExpose]
    func getTodayUVProgressRate(userSkinType: SkinType) async throws -> Double
    func getWeeklyUVProgressRates(userSkinType: SkinType) async throws -> [Double]
    
    // ✅ DailyUVExpose 관리 메서드들
    func saveDailyUVExposure(_ dailyExposure: DailyUVExpose) async throws
    func getDailyUVExposure(for date: Date) async throws -> DailyUVExpose?
    func updateDailyUVExposure(for date: Date) async throws
}
