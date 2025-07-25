//
//  SendUVWarningNotificationUseCase.swift
//  TarTanning
//
//  Created by taeni on 7/25/25.
//

/**
 목적: UV 위험 상황 시 알림 발송
 입력: 현재 MED 진행률, 예상 위험 시간
 출력: 알림 발송 성공/실패
 비즈니스 로직:

 MED 70% 이상 시 경고 알림
 디바이스별 알림 방식 (iOS: 배너, Watch: 햅틱)
 */
import Foundation
