//
//  SyncTimerStateUseCase.swift
//  TarTanning
//
//  Created by taeni on 7/25/25.
//

/**
 목적: 디바이스 간 타이머 상태 동기화
 입력: 타이머 상태, 남은 시간, 소스 디바이스
 출력: 동기화 성공/실패
 비즈니스 로직:

 WatchConnectivity를 통한 실시간 상태 전송
 충돌 해결 (최신 업데이트 우선)
 */
import Foundation
