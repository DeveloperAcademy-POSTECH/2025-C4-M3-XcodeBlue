//
//  WatchConnectivityManager.swift
//  TarTanning
//
//  Created by Jun on 7/15/25.
//

import Combine
import WatchConnectivity

enum WatchConnectivityError: Error, LocalizedError {
    case notPairedOrInstalled
    case notReachable
    case sendMessageFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notPairedOrInstalled:
            return "워치가 페어링 되어있지 않거나 앱이 설치되지 않았습니다."
        case .notReachable:
            return "워치에 연결할 수 없습니다. 워치 앱이 실행 중인지 확인해주세요."
        case .sendMessageFailed(let error):
            return "워치 정보 요청 실패: \(error.localizedDescription)"
        }
    }
}

final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    /// Watch ->  iPhone 데이터 전송 publisher
    let messageFromWatchPublisher = PassthroughSubject<[String: Any], Never>()
    private let session: WCSession

    private override init() {
        self.session = .default
        super.init()
        self.session.delegate = self
        self.activateSession()
    }

    func activateSession() {
        if WCSession.isSupported() {
            session.activate()
        }
    }

    /// iphone -> Watch 데이터 실시간  전송
    func sendContext(_ context: [String: Any]) {
        guard session.isPaired && session.isWatchAppInstalled else { return }
        do {
            try session.updateApplicationContext(context)
        } catch {
            print("Error sending context: \(error.localizedDescription)")
        }
    }

    /// iPhone -> Watch 일회서 데이터 전송
    func sendMessage(_ message: [String: Any]) {
        guard session.isReachable else {
            print("Watch is not reachable for sendMessage.")
            return
        }
        session.sendMessage(message, replyHandler: nil) { error in
            print(
                "Error sending message to watch: \(error.localizedDescription)"
            )
        }
    }

    /// Watch 기기  정보 요청 및 데이터 받기
    func requestWatchDeviceInfo() async throws -> [String: Any] {
        guard session.isPaired && session.isWatchAppInstalled else {
            throw WatchConnectivityError.notPairedOrInstalled
        }
        guard session.isReachable else {
            throw WatchConnectivityError.notReachable
        }
        let message = ["request": "deviceInfo"]
        return try await withCheckedThrowingContinuation { continuation in
            session.sendMessage(
                message,
                replyHandler: { replyMessage in
                    continuation.resume(returning: replyMessage)
                },
                errorHandler: { error in
                    continuation.resume(
                        throwing: WatchConnectivityError.sendMessageFailed(
                            error
                        )
                    )
                }
            )
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        if let error = error {
            print(
                "WCSession activiation failed with error: \(error.localizedDescription)"
            )
        } else {
            print(
                "WCSession activated with state : \(activationState.rawValue)"
            )
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    func session(_ session: WCSession, didReceiveMessage message: [String: Any])
    {
        DispatchQueue.main.async {
            self.messageFromWatchPublisher.send(message)
        }
    }
}
