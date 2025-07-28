//
//  SunscreenViewModel+DataSync.swift
//  TarTanning
//
//  Created by taeni on 7/28/25.
//

import Foundation
import Combine

// MARK: - Data Sync & Auto Update
extension SunscreenViewModel {
    
    /// iOS에서 주기적으로 UV 데이터를 업데이트하고 watchOS로 전송
    func startUVDataSync() {
        #if os(iOS)
        print("🔄 [SunscreenViewModel] Starting UV data sync on iOS...")
        
        // 즉시 한 번 실행
        Task {
            await fetchAndSendUVData()
        }
        
        // 30초마다 UV 데이터 업데이트
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchAndSendUVData()
            }
        }
        .store(in: &cancellables)
        
        print("✅ [SunscreenViewModel] UV data sync timer started")
        #endif
    }
    
    /// UV 데이터를 가져와서 watchOS로 전송
    @MainActor
    private func fetchAndSendUVData() async {
        #if os(iOS)
        do {
            print("📊 [SunscreenViewModel] Fetching UV data...")
            
            // DashboardViewModel 또는 직접 Repository를 사용해서 UV 데이터 가져오기
            let uvData = await fetchCurrentUVData()
            
            // watchOS로 전송
            sendUVDataToWatch(
                medValue: uvData.medValue,
                uvIndex: uvData.uvIndex,
                statusLevel: uvData.statusLevel,
                location: uvData.location
            )
            
            print("✅ [SunscreenViewModel] UV data sent to watch - MED: \(uvData.medValue), UV: \(uvData.uvIndex)")
            
        } catch {
            print("❌ [SunscreenViewModel] Failed to fetch UV data: \(error)")
            
            // 오류 시 기본값 전송
            sendUVDataToWatch(
                medValue: 0.0,
                uvIndex: 0.0,
                statusLevel: "데이터 없음",
                location: "위치 정보 없음"
            )
        }
        #endif
    }
    
    /// 현재 UV 데이터를 가져오는 메서드 (Repository 패턴 사용)
    @MainActor
    private func fetchCurrentUVData() async -> UVDataSnapshot {
        #if os(iOS)
        // 실제 구현에서는 DashboardViewModel이나 Repository를 주입받아 사용
        // 여기서는 Mock 데이터로 대체
        
        // TODO: 실제 Repository 구현
        // let uvExposureRepo = DefaultUVExposureRepository(weatherRepository: DefaultWeatherRepository())
        // let userProfileRepo = MockUserProfileRepository()
        // let todayProgress = try await uvExposureRepo.getTodayUVProgressRate(userSkinType: userProfile.skinType)
        
        // Mock 데이터 (실제로는 Repository에서 가져와야 함)
        return UVDataSnapshot(
            medValue: Double.random(in: 20...80),
            uvIndex: Double.random(in: 3...9),
            statusLevel: ["안전", "주의", "위험"].randomElement() ?? "안전",
            location: "서울시" // 실제 위치 정보
        )
        #else
        return UVDataSnapshot(medValue: 0, uvIndex: 0, statusLevel: "안전", location: "위치 없음")
        #endif
    }
    
    /// watchOS에서 데이터 요청 시 즉시 전송
    func handleDataRequest(from message: [String: Any]) {
        #if os(iOS)
        if message["action"] as? String == "requestUVDataRefresh" {
            print("📱 [SunscreenViewModel] Received UV data request from watch")
            
            Task {
                await fetchAndSendUVData()
            }
        }
        #endif
    }
    
    /// 앱이 포그라운드로 돌아왔을 때 데이터 동기화
    func syncDataOnAppBecomesActive() {
        #if os(iOS)
        Task {
            await fetchAndSendUVData()
        }
        print("🔄 [SunscreenViewModel] Data synced on app becomes active")
        #endif
    }
}

// MARK: - UV Data Snapshot
struct UVDataSnapshot {
    let medValue: Double
    let uvIndex: Double
    let statusLevel: String
    let location: String
}

// MARK: - Timer Extension for Combine
extension Timer {
    func store(in set: inout Set<AnyCancellable>) {
        // Timer를 AnyCancellable로 변환하여 저장
        let cancellable = AnyCancellable { [weak self] in
            self?.invalidate()
        }
        set.insert(cancellable)
    }
}
