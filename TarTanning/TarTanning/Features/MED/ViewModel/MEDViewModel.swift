//
//  MEDViewModel.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import SwiftUI

class MEDViewModel: ObservableObject {
    private let uvIndex = 6.0
    private let durationMinutes = 30.0
    private let spf = 15.0
    
    /// 시나리오 1: SPF 15 선크림을 적용했을 경우의 UV 노출량을 계산하고 로그를 출력합니다.
    func testMEDCalculationWithSPF() {
        let result = MEDCalculator.calculateUVDose(
            uvIndex: self.uvIndex,
            durationMinutes: self.durationMinutes,
            spf: self.spf
        )
        
        // 테스트 결과 로그 출력
        print("--- MED 계산 테스트 (SPF 적용) ---")
        print("[입력값] UV지수: \(self.uvIndex), 노출시간(분): \(self.durationMinutes), SPF: \(self.spf)")
        print("[결과] 계산된 UV 노출량(J/m²): \(result)")
        print("------------------------------------")
    }
    
    /// 시나리오 2: 선크림을 적용하지 않았을 경우의 UV 노출량을 계산하고 로그를 출력합니다.
    func testMEDCalculationWithoutSPF() {
        let result = MEDCalculator.calculateUVDose(
            uvIndex: self.uvIndex,
            durationMinutes: self.durationMinutes,
            spf: nil
        )
        
        // 테스트 결과 로그 출력
        print("--- MED 계산 테스트 (선크림 미적용) ---")
        print("[입력값] UV지수: \(self.uvIndex), 노출시간(분): \(self.durationMinutes), SPF: 없음")
        print("[결과] 계산된 UV 노출량(J/m²): \(result)")
        print("------------------------------------")
    }
}
