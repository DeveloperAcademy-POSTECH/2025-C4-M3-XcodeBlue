//
//  SunscreenViewModel+Preview.swift
//  TarTanning
//
//  Created by taeni on 7/28/25.
//

import Foundation

// MARK: - Preview & Test Support
extension SunscreenViewModel {
    
    /// Preview와 테스트용 Mock 데이터 설정
    func setupMockData(
        isActive: Bool = true,
        remainingTime: TimeInterval = 90 * 60,
        totalDuration: TimeInterval = 120 * 60,
        connectionStatus: String = "연결됨",
        medValue: Double = 45.0,
        uvIndex: Double = 6.0,
        statusLevel: String = "주의",
        location: String = "서울시"
    ) {
        self.isActive = isActive
        self.remainingTime = remainingTime
        self.totalDuration = totalDuration
        self.connectionStatus = connectionStatus
        self.currentMEDValue = medValue
        self.currentUVIndex = uvIndex
        self.uvStatusLevel = statusLevel
        self.currentLocation = location
    }
}

#if DEBUG
// MARK: - Mock SunscreenViewModel for Previews
@MainActor
final class MockSunscreenViewModel: ObservableObject {
    @Published var isActive: Bool
    @Published var remainingTime: TimeInterval
    @Published var totalDuration: TimeInterval
    @Published var connectionStatus: String
    @Published var timerState: TimerState
    @Published var currentMEDValue: Double
    @Published var currentUVIndex: Double
    @Published var uvStatusLevel: String
    @Published var currentLocation: String
    
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return max(0, min(1, (totalDuration - remainingTime) / totalDuration))
    }
    
    var isCompleted: Bool {
        remainingTime <= 0 && !isActive
    }
    
    var timeDisplayString: String {
        return remainingTime.timeDisplayString
    }
    
    init(
        isActive: Bool = false,
        remainingTime: TimeInterval = 0,
        totalDuration: TimeInterval = 120 * 60,
        connectionStatus: String = "연결 안됨",
        timerState: TimerState = .stopped,
        medValue: Double = 0.0,
        uvIndex: Double = 0.0,
        statusLevel: String = "안전",
        location: String = "위치 정보 없음"
    ) {
        self.isActive = isActive
        self.remainingTime = remainingTime
        self.totalDuration = totalDuration
        self.connectionStatus = connectionStatus
        self.timerState = timerState
        self.currentMEDValue = medValue
        self.currentUVIndex = uvIndex
        self.uvStatusLevel = statusLevel
        self.currentLocation = location
    }
    
    // Mock 메서드들 (실제 동작 안함)
    func startSunscreenProtection(duration: TimeInterval = 120 * 60) {
        isActive = true
        remainingTime = duration
        totalDuration = duration
        timerState = .running
    }
    
    func stopSunscreenProtection() {
        isActive = false
        remainingTime = 0
        timerState = .stopped
    }
    
    func resetTimer() {
        isActive = false
        remainingTime = 0
        totalDuration = 120 * 60
        timerState = .stopped
    }
    
    func logCurrentUVData() {
        print("📊 [MockSunscreenViewModel] Current UV Data:")
        print("   MED Value: \(currentMEDValue)")
        print("   UV Index: \(currentUVIndex)")
        print("   Status Level: \(uvStatusLevel)")
        print("   Location: \(currentLocation)")
        print("   Connection: \(connectionStatus)")
    }
    
    // 자주 사용되는 Mock 상태들
    static var active: MockSunscreenViewModel {
        MockSunscreenViewModel(
            isActive: true,
            remainingTime: 75 * 60,        // 1시간 15분 남음
            totalDuration: 120 * 60,       // 총 2시간
            connectionStatus: "연결됨",
            timerState: .running,
            medValue: 65.0,
            uvIndex: 7.0,
            statusLevel: "주의",
            location: "서울시"
        )
    }
    
    static var completed: MockSunscreenViewModel {
        MockSunscreenViewModel(
            isActive: false,
            remainingTime: 0,              // 완료됨
            totalDuration: 120 * 60,       // 총 2시간
            connectionStatus: "연결됨",
            timerState: .stopped,
            medValue: 85.0,
            uvIndex: 8.0,
            statusLevel: "위험",
            location: "부산시"
        )
    }
    
    static var disconnected: MockSunscreenViewModel {
        MockSunscreenViewModel(
            isActive: true,
            remainingTime: 45 * 60,        // 45분 남음
            totalDuration: 120 * 60,       // 총 2시간
            connectionStatus: "연결 안됨",
            timerState: .running,
            medValue: 45.0,
            uvIndex: 6.0,
            statusLevel: "주의",
            location: "대구시"
        )
    }
    
    static var inactive: MockSunscreenViewModel {
        MockSunscreenViewModel(
            isActive: false,
            remainingTime: 0,
            totalDuration: 120 * 60,
            connectionStatus: "비활성",
            timerState: .stopped,
            medValue: 25.0,
            uvIndex: 4.0,
            statusLevel: "안전",
            location: "제주시"
        )
    }
    
    static var caution: MockSunscreenViewModel {
        MockSunscreenViewModel(
            isActive: true,
            remainingTime: 30 * 60,        // 30분 남음
            totalDuration: 120 * 60,       // 총 2시간
            connectionStatus: "연결됨",
            timerState: .running,
            medValue: 78.0,
            uvIndex: 9.0,
            statusLevel: "매우 위험",
            location: "광주시"
        )
    }
}
#endif
