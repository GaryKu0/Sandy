//
//  Task.swift
//  Sandy
//
//  Created by 郭粟閣 on 2024/9/28.
//

// Task.swift
import Foundation

// Define Task struct
struct Task: Identifiable {
    let id = UUID()
    let name: String                         // Task name
    let expectedConditions: [Int: String]    // Model output index to label condition
    let duration: Int                        // Duration to maintain the state (seconds)
    let modelName: String                    // Model name
    let icon: String                         // Icon name in SF Symbols
    let indexToLabelMap: [Int: String]       // Model output index to label
    let multipliers: [String: Double]        // Multipliers for labels
    let mediapipeTasks: [String]             // Array of Mediapipe Tasks needed (e.g., ["face", "pose", "hand"])

    // Initializer
    init(name: String, expectedConditions: [Int: String], duration: Int, modelName: String, icon: String, indexToLabelMap: [Int: String], multipliers: [String: Double] = [:], mediapipeTasks: [String]) {
        self.name = name
        self.expectedConditions = expectedConditions
        self.duration = duration
        self.modelName = modelName
        self.icon = icon
        self.indexToLabelMap = indexToLabelMap
        self.multipliers = multipliers
        self.mediapipeTasks = mediapipeTasks
    }
}
