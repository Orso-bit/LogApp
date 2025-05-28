//
//  Clinometer.swift
//  VeeTA
//
//  Created by Vincenzo Salzano on 27/05/25.
//

import Foundation
import SwiftData

//Misure per il clinometro
@Model
final class Clinometer {
    var inclination: Double // Inclinazione in gradi
    var inclinationDate: Date
    var notes: String
    
    // Relazione con l'albero
    var tree: Tree?
    
    init(inclination: Double, notes: String = "", tree: Tree? = nil) {
        self.inclination = inclination
        self.inclinationDate = Date()
        self.notes = notes
        self.tree = tree
    }
    
    // Computed property per formattare l'inclinazione (corretto da "m" a "°")
    var formattedInclination: String {
        return String(format: "%.2f°", inclination)
    }
}
