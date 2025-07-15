//
//  WatchConnectivityManager.swift
//  TarTanningWatch Watch App
//
//  Created by Jun on 7/15/25.
//

import Combine
import WatchConnectivity
import WatchKit

final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()

    /// iPhone ->  Watch 데이터 전달하는 publisher
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

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        if let error = error {
            print("WCSession activiation failed with error: \(error.localizedDescription)")
            return
        }
        print("WCSession activated with state : \(activationState.rawValue)")
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("Received context on watch: \(applicationContext)")
        DispatchQueue.main.async {
            self.receivedContextPublisher.send(applicationContext)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if message["request"] as? String == "deviceInfo" {
            let device = WKInterfaceDevice.current()
            let reply: [String: Any] = [
                "watchModel": device.model,
                "watchOSVersion": device.systemVersion
            ]
            print("Replying to device info request with: \(reply)")
            replyHandler(reply)
        }
    }
}
