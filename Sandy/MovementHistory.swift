//
//  MovementHistory.swift
//  Sandy
//
//  Created by 郭粟閣 on 2024/11/22.
//

import Foundation

struct MovementHistory: Identifiable {
    let id = UUID()
    let movementName: String
    let icon: String
    let duration: Int // Duration spent on the movement in seconds
    let startTime: Date
    let endTime: Date
    let wasSuccessful: Bool
}

struct RoutineHistory: Identifiable {
    let id = UUID()
    let routineName: String
    let movements: [MovementHistory]
    let totalDuration: Int // Total duration of the routine in seconds
    let completionDate: Date
    let wasSuccessful: Bool
}
