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
    
    // Relazione uno-a-molti con le misurazioni
    @Relationship(deleteRule: .cascade, inverse: \Measurement.tree)
    var measurements: [Measurement] = []
    @Relationship(deleteRule: .cascade, inverse: \LengthMeasurement.tree)
    var lengthMeasurements: [LengthMeasurement] = []
    
    init(name: String, species: String, extraNotes: String = "", cluster: Cluster? = nil) {
        self.name = name
        self.species = species
        self.extraNotes = extraNotes
        self.createdAt = Date()
        self.cluster = cluster
    }
    
    // Computed property per l'ultima misurazione
    var latestMeasurement: Measurement? {
        measurements.sorted { $0.measurementDate > $1.measurementDate }.first
    }
    var latestLengthMeasurement: LengthMeasurement? {
        lengthMeasurements.sorted { $0.lengthmeasurementDate > $1.lengthmeasurementDate }.first
    }
    
    // Computed property per l'altezza e larghezza più recente
    var currentHeight: String? {
        guard let latest = latestMeasurement else { return nil }
        return latest.formattedHeight
    }
    var currentLength: String? {
        guard let latestLength = latestLengthMeasurement else { return nil }
        return latestLength.formattedLength
    }
    
}
