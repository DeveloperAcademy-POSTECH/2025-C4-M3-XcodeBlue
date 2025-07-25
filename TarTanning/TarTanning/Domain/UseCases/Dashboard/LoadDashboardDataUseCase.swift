//
//  LoadDashboardDataUseCase.swift
//  TarTanning
//
//  Created by taeni on 7/25/25.
//

/**
 목적: 대시보드 화면에 필요한 모든 데이터 수집
 입력: 사용자 ID, 날짜
 출력: 통합 대시보드 데이터
 비즈니스 로직:

 여러 데이터 소스 병합 (UV, 날씨, 타이머 상태)
 캐싱 및 성능 최적화
 */
import Foundation
