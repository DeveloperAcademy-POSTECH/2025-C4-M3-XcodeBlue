//
//  SunScreenInfo.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import Foundation

struct SunScreenInfo {
    let spfIndex: Int
    let activationTime: Date
    
    static let duration: TimeInterval = 2 * 60 * 60 // 2시간 (초 단위)
    static let defaultSPFIndex = 30
}
