//
//  SettingView.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import SwiftUI

struct SettingView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text("서비스 설정")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Divider()
                        .background(.black)
                    
                    PermissionRow(
                        title: "알림 권한",
                        description: "자외선과 관련된 알림을 알려드립니다.",
                        openSettings: viewModel.openSystemSettings
                    )
                    
                    PermissionRow(
                        title: "위치 권한",
                        description: "현재 지역의 자외선 정보를 위한 위치정보를 수집합니다.",
                        openSettings: viewModel.openSystemSettings
                    )
                }
                .padding(.bottom, 45)
                
                VStack(alignment: .leading) {
                    Text("피부정보 설정")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Divider()
                        .background(.black)
                    
                    UserInfoRow(
                        title: "스킨타입 설정",
                        description: "피츠패트릭 스킨타입을 수정합니다.",
                        displayType: viewModel.skinTypeDisplay,
                        action: {
                            viewModel.isSkinTypePickerPresented = true
                        }
                    )
                    UserInfoRow(
                        title: "선크림SPF 설정",
                        description: "사용하는 선크림의 SPF 지수를 수정합니다.",
                        displayType: viewModel.spfDisplay,
                        action: {
                            viewModel.isSPFPickerPresented = true
                        }
                    )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $viewModel.isSkinTypePickerPresented) {
                Picker("스킨타입 선택", selection: $viewModel.selectedSkinType) {
                    ForEach(SkinType.allCases) { type in
                        Text("\(type.romanNumeral)형 - \(type.summary)").tag(type)
                    }
                }
                .pickerStyle(.wheel)
                .presentationDetents([.height(300)])
                .padding()
            }
            .sheet(isPresented: $viewModel.isSPFPickerPresented) {
                Picker("SPF 선택", selection: $viewModel.selectedSPFLevel) {
                    ForEach(SPFLevel.allCases) { level in
                        Text(level.displayTitle).tag(level)
                    }
                }
                .pickerStyle(.wheel)
                .presentationDetents([.height(300)])
                .padding()
            }
        }
    }
}

#Preview {
    SettingView()
}
