//
//  Item.swift
//  knobby
//
//  Created by Grigory Moroz on 19.12.25.
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
