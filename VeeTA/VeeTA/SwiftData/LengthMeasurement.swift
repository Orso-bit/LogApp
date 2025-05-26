//
//  LengthMeasurement.swift
//  SwiftDataLog
//
//  Created by Vincenzo Salzano on 25/05/25.
//

import Foundation
import SwiftData

// Misure per la lunghezza
@Model
final class LengthMeasurement {
    var length: Double // Lunghezza in metri
    var lengthmeasurementDate: Date
    var notes: String // Relazione con l'albero o altro oggetto
    
    var tree: Tree?
    
    init(length: Double, notes: String = "", tree: Tree? = nil) {
        self.length = length
        self.lengthmeasurementDate = Date()
        self.notes = notes
        self.tree = tree
    }
    
    // Computed property per formattare la lunghezza
    var formattedLength: String {
        return String(format: "%.2f m", length)
    }
}
