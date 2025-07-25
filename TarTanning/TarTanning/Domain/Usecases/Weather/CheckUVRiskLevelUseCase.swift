//
//  CheckUVRiskLevelUseCase.swift
//  TarTanning
//
//  Created by taeni on 7/25/25.
//

/**
 목적: 현재 UV 조건에서의 위험도 판단
 입력: UV지수, 노출 예정 시간, 사용자 피부타입
 출력: 위험도 레벨, 권장 행동
 비즈니스 로직:

 UV지수 × 시간 × 피부타입 → 예상 노출량 계산
 안전 기준 대비 위험도 판단
 */
import Foundation
