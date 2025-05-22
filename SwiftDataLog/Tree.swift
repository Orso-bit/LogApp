//
//  Tree.swift
//  SwiftDataLog
//
//  Created by Vincenzo Salzano on 22/05/25.
//

import Foundation
import SwiftData

@Model
final class Tree {
    var name: String
    var species: String
    var extraNotes: String
    var createdAt: Date
    
    // Relazione con il cluster
    var cluster: Cluster?
    
    init(name: String, species: String, extraNotes: String = "", cluster: Cluster? = nil) {
        self.name = name
        self.species = species
        self.extraNotes = extraNotes
        self.createdAt = Date()
        self.cluster = cluster
    }
}
