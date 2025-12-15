//
//  Item.swift
//  BabySafeVisuals
//
//  Created by Brent Kubitschek on 12/15/25.
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
