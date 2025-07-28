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
    @State private var showTotalSunlight: Bool = false // ✨ 토글 상태 추가
    
    var body: some View {
        ZStack {
            // 배경 색상
            syncService.uvLevel.color
                .ignoresSafeArea()
            
            // 콘텐츠 전체 레이어
            VStack(spacing: 24) {
                // ✨ 중앙 MED 정보 - 터치로 토글 가능
                VStack(spacing: 8) {
                    // 라벨 텍스트 (토글 상태에 따라 변경)
                    Text(showTotalSunlight ? "총 일광량" : "현재 UV노출량")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .animation(.easeInOut(duration: 0.3), value: showTotalSunlight)
                    
                    // 메인 값 텍스트 (토글 상태에 따라 변경)
                    Group {
                        if showTotalSunlight {
                            Text("\(syncService.totalSunlight) 분")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(syncService.uvProgressPercentage)%")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: showTotalSunlight)
                }
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showTotalSunlight.toggle()
                    }
                    WKInterfaceDevice.current().play(.click)
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
        }
        // ✨ 전체 화면 탭 제스처는 데이터 새로고침으로 변경 (더 긴 탭으로 구분)
        .onLongPressGesture(minimumDuration: 0.5) {
            syncService.requestDataFromiPhone()
            WKInterfaceDevice.current().play(.start)
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
