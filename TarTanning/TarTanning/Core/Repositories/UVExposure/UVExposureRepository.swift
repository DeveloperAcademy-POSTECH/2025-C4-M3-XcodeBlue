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
    func saveUVExposureRecord(_ record: UVExposeRecord) async throws
}
