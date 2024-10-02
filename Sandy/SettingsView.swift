//
//  SettingsView.swift
//  Sandy
//
//  Created by 郭粟閣 on 2024/10/2.
//

import SwiftUI

// MARK: - 設置視圖
struct SettingsView: View {
    var body: some View {
        VStack {
            Text("施工中")
                .font(.largeTitle)
                .fontWeight(.bold)

            Image(systemName: "hammer.fill")
                .font(.system(size: 50))
                .padding()

            Text("此功能正在開發中，敬請期待！")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding()
        }
        .navigationBarTitle("設置", displayMode: .inline)
    }
}
