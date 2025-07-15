//
//  WatchConnectivityManager.swift
//  TarTanning
//
//  Created by Jun on 7/15/25.
//

import Combine
import WatchConnectivity

final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()

    let receivedContextPublisher = PassthroughSubject<[String: Any], Never>()

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

    // MARK: - WCSessionDelegate (공통)
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        if let error = error {
            print(
                "WCSession activiation failed with error: \(error.localizedDescription)"
            )
            return
        }
        print("WCSession activated with state : \(activationState.rawValue)")
    }

    // MARK: - WCSessionDelegate (Watch 수신 전용)
    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        print("Received context on watch: \(applicationContext)")
        DispatchQueue.main.async {
            self.receivedContextPublisher.send(applicationContext)
        }
    }

    // MARK: - iOS 전용 코드
    // 이 아래의 모든 코드는 오직 iOS에서만 컴파일되고 실행됩니다.
    #if os(iOS)
        /// iPhone에서 Watch로 최신 데이터를 전송합니다.
        func sendContext(_ context: [String: Any]) {
            // Watch가 연결되어 있고, 앱이 설치되어 있는지 확인합니다.
            guard session.isPaired && session.isWatchAppInstalled else {
                print("Watch is not paired or app is not installed")
                return
            }

            do {
                try session.updateApplicationContext(context)
                print("Sent context to watch : \(context)")
            } catch {
                print("Error sending context : \(error.localizedDescription)")
            }
        }

        func sessionDidBecomeInactive(_ session: WCSession) {
            // 이 메서드는 watchOS에서는 호출되지 않으므로 비워둡니다.
        }

        func sessionDidDeactivate(_ session: WCSession) {
            // 사용자가 다른 워치로 전환했을 때, 새로운 세션을 다시 활성화합니다.
            session.activate()
        }
    #endif
}
