//
//  GetCurrentLocationWeatherUseCase.swift
//  TarTanning
//
//  Created by taeni on 7/25/25.
//

/**
 목적: 현재 위치의 실시간 날씨 및 UV 정보 제공
 입력: 현재 위치 (위도, 경도)
 출력: UV지수, 온도, 시간별 예보
 비즈니스 로직:

 위치 권한 확인 → WeatherKit 호출
 UV지수 카테고리 분류 (낮음/보통/높음/매우높음/위험)
 */
import Foundation
