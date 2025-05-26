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
final class TreeProiection {
    var diameter: Double //Diametro in metri
    var diameterDate: Date
    var notes: String
    
    // Relazione con l'albero
    var tree: Tree?
    
    init(diameter: Double, notes: String = "", tree: Tree? = nil) {
        self.diameter = diameter
        self.diameterDate = Date()
        self.notes = notes
        self.tree = tree
    }
    
    // Computed property per formattare il diametro
    var formattedDiameter: String {
        return String(format: "%.2f m", diameter)
    }
}
