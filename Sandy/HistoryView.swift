//
//  HistoryView.swift
//  Sandy
//
//  Created by 郭粟閣 on 2024/11/22.
//
// HistoryView.swift
import SwiftUI

struct HistoryView: View {
    @Binding var routineHistories: [RoutineHistory]

    var body: some View {
        List {
            ForEach(routineHistories) { routine in
                NavigationLink(destination: RoutineDetailView(routine: routine)) {
                    HStack {
                        Image(systemName: routine.wasSuccessful ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(routine.wasSuccessful ? .green : .red)
                        VStack(alignment: .leading) {
                            Text(routine.routineName)
                                .font(.headline)
                            Text(routine.completionDate, formatter: dateFormatter)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(routine.totalDuration) 秒")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("歷史紀錄")
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}
