//
//  CalculateUserMEDUseCase.swift
//  TarTanning
//
//  Created by taeni on 7/25/25.
//

/**
 목적: 사용자의 피부타입과 현재 노출량을 기반으로 MED 계산
 입력: 사용자 피부타입, 현재 UV 노출량
 출력: MED 진행률(%), 위험도 레벨
 비즈니스 로직:

 피부타입별 최대 MED 값 적용
 누적 UV 노출량 vs 안전 기준 비교
 */

import Foundation

