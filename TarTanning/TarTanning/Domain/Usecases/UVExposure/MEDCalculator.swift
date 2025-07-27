//
//  MEDCalculator.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import Foundation

// 총 노출된 자외선 양 (Dose, J/m²) = 자외선 세기 (Irradiance, W/m²) X 노출 시간 (Time, s)
// 선크림 : 누적 자외선 양 += ((UV지수 * 0.025) / SPF 지수) x 일광 시간 (초)
struct MEDCalculator {
    private static let uvIndexToIrradiance = 0.025  // 자외선 세기 0.025W/m^2 = 1 UV

    static func calculateUVDose(
        uvIndex: Double,
        durationMinutes: Double,
        spf: Double?
    ) -> Double {
        let durationSeconds = durationMinutes * 60.0
        let irradiance = uvIndex * uvIndexToIrradiance  // UV 지수 -> 자외선 세기 지수 변환
        var dose = irradiance * durationSeconds

        // 상세 디버깅 로그
        print("🧮 [MEDCalculator] Calculation Details:")
        print("   • Input UV Index: \(uvIndex)")
        print("   • Input Duration Minutes: \(durationMinutes)")
        print("   • Duration Seconds: \(durationSeconds)")
        print("   • UV Index to Irradiance: \(uvIndexToIrradiance)")
        print("   • Calculated Irradiance: \(irradiance) W/m²")
        print("   • Dose before SPF: \(dose) J/m²")

        guard let spfValue = spf, spfValue >= 1 else {
            print("   • No SPF applied (spf is nil or < 1), final dose: \(dose) J/m²")
            return dose
        }

        dose /= Double(spfValue)
        print("   • SPF Value: \(spfValue)")
        print("   • Final dose after SPF: \(dose) J/m²")

        return dose
    }
}
