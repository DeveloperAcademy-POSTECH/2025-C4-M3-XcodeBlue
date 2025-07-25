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
    VStack(spacing: 8) {
      ForEach(0..<viewModel.information.count, id: \.self) { index in
        InformationCardView(info: viewModel.information[index])
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
      
      VStack(spacing: 0) {
        Image(info.imageName)
          .resizable()
          .frame(width: 354, height: 197)
          .padding(.bottom,10)
          .clipShape(RoundedRectangle(cornerRadius:10))
        
        HStack {
          VStack(alignment: .leading, spacing: 8){
            Text(info.category)
              .font(.caption)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(
                RoundedRectangle(cornerRadius: 5)
                  .foregroundColor(.blue))
            Text(info.title)
              .font(.title2)
            Text(info.explanation)
              .padding(.bottom)
          }
          .padding(.leading, 40)
          .padding(.top, 10)
          Spacer()
        }
      }
      .onTapGesture {
        isPresented = true
      }
      .background(
        RoundedRectangle(cornerRadius: 10)
          .fill(Color.gray)
          .frame(width: 354)
          .alignmentGuide(.top) { _ in 0 }
      )
      .sheet(isPresented: $isPresented) {
        ScrollView{
          VStack {
            Text("SPF 관련 기사")
              .font(.caption)
              .padding()
            Image(info.imageName)
              .resizable()
              .frame(width: 394, height: 191)
            VStack(alignment: .leading, spacing: 8) {
                Text(info.title)
                  .font(.title3)
                  .padding(.bottom)
                Text(info.content)
            }
            .padding(.horizontal)
            Spacer()
          }
          .presentationDetents([.large])
          .presentationDragIndicator(.visible)
        }
      }
    }
}

#Preview {
  DashboardInfoView(viewModel: DashboardInfoViewModel())
}
