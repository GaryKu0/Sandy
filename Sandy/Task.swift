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
    init(
        name: String,
        expectedConditions: [Int: String],
        duration: Int,
        modelName: String,
        icon: String,
        indexToLabelMap: [Int: String],
        multipliers: [String: Double] = [:],
        mediapipeTasks: [String]
    ) {
        self.name = name
        self.expectedConditions = expectedConditions
        self.duration = duration
        self.modelName = modelName
        self.icon = icon
        self.indexToLabelMap = indexToLabelMap
        self.multipliers = multipliers
        self.mediapipeTasks = mediapipeTasks
    }

    // Static array of default tasks
    static let defaultTasks: [Task] = [
        Task(
            name: "頭部向左轉",
            expectedConditions: [1: "left", 4: "turn"],
            duration: 4,
            modelName: "facing-model",
            icon: "arrowshape.left.fill",
            indexToLabelMap: [0: "front", 1: "left", 2: "right", 3: "tilt", 4: "turn"],
            multipliers: ["left": 0.9],
            mediapipeTasks: ["face"]
        ),
        Task(
            name: "頭部回正",
            expectedConditions: [0: "front"],
            duration: 4,
            modelName: "facing-model",
            icon: "face.smiling.inverse",
            indexToLabelMap: [0: "front", 1: "left", 2: "right", 3: "tilt", 4: "turn"],
            multipliers: ["front": 1.5],
            mediapipeTasks: ["face"]
        ),
        Task(
            name: "頭部向右轉",
            expectedConditions: [2: "right", 4: "turn"],
            duration: 4,
            modelName: "facing-model",
            icon: "arrowshape.right.fill",
            indexToLabelMap: [0: "front", 1: "left", 2: "right", 3: "tilt", 4: "turn"],
            multipliers: ["front": 1.3],
            mediapipeTasks: ["face"]
        ),
        Task(
            name: "向上看",
            expectedConditions: [7: "top"],
            duration: 4,
            modelName: "facing-model",
            icon: "arrow.up.circle.fill",
            indexToLabelMap: [5: "down", 6: "unknown", 7: "top"],
            multipliers: ["top": 1.4],
            mediapipeTasks: ["face"]
        ),
//        Task(
//            name:"顎下線按摩",
//            expectedConditions: [0: "YES"],
//            duration: 4,
//            modelName: "submandibular_gland",
//            icon: "person.crop.circle",
//            indexToLabelMap: [0: "NO", 1: "YES"],
//            multipliers: ["YES": 1.5],
//            mediapipeTasks: ["pose", "hand"]
//        )
    ]
}
