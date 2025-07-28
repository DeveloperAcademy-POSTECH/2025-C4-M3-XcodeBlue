//
//  SunscreenViewModel+Debug.swift
//  TarTanning
//
//  Created by taeni on 7/28/25.
//

import Foundation
import WatchConnectivity

// MARK: - Debug & Logging Utilities
extension SunscreenViewModel {
    
    /// 전체 상태를 로그로 출력
    func logFullState() {
        print("🔍 [SunscreenViewModel] === FULL STATE DEBUG ===")
        print("   Device: \(deviceType)")
        print("   Connection: \(connectionStatus)")
        print("   Timer Active: \(isActive)")
        print("   Remaining Time: \(remainingTime)")
        print("   Timer State: \(timerState.rawValue)")
        print("   MED Value: \(currentMEDValue)")
        print("   UV Index: \(currentUVIndex)")
        print("   Status Level: \(uvStatusLevel)")
        print("   Location: \(currentLocation)")
        print("   WatchConnectivity Reachable: \(WatchConnectivityManager.shared.isReachable)")
        print("   WatchConnectivity Activated: \(WatchConnectivityManager.shared.isActivated)")
        print("========================================")
    }
    
    /// Watch Connectivity 상태를 상세히 로그
    func logWatchConnectivityStatus() {
        let manager = WatchConnectivityManager.shared
        print("📡 [SunscreenViewModel] === WATCH CONNECTIVITY STATUS ===")
        print("   Is Supported: \(WCSession.isSupported())")
        print("   Is Activated: \(manager.isActivated)")
        print("   Is Reachable: \(manager.isReachable)")
        
        #if os(iOS)
        print("   Is Paired: \(manager.isPaired)")
        print("   Is Watch App Installed: \(manager.isWatchAppInstalled)")
        #endif
        
        print("=============================================")
    }
    
    /// 테스트용 UV 데이터 강제 전송
    func sendTestUVData() {
        let testData = UVDataSnapshot(
            medValue: 67.5,
            uvIndex: 8.0,
            statusLevel: "위험",
            location: "테스트 위치"
        )
        
        print("🧪 [SunscreenViewModel] Sending TEST UV data...")
        sendUVDataToWatch(
            medValue: testData.medValue,
            uvIndex: testData.uvIndex,
            statusLevel: testData.statusLevel,
            location: testData.location
        )
        print("✅ [SunscreenViewModel] Test UV data sent")
    }
    
    /// WatchConnectivity 강제 재시작
    func restartWatchConnectivity() {
        print("🔄 [SunscreenViewModel] Restarting WatchConnectivity...")
        WatchConnectivityManager.shared.activateSession()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.updateConnectionStatus()
            self.logWatchConnectivityStatus()
        }
    }
}

// MARK: - Test Methods for Development
#if DEBUG
extension SunscreenViewModel {
    
    /// 개발용 테스트 메서드들
    func runDevelopmentTests() {
        print("🧪 [SunscreenViewModel] Running development tests...")
        
        // 1. 상태 로그
        logFullState()
        
        // 2. WatchConnectivity 상태 확인
        logWatchConnectivityStatus()
        
        // 3. 테스트 데이터 전송
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.sendTestUVData()
        }
        
        // 4. 5초 후 다시 상태 확인
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            print("🔍 [SunscreenViewModel] === AFTER TEST STATE ===")
            self.logFullState()
        }
    }
}
#endif
