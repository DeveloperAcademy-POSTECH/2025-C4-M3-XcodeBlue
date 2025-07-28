//
//  SunscreenViewModel+UVData.swift
//  TarTanning
//
//  Created by taeni on 7/28/25.
//

import Foundation
import Combine

// MARK: - UV Data Management
extension SunscreenViewModel {
    
    /// UV 데이터 수신 설정 (watchOS용)
    internal func setupUVDataReception() {
#if os(watchOS)
        print("📡 [SunscreenViewModel] Setting up UV data reception on watchOS...")
        
        let manager = WatchConnectivityManager.shared
        
        // Application Context 수신
        manager.receivedContextPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] context in
                self?.handleReceivedUVData(context)
            }
            .store(in: &cancellables)
        
        // 실시간 메시지 수신
        manager.receivedMessagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleReceivedUVData(message)
            }
            .store(in: &cancellables)
        
        // 초기 컨텍스트 확인 (앱 시작 시 마지막으로 받은 데이터 복원)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            manager.checkLastReceivedContext()
        }
        
        print("✅ [SunscreenViewModel] UV data reception setup completed")
#else
        print("📱 [SunscreenViewModel] Running on iOS - no UV data reception setup needed")
#endif
    }
    
    /// UV 관련 데이터를 watchOS로 전송 (iOS용)
    func sendUVDataToWatch(
        medValue: Double,
        uvIndex: Double,
        statusLevel: String,
        location: String
    ) {
        // 로컬 상태 업데이트
        self.currentMEDValue = medValue
        self.currentUVIndex = uvIndex
        self.uvStatusLevel = statusLevel
        self.currentLocation = location
        
        // watchOS로 전송
        sendUVDataToCounterpart()
        
        logger.info("[\(self.deviceType)] UV data sent to watch - MED: \(medValue), UV: \(uvIndex), Status: \(statusLevel), Location: \(location)")
    }
    
    /// 수신된 UV 데이터 처리 (watchOS용)
    private func handleReceivedUVData(_ data: [String: Any]) {
        // UV 데이터가 포함된 메시지인지 확인
        guard data.keys.contains(where: { $0.hasPrefix("uv_") }) else {
            print("📡 [SunscreenViewModel] Received non-UV data, ignoring...")
            return
        }
        
        guard let timestamp = data["uv_timestamp"] as? TimeInterval else {
            print("⚠️ [SunscreenViewModel] UV data without timestamp, ignoring...")
            return
        }
        
        // 너무 오래된 데이터는 무시 (5분 이상)
        let age = Date().timeIntervalSince1970 - timestamp
        guard age < 300 else {
            print("⏰ [SunscreenViewModel] UV data too old: \(age)s, ignoring...")
            return
        }
        
        print("📊 [SunscreenViewModel] Processing UV data from iPhone...")
        
        if let medValue = data["uv_medValue"] as? Double {
            self.currentMEDValue = medValue
            print("   📊 MED Value: \(medValue)")
        }
        if let uvIndex = data["uv_uvIndex"] as? Double {
            self.currentUVIndex = uvIndex
            print("   ☀️ UV Index: \(uvIndex)")
        }
        if let statusLevel = data["uv_statusLevel"] as? String {
            self.uvStatusLevel = statusLevel
            print("   🚦 Status Level: \(statusLevel)")
        }
        if let location = data["uv_location"] as? String {
            self.currentLocation = location
            print("   📍 Location: \(location)")
        }
        
        print("✅ [SunscreenViewModel] UV data updated successfully")
    }
    
    /// UV 데이터만 별도로 전송하는 메서드
    private func sendUVDataToCounterpart() {
        let uvContext = [
            "uv_medValue": currentMEDValue,
            "uv_uvIndex": currentUVIndex,
            "uv_statusLevel": uvStatusLevel,
            "uv_location": currentLocation,
            "uv_deviceSource": deviceType,
            "uv_timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        let manager = WatchConnectivityManager.shared
        
#if os(iOS)
        manager.sendContext(uvContext)
        if manager.isReachable {
            manager.sendMessage(uvContext)
        }
#else
        manager.sendMessageToPhone(uvContext)
#endif
        
        logger.debug("[\(self.deviceType)] UV data context sent to counterpart")
    }
    
    /// UV 데이터 컨텍스트 업데이트 처리
    internal func updateUVDataFromContext(context: [String: Any]) {
        // 자신이 보낸 메시지는 무시
        if let deviceSource = context["uv_deviceSource"] as? String,
           deviceSource == deviceType {
            return
        }
        
        // 너무 오래된 데이터는 무시 (30초 이상)
        if let timestamp = context["uv_timestamp"] as? TimeInterval {
            let age = Date().timeIntervalSince1970 - timestamp
            guard age < 30 else {
                logger.warning("[\(self.deviceType)] UV context too old: \(age)s")
                return
            }
        }
        
        var hasUVData = false
        
        // UV 데이터 업데이트
        if let medValue = context["uv_medValue"] as? Double {
            self.currentMEDValue = medValue
            hasUVData = true
        }
        if let uvIndex = context["uv_uvIndex"] as? Double {
            self.currentUVIndex = uvIndex
            hasUVData = true
        }
        if let statusLevel = context["uv_statusLevel"] as? String {
            self.uvStatusLevel = statusLevel
            hasUVData = true
        }
        if let location = context["uv_location"] as? String {
            self.currentLocation = location
            hasUVData = true
        }
        
        if hasUVData {
            logger.info("[\(self.deviceType)] UV data updated from context: MED=\(self.currentMEDValue), UV=\(self.currentUVIndex), Status=\(self.uvStatusLevel), Location=\(self.currentLocation)")
        }
    }
    
    /// 디버깅용 현재 UV 데이터 로깅
    func logCurrentUVData() {
        print("📊 [SunscreenViewModel] Current UV Data:")
        print("   MED Value: \(currentMEDValue)")
        print("   UV Index: \(currentUVIndex)")
        print("   Status Level: \(uvStatusLevel)")
        print("   Location: \(currentLocation)")
        print("   Connection: \(connectionStatus)")
    }
}
