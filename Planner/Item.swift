//
//  Item.swift
//  Planner
//
//  Created by Vedang Patel on 2026-02-22.
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
