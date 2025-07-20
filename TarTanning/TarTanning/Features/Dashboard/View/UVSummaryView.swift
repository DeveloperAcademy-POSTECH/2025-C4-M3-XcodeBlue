//
//  UVSummaryView.swift
//  TarTanning
//
//  Created by 강진 on 7/18/25.
//

import SwiftUI

struct UVSummaryView: View {
    var body: some View {
      //UV 지수, 일광 시간, 현재 기온 영역
      ZStack{
        Rectangle()
          .frame(width: 353, height: 88)
          .foregroundColor(.white)
        
        HStack{
          Text("9")
          Divider()
            .padding()
          Text("30M")
            .padding()
          Divider()
            .padding()
          Text("28˚C")
        }
      }
      .padding(.bottom, 10)
    }
}

#Preview {
    UVSummaryView()
}
