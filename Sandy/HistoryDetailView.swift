//
//  HistoryDetailView.swift
//  Sandy
//
//  Created by 郭粟閣 on 2024/11/22.
//

// HistoryDetailView.swift

import SwiftUI

struct HistoryDetailView: View {
    let history: TaskHistory

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: history.icon)
                .resizable()
                .scaledToFit()
                .frame(height: 100)
                .foregroundColor(.accentColor)
                .padding(.top, 32)
            Text(history.taskName)
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("完成時間: \(history.completionDate, formatter: dateFormatter)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Divider()
                .padding(.vertical, 16)
            Text("任務持續時間")
                .font(.headline)
            Text("\(history.sessionDuration) 秒")
                .font(.title)
            Text("成功率")
                .font(.headline)
                .padding(.top, 8)
            Text("\(Int(history.successRate * 100))%")
                .font(.title)
            Text("總耗時")
                .font(.headline)
                .padding(.top, 8)
            Text("\(history.sessionDuration) 秒")
                .font(.title)
            Spacer()
        }
        .padding()
        .navigationTitle("詳細資訊")
    }

    // Date formatter for displaying dates
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .medium
        return formatter
    }
}
