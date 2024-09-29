//
//  Task.swift
//  Sandy
//
//  Created by 郭粟閣 on 2024/9/28.
//

import Foundation

// 定義任務結構體
struct Task: Identifiable {
    let id = UUID()
    let name: String                         // 任務名稱
    let expectedConditions: [Int: String]    // 模型輸出索引對應的標籤條件，例如 [2: "right", 4: "turn"]
    let duration: Int                        // 需要保持該狀態的持續時間（秒）
    let modelName: String                    // 模型名稱
    let icon: String                         // SF Symbols 中的圖標名稱
    let indexToLabelMap: [Int: String]       // 模型輸出索引對應的標籤
    let multipliers: [String: Double]        // 標籤的倍率調整

    // 初始化器
    init(name: String, expectedConditions: [Int: String], duration: Int, modelName: String, icon: String, indexToLabelMap: [Int: String], multipliers: [String: Double] = [:]) {
        self.name = name
        self.expectedConditions = expectedConditions
        self.duration = duration
        self.modelName = modelName
        self.icon = icon
        self.indexToLabelMap = indexToLabelMap
        self.multipliers = multipliers
    }
}
