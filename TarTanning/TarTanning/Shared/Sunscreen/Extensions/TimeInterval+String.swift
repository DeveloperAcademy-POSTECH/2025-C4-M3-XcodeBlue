//
//  TimeInterval.swift
//  TarTanning
//
//  Created by taeni on 7/19/25.
//

import Foundation

extension TimeInterval {
    var timeDisplayString: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) % 3600 / 60
        
        if hours > 0 {
            return String(format: "%02d:%02d", hours, minutes)
        } else {
            return String(format: "00:%02d", minutes)
        }
    }
    
    var shortTimeString: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var hoursAndMinutes: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) % 3600 / 60
        
        if hours > 0 {
            return String(format: "%d시간 %d분", hours, minutes)
        } else {
            return String(format: "%d분", minutes)
        }
    }
}
