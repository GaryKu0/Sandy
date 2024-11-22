//
//  RoutineDetailView.swift
//  Sandy
//
//  Created by 郭粟閣 on 2024/11/22.
//

// RoutineDetailView.swift

import SwiftUI

struct RoutineDetailView: View {
    let routine: RoutineHistory

    var body: some View {
        VStack {
            List {
                ForEach(routine.movements) { movement in
                    HStack {
                        Image(systemName: movement.icon)
                            .foregroundColor(.accentColor)
                        VStack(alignment: .leading) {
                            Text(movement.movementName)
                                .font(.headline)
                            Text("耗時: \(movement.duration) 秒")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: movement.wasSuccessful ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(movement.wasSuccessful ? .green : .red)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .navigationTitle(routine.routineName)
    }
}
