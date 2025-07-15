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

    //Watched -> iPhone 데이터 수신용 Publisher
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

    /// iPhone에서 Watch로 최신 데이터를 전송합니다.
    func sendContext(_ context: [String: Any]) {
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

    func session(_ session: WCSession, didReceiveMessage message: [String: Any])
    {
        print("Received message on phone: \(message)")
        DispatchQueue.main.async {
            self.messageFromWatchPublisher.send(message)
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
    }

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
