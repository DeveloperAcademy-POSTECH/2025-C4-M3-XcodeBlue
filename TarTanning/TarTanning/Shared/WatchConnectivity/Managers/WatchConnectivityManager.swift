//
//  WatchConnectivityManager.swift
//  TarTanning (Unified for iOS & watchOS)
//
//  Created by Taein on 7/15/25.
//

import Combine
import WatchConnectivity

#if os(watchOS)
import WatchKit
#endif

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
    
    // iOS 전용 - Watch에서 iPhone으로 데이터 전송 publisher
#if os(iOS)
    let messageFromWatchPublisher = PassthroughSubject<[String: Any], Never>()
#endif
    
    // watchOS 전용 - iPhone에서 Watch로 데이터 전송 publisher
#if os(watchOS)
    let receivedContextPublisher = PassthroughSubject<[String: Any], Never>()
    let receivedMessagePublisher = PassthroughSubject<[String: Any], Never>()
#endif
    
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
    
#if os(iOS)
    
    /// iPhone -> Watch 데이터 실시간 전송
    func sendContext(_ context: [String: Any]) {
        guard session.isPaired && session.isWatchAppInstalled else { return }
        do {
            try session.updateApplicationContext(context)
        } catch {
            print("Error sending context: \(error.localizedDescription)")
        }
    }
    
    /// Watch -> iPhone 일회성 메시지 전송
    func sendMessage(_ message: [String: Any]) {
        guard session.isReachable else {
            print("⌚ iPhone is not reachable for sendMessage.")
            return
        }
        session.sendMessage(message, replyHandler: nil) { error in
            print("⌚ Error sending message to iPhone: \(error.localizedDescription)")
        }
    }

    /// Watch -> iPhone 일회성 메시지 전송
    func sendMessageToPhone(_ message: [String: Any]) {
        sendMessage(message)
    }
    
    /// Watch 기기 정보 요청 및 데이터 받기
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
                        throwing: WatchConnectivityError.sendMessageFailed(error)
                    )
                }
            )
        }
    }
    
#endif
    
#if os(watchOS)
    
    /// Watch -> iPhone 일회성 메시지 전송
    func sendMessageToPhone(_ message: [String: Any]) {
        guard session.isReachable else {
            print("iPhone is not reachable.")
            return
        }
        session.sendMessage(message, replyHandler: nil) { error in
            print("Error sending message to phone: \(error.localizedDescription)")
        }
    }
    
    /// 기기의 고유 식별자(예: "Watch7,1")를 가져오는 헬퍼 함수
    private func getMachineIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
    
    /// 마지막으로 수신된 컨텍스트 확인
    public func checkLastReceivedContext() {
        let context = session.receivedApplicationContext
        
        if !context.isEmpty {
            print("Found last received context on init: \(context)")
            DispatchQueue.main.async {
                self.receivedContextPublisher.send(context)
            }
        }
    }
    
#endif
    
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
        
#if os(watchOS)
        if activationState == .activated {
            checkLastReceivedContext()
        }
#endif
    }
    
#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
#endif
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
#if os(iOS)
        DispatchQueue.main.async {
            self.messageFromWatchPublisher.send(message)
        }
#endif
        
#if os(watchOS)
        DispatchQueue.main.async {
            self.receivedMessagePublisher.send(message)
        }
#endif
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
#if os(iOS)
        DispatchQueue.main.async {
            self.messageFromWatchPublisher.send(message)
        }
        replyHandler([:])
#endif
        
#if os(watchOS)
        // watchOS에서 deviceInfo 요청 처리
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
#endif
    }
    
#if os(watchOS)
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            self.receivedContextPublisher.send(applicationContext)
        }
    }
#endif
}

extension WatchConnectivityManager {
    /// 현재 연결 상태 확인
    var isReachable: Bool {
        return session.isReachable
    }
    
    /// 세션 활성화 상태 확인
    var isActivated: Bool {
        return session.activationState == .activated
    }
    
#if os(iOS)
    /// Watch 앱이 설치되어 있는지 확인
    var isWatchAppInstalled: Bool {
        return session.isWatchAppInstalled
    }
    
    /// Watch가 페어링되어 있는지 확인
    var isPaired: Bool {
        return session.isPaired
    }
#endif
    
    /// 디버깅을 위한 세션 상태 로깅
    func logSessionStatus() {
        print("=== WatchConnectivity Session Status ===")
        print("Activation State: \(session.activationState.rawValue)")
        print("Is Reachable: \(session.isReachable)")
        
#if os(iOS)
        print("Is Paired: \(session.isPaired)")
        print("Is Watch App Installed: \(session.isWatchAppInstalled)")
#endif
        
#if os(watchOS)
        print("Received Application Context: \(session.receivedApplicationContext)")
#endif
        
        print("========================================")
    }
}
