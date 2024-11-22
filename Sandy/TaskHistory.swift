//
//  TaskHistory.swift
//  Sandy
//
//  Created by 郭粟閣 on 2024/11/22.
//

import Foundation

struct TaskHistory: Identifiable {
    let id = UUID()
    let taskName: String
    let icon: String
    let sessionDuration: Int
    let successRate: Double
    let completionDate: Date // Add this property
}
