//
//  Item.swift
//  Sandy
//
//  Created by 郭粟閣 on 2024/9/27.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
