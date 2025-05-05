//
//  Item.swift
//  OllamaUX
//
//  Created by Jack Rogers on 5/5/25.
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
