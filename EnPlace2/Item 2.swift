//
//  Item.swift
//  EnPlace
//
//  Created by Sam Berenato on 12/1/25.
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
