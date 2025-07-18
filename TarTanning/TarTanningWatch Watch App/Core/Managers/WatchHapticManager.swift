//
//  WatchHapticManager.swift
//  TarTanning Watch App
//
//  Created by taeni on 7/18/25.
//

import WatchKit

final class WatchHapticManager {
    static let shared = WatchHapticManager()
    
    private init() {}
    
    /// 타이머 완료 햅틱 재생
    func playTimerCompletionHaptic() {
        let device = WKInterfaceDevice.current()
        
        device.play(.success)
        
        print("[Watch] Timer completion haptic played")
    }
    
    /// 일반 햅틱 재생
    func playGeneralHaptic() {
        WKInterfaceDevice.current().play(.click)
    }
}
