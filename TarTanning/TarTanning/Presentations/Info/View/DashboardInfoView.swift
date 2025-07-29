//
//  DashboardInfoView.swift
//  TarTanning
//
//  Created by 강진 on 7/21/25.
//

import SwiftUI

struct DashboardInfoView: View {
    @StateObject var viewModel: DashboardInfoViewModel
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(0..<viewModel.information.count, id: \.self) { index in
                        InformationCardView(info: viewModel.information[index])
                    }
                    .padding(.horizontal, 20)
                }
                .navigationTitle("정보")
            }
        }
    }
}

struct InformationItem {
    let title: String
    let category: String
    let imageName: String
    let explanation: String
    let content: String
}

struct InformationCardView: View {
    let info: InformationItem
    @State private var isPresented = false
    
    var body: some View {
        VStack {
            Image(info.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .clipped()
                .background(Color.yellow)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 20,
                        topTrailingRadius: 20
                    )
                )
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(info.category)
                        .foregroundStyle(Color("Key01"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4).fill(Color("Label")))
                    Text(info.title)
                        .fontWeight(.bold)
                        .font(.headline)
                    Text(info.explanation)
                        .fontWeight(.regular)
                        .font(.subheadline)
                }
                .padding(20)
                Spacer()
            }
            
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    DashboardInfoView(viewModel: DashboardInfoViewModel())
}
