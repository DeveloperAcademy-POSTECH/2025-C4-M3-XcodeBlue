//
//  UVExposeRecord.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import Foundation

struct UVExposeRecord {
    var startDate: Date // 일광 노출이 시작된 시간 (11:42)
    var endDate: Date // 일광 노출이 시작된 시간 (12:15)
    var sunlightExposureDuration: Double // startDate ~ endDate 사이의 일광 시간
    var uvDose: Double // start Date ~ endDate 시간 사이의 UV 누적량 (UV노출량 식 계산, 단위 J/m^2)
    
    init(startDate: Date, endDate: Date, sunlightExposureDuration: Double, uvDose: Double) {
        self.startDate = startDate
        self.endDate = endDate
        self.sunlightExposureDuration = sunlightExposureDuration
        self.uvDose = uvDose
    }
}
