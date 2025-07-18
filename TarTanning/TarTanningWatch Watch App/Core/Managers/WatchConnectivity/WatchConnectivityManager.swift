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

    let receivedContextPublisher = PassthroughSubject<[String: Any], Never>()
    
    let receivedMessagePublisher = PassthroughSubject<[String: Any], Never>()

    private let session: WCSession = .default

    private override init() {
        super.init()
        session.delegate = self
        activateSession()
    }

    func activateSession() {
        if WCSession.isSupported() {
            session.activate()
        }
    }

    /// (Watch -> iPhone) iPhone으로 일회성 메시지를 전송합니다.
    func sendMessageToPhone(_ message: [String: Any]) {
        guard session.isReachable else {
            print("iPhone is not reachable.")
            return
        }
        session.sendMessage(message, replyHandler: nil) { error in
            print("Error sending message to phone: \(error.localizedDescription)")
        }
    }

    /// 기기의 고유 식별자(예: "Watch7,1")를 가져오는 헬퍼 함수입니다.
    private func getMachineIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
    
    public func checkLastReceivedContext() {
        let context = session.receivedApplicationContext
        
        if !context.isEmpty {
            print("Found last received context on init: \(context)")
            DispatchQueue.main.async {
                self.receivedContextPublisher.send(context)
            }
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        if activationState == .activated {
            checkLastReceivedContext()
        }
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            self.receivedContextPublisher.send(applicationContext)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        if message["request"] as? String == "deviceInfo" {
            let reply: [String: Any] = [
                "watchModel": getMachineIdentifier(),
                "watchOSVersion": WKInterfaceDevice.current().systemVersion
            ]
            replyHandler(reply)
            return
        }
        
        DispatchQueue.main.async {
            self.receivedMessagePublisher.send(message)
        }
        replyHandler([:])
    }
}
