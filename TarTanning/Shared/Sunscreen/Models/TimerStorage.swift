//
//  TimerStorage.swift
//  TarTanning (iOS + watchOS)
//
//  Created by taeni on 7/17/25.
//

import Foundation

class TimerStorage {
    static let shared = TimerStorage()
    private let userDefaults = UserDefaults.standard
    
    private let endTimeKey = "timer_endTime"
    private let stateKey = "timer_state"
    
    private init() {}
    
    var endTime: Date? {
        get { userDefaults.object(forKey: endTimeKey) as? Date }
        set { userDefaults.set(newValue, forKey: endTimeKey) }
    }
    
    var state: TimerState {
        get {
            if let raw = userDefaults.string(forKey: stateKey),
               let state = TimerState(rawValue: raw) {
                return state
            }
            return .stopped
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: stateKey)
        }
    }
    
    func clear() {
        userDefaults.removeObject(forKey: endTimeKey)
        userDefaults.removeObject(forKey: stateKey)
    }
}
