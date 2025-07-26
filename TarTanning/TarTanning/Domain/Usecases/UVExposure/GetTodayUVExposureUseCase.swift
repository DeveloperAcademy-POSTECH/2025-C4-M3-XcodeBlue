//
//  GetTodayUVExposureUseCase.swift
//  TarTanning
//
//  Created by taeni on 7/25/25.
//

/**
 목적: 오늘의 UV 노출량 데이터 수집 및 계산
 입력: 날짜, 사용자 피부타입
 출력: 일일 UV 노출 요약 데이터
 비즈니스 로직:

 HealthKit 일광시간 + WeatherKit UV지수 조합
 선크림 적용 여부에 따른 노출량 보정
 */

import Foundation
