//
//  SunScreenInfo.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import Foundation

struct SunScreenInfo {
    var spfIndex: Int = 30
    let activationTime: Date
    static let duration: TimeInterval = 2 * 60 * 60  // 2시간 (초 단위)
}

extension SunScreenInfo {
    static let mockSunscreen = SunScreenInfo(
        activationTime: Date()
    )
}
