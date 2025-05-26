//
//  Measurement.swift
//  SwiftDataLog
//
//  Created by Vincenzo Salzano on 24/05/25.
//

import Foundation
import SwiftData
//Misure per l'altezza 
@Model
final class Measurement {
    var height: Double // Altezza in metri
    var measurementDate: Date
    var notes: String
    
    // Relazione con l'albero
    var tree: Tree?
    
    init(height: Double, notes: String = "", tree: Tree? = nil) {
        self.height = height
        self.measurementDate = Date()
        self.notes = notes
        self.tree = tree
    }
    
    // Computed property per formattare l'altezza
    var formattedHeight: String {
        return String(format: "%.2f m", height)
    }
}
