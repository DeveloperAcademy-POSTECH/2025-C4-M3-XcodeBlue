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

struct InformationSet {
  let title: String
  let category: String
  let imageName: String
  let explanation: String
  let content: String
}

struct InformationCardView: View {
  let info: InformationSet
  
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
      .background(
        RoundedRectangle(cornerRadius: 10)
          .fill(Color.gray)
          .frame(width: 354)
          .alignmentGuide(.top) { _ in 0 }
      )
    }
}

#Preview {
  DashboardInfoView(viewModel: DashboardInfoViewModel())
}
