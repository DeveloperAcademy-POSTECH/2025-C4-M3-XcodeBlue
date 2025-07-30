//
//  TimerSPFManager.swift
//  TarTanning (Shared Target)
//
//  Created by taeni on 7/30/25.
//

import Foundation

/**
 타이머 활성화 기간을 나타내는 구조체
 SPF 계산에 사용되는 시간 범위를 정의
 */
struct TimerActivePeriod {
    let startTime: Date
    let endTime: Date
    let spfLevel: Double
    
    /// 특정 시간이 이 활성화 기간에 포함되는지 확인
    func contains(_ date: Date) -> Bool {
        return date >= startTime && date <= endTime
    }
    
    /// 특정 시간 범위와 겹치는 부분의 분 단위 시간을 계산
    func overlapDuration(with startDate: Date, endDate: Date) -> Double {
        let overlapStart = max(startTime, startDate)
        let overlapEnd = min(endTime, endDate)
        
        guard overlapStart < overlapEnd else { return 0.0 }
        
        return overlapEnd.timeIntervalSince(overlapStart) / 60.0 // 분 단위 반환
    }
}

/**
 SPF 적용 결과를 나타내는 구조체
 UV 계산에 사용할 정보를 제공
 */
struct SPFApplicationResult {
    let isSPFApplied: Bool
    let spfLevel: Double?
    let protectedDuration: Double // 분 단위
    let unprotectedDuration: Double // 분 단위
    
    static var noSPF: SPFApplicationResult {
        return SPFApplicationResult(
            isSPFApplied: false,
            spfLevel: nil,
            protectedDuration: 0.0,
            unprotectedDuration: 0.0
        )
    }
}

@MainActor
final class TimerSPFManager {
    static let shared = TimerSPFManager()
    
    // 타이머 활성화 기간들을 저장하는 배열
    private var timerActivePeriods: [TimerActivePeriod] = []
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 타이머 활성화 기간 추가
    func addActivePeriod(startTime: Date, endTime: Date, spfLevel: Double) {
        let activePeriod = TimerActivePeriod(
            startTime: startTime,
            endTime: endTime,
            spfLevel: spfLevel
        )
        
        timerActivePeriods.append(activePeriod)
        
        print("✅ [TimerSPFManager] Active period added - SPF: \(spfLevel)")
        print("🕐 [TimerSPFManager] Period: \(startTime.formatted(date: .omitted, time: .shortened)) ~ \(endTime.formatted(date: .omitted, time: .shortened))")
    }
    
    /// 현재 실행 중인 타이머 기간을 실제 종료 시간으로 업데이트
    func updateCurrentPeriodEndTime(to endTime: Date) {
        let now = Date()
        if let lastIndex = timerActivePeriods.lastIndex(where: { $0.endTime > now }) {
            let oldPeriod = timerActivePeriods[lastIndex]
            let updatedPeriod = TimerActivePeriod(
                startTime: oldPeriod.startTime,
                endTime: endTime, // 실제 종료 시간으로 업데이트
                spfLevel: oldPeriod.spfLevel
            )
            timerActivePeriods[lastIndex] = updatedPeriod
            
            print("🛑 [TimerSPFManager] Active period updated to end at \(endTime.formatted(date: .omitted, time: .shortened))")
        }
    }
    
    /// 특정 UV 노출 기간에 대한 SPF 적용 상태 확인
    func checkSPFApplication(startDate: Date, endDate: Date) -> SPFApplicationResult {
        guard !timerActivePeriods.isEmpty else {
            print("📋 [TimerSPFManager] No timer periods found")
            return .noSPF
        }
        
        let totalDuration = endDate.timeIntervalSince(startDate) / 60.0 // 분 단위
        var protectedDuration: Double = 0.0
        var appliedSPFLevel: Double = 0.0
        
        // 모든 타이머 활성화 기간과 겹치는 시간을 계산
        for period in timerActivePeriods {
            let overlapDuration = period.overlapDuration(with: startDate, endDate: endDate)
            if overlapDuration > 0 {
                protectedDuration += overlapDuration
                appliedSPFLevel = max(appliedSPFLevel, period.spfLevel) // 가장 높은 SPF 사용
                
                print("🔍 [TimerSPFManager] Found overlap: \(String(format: "%.1f", overlapDuration))min with SPF \(period.spfLevel)")
            }
        }
        
        let unprotectedDuration = totalDuration - protectedDuration
        let isSPFApplied = protectedDuration > 0
        
        let result = SPFApplicationResult(
            isSPFApplied: isSPFApplied,
            spfLevel: isSPFApplied ? appliedSPFLevel : nil,
            protectedDuration: protectedDuration,
            unprotectedDuration: max(0, unprotectedDuration)
        )
        
        print("📊 [TimerSPFManager] SPF Application Result:")
        print("   • Period: \(startDate.formatted(date: .omitted, time: .shortened)) ~ \(endDate.formatted(date: .omitted, time: .shortened))")
        print("   • Total duration: \(String(format: "%.1f", totalDuration))min")
        print("   • Protected duration: \(String(format: "%.1f", protectedDuration))min")
        print("   • Unprotected duration: \(String(format: "%.1f", unprotectedDuration))min")
        print("   • SPF applied: \(isSPFApplied ? "Yes (SPF \(appliedSPFLevel))" : "No")")
        
        return result
    }
    
    /// 디버깅용: 현재 저장된 타이머 활성화 기간들 출력
    func printActivePeriods() {
        print("📅 [TimerSPFManager] Current active periods (\(timerActivePeriods.count)):")
        for (index, period) in timerActivePeriods.enumerated() {
            print("   \(index + 1). \(period.startTime.formatted(date: .abbreviated, time: .shortened)) ~ \(period.endTime.formatted(date: .abbreviated, time: .shortened)) (SPF \(period.spfLevel))")
        }
    }
    
    /// 오래된 타이머 기간 정리 (24시간 이전 데이터 삭제)
    func cleanupOldPeriods() {
        let oneDayAgo = Date().addingTimeInterval(-24 * 60 * 60)
        let oldCount = timerActivePeriods.count
        
        timerActivePeriods.removeAll { period in
            period.endTime < oneDayAgo
        }
        
        let removedCount = oldCount - timerActivePeriods.count
        if removedCount > 0 {
            print("🧹 [TimerSPFManager] Cleaned up \(removedCount) old timer periods")
        }
    }
}