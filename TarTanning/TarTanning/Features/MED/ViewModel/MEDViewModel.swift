//
//  MEDViewModel.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import Foundation

class MEDViewModel: ObservableObject {
    func testMEDCalculation() {
        let uvIndex: Double = 6.0
        let durationMinutes: Double = 30.0
        let spf: Double? = 15.0
        
        let result = MEDCalculator.calculateUVDose(
            uvIndex: uvIndex,
            durationMinutes: durationMinutes,
            spf: spf
        )
        print("[MED TEST] UV지수: \(uvIndex), 노출시간(분): \(durationMinutes), SPF: \(spf ?? 0)")
        print("[MED TEST] 계산된 UV 노출량(J/m²): \(result)")
    }
}
