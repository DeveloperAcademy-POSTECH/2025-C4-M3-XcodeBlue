//
//  UVExposureRepository.swift
//  TarTanning
//
//  Created by Jun on 7/20/25.
//

import Foundation

protocol UVExposureRepository {
    func getTodayUVExposure() async throws -> DailyUVExpose
    func getWeeklyUVExposure() async throws -> [DailyUVExpose]
    
    func calculateAndSaveUVDose(
        for record: UVExposeRecord,
        uvIndex: Double,
        userSkinType: SkinType
    ) async throws -> Double
    
    func updateDailyUVExposure(for date: Date) async throws
    
    func getTodayUVProgressRate(userSkinType: SkinType) async throws -> Double
    func getWeeklyUVProgressRates(userSkinType: SkinType) async throws -> [Double]
    
    func saveUVExposureRecord(_ record: UVExposeRecord) async throws
    func getUVExposureRecords(for date: Date) async throws -> [UVExposeRecord]
}
