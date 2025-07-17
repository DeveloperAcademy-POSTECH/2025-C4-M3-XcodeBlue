//
//  TimerVieModel.swift
//  TarTanning
//
//  Created by taeni on 7/17/25.
//

import Foundation
import WatchConnectivity

@MainActor
public final class TimerViewModel: NSObject, ObservableObject {
    @Published public var session: TimerSession?
    @Published public var isRunning = false
    @Published public var isCompleted = false
    @Published public var remainingTime: TimeInterval = 0

    private var timer: Timer?

    public override init() {
        super.init()
        activateWCSession()
    }

    // MARK: - 타이머 시작
    public func start(duration: TimeInterval) {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(duration)
        let newSession = TimerSession(startDate: startDate, endDate: endDate, duration: duration)

        self.session = newSession
        self.isRunning = true
        self.isCompleted = false

        runLocalTimer(until: endDate)
        sendToPeer(newSession)
    }

    // MARK: - 타이머 수신
    public func receive(_ session: TimerSession) {
        guard self.session?.id != session.id else { return }

        self.session = session
        self.isRunning = true
        self.isCompleted = false

        runLocalTimer(until: session.endDate)
    }

    // MARK: - 로컬 타이머 구동
    private func runLocalTimer(until endDate: Date) {
        timer?.invalidate()
        updateRemainingTime(endDate: endDate) // 즉시 1회 계산

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            self.updateRemainingTime(endDate: endDate)

            if self.remainingTime <= 0 {
                self.complete()
            }
        }
    }

    // MARK: - 남은 시간 갱신
    private func updateRemainingTime(endDate: Date) {
        let remaining = endDate.timeIntervalSinceNow
        self.remainingTime = max(0, remaining)
    }

    // MARK: - 완료 처리
    private func complete() {
        isRunning = false
        isCompleted = true
        timer?.invalidate()
        timer = nil
        remainingTime = 0

        handleCompletion()
    }

    private func handleCompletion() {
        #if os(watchOS)
        TimerNotificationManager.sendWatchNotification()
        #endif
        // iOS는 UI 처리 (예: Navigation pop 등)
    }

    // MARK: - WatchConnectivity
    private func activateWCSession() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    private func sendToPeer(_ session: TimerSession) {
        WCSession.default.sendMessage(session.dictionary, replyHandler: nil, errorHandler: nil)
    }
}

// MARK: - WCSessionDelegate
extension TimerViewModel: WCSessionDelegate {
    public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let session = TimerSession.from(dictionary: message) {
            Task { @MainActor in
                self.receive(session)
            }
        }
    }

    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {}
    public func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif
}

