//
//  WatchUvDoseView.swift
//  TarTanningWatch Watch App
//
//  Created by taeni on 7/18/25.
//

import SwiftUI
import WatchKit

struct WatchUvDoseView: View {
    
    @StateObject private var syncService = WatchDashboardSyncService.shared
    @State private var currentTab: Int = 0 // 페이지 인덱스
    private var infoToggle: Bool = false
    
    var body: some View {
        ZStack {
            // 배경 색상
            syncService.uvLevel.color
                .ignoresSafeArea()
            
            // 콘텐츠 전체 레이어
            VStack(spacing: 24) {
                // 중앙 MED 정보
                VStack(spacing: 8) {
                    if infoToggle {
                        Text("현재 총 일광량")
                            .font(.caption2)
                            .foregroundColor(.white)
                        
                        Text("\(syncService.totalUVDose)분")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("현재 UV 노출량")
                            .font(.caption2)
                            .foregroundColor(.white)
                        
                        Text("\(syncService.uvProgressPercentage)%")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                VStack {
                    UvIndexAndLocationView(
                        uvIndex: syncService.currentUVIndex,
                        location: syncService.currentCityName
                    )
                }
            }
        }
        .onAppear {
            syncService.requestDataFromiPhone()
            print("\(syncService.uvProgressPercentage) syncService.uvProgressPercentage")
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            syncService.requestDataFromiPhone()
            WKInterfaceDevice.current().play(.click)
        }
        .onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationDidBecomeActiveNotification)) { _ in
            syncService.requestDataFromiPhone()
        }
    }
}

struct UvIndexAndLocationView: View {
    let uvIndex: Double
    let location: String
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .center) {
                Text("자외선 지수")
                Text("\(Int(uvIndex))")
            }
            .font(.caption)
            .foregroundColor(.white)
            
            Spacer()
            
            Text(location)
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
    }
}

struct VerticalPageIndicator: View {
    let currentIndex: Int
    let totalCount: Int
    
    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<totalCount, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

#Preview {
    WatchUvDoseView()
}
