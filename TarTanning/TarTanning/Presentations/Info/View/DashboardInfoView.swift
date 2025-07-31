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
                LazyVStack(spacing: 24) {
                    ForEach(viewModel.categories, id: \.self) { category in
                        VStack(alignment: .leading, spacing: 16) {
                            LazyVStack(spacing: 20) {
                                ForEach(viewModel.groupedInformation[category] ?? []) { info in
                                    InformationCardView(info: info)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("정보")
        }
    }
}

struct InformationCardView: View {
    let info: SunscreenInfoItem
    @State private var isDetailPresented = false
    
    var body: some View {
        Button {
            isDetailPresented = true
        } label: {
            VStack {
                Image(info.thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .clipped()
                    .background(Color.gray.opacity(0.2))
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
                            .foregroundColor(.primary)
                        Text(String(info.content.prefix(100)) + "...")
                            .fontWeight(.regular)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
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
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $isDetailPresented) {
            InformationDetailView(info: info)
        }
    }
}

struct InformationDetailView: View {
    let info: SunscreenInfoItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Image(info.thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                        )
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(info.category)
                            .foregroundStyle(Color("Key01"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4).fill(Color("Label")))
                        
                        Text(info.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(info.content)
                            .font(.body)
                            .lineSpacing(4)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("정보")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DashboardInfoView(viewModel: DashboardInfoViewModel())
}
