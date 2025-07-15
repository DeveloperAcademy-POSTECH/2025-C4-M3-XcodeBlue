//
//  OnboardingView.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import SwiftUI

struct OnboardingView: View {
    
    @EnvironmentObject var router: NavigationRouter
    @StateObject private var viewModel = OnboardingViewModel()
    
    var body: some View {
        VStack {
            switch viewModel.currentStep {
            case .watchInfo:
                OnboardingWatchCheckView(onNext: viewModel.nextMainView)
            case .permissionInfo:
                OnboardingPermissionInfoView(onNext: viewModel.nextMainView)
            case .skinTypeInfo:
                OnboardingSkinTypeView(
                    selectedType: viewModel.selectedSkinType,
                    onTapSkinTypeInfo: {
                        viewModel.activeSheet = .skinTypeDetailSheet
                    },
                    onNext: {
                        router.reset()
                        router.push(.dashboard)
                    },
                    onSelect: {
                        viewModel.selectSkinType($0)
                    }
                )
            default:
                EmptyView()
            }
        }
        .sheet(item: $viewModel.activeSheet) { sheet in
            switch sheet {
            case .startSheet:
                OnboardingStartView(onClose: {
                    viewModel.activeSheet = nil
                })
            case .skinTypeDetailSheet:
                OnboardingSkinTypeDetailView()
            default:
                EmptyView()
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(NavigationRouter())
}
