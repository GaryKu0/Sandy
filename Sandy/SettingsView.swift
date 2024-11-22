//
//  SettingsView.swift
//  Sandy
//
//  Created by 郭粟閣 on 2024/10/2.
//

import SwiftUI

// MARK: - 設置視圖
struct SettingsView: View {
    @Binding var routineHistories: [RoutineHistory]

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: HistoryView(routineHistories: $routineHistories)) {
                    Label("查看歷史紀錄", systemImage: "clock.arrow.circlepath")
                }
            }
            .navigationTitle("設定")
        }
    }
}
