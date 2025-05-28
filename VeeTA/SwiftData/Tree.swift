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
    @Relationship(deleteRule: .cascade, inverse: \TreeProiection.tree)
    var treeProiection: [TreeProiection] = []
    @Relationship(deleteRule: .cascade, inverse: \Clinometer.tree)
    var clinometer: [Clinometer] = []
    
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
    var latestDiameterMeasurement: TreeProiection? {
        treeProiection.sorted { $0.diameterDate > $1.diameterDate }.first
    }
    var latestClinometerMeasurement: Clinometer? {
        clinometer.sorted { $0.inclinationDate > $1.inclinationDate }.first
    }
    
    // Computed property per l'altezza,larghezza e diametro proiezione più recente
    var currentHeight: String? {
        guard let latest = latestMeasurement else { return nil }
        return latest.formattedHeight
    }
    var currentLength: String? {
        guard let latestLength = latestLengthMeasurement else { return nil }
        return latestLength.formattedLength
    }
    var currentDiameter: String? {
        guard let latestDiameter = latestDiameterMeasurement else { return nil }
        return latestDiameter.formattedDiameter
    }
    var currentInclination: String? {
        guard let latestInclination = latestClinometerMeasurement else { return nil }
        return latestInclination.formattedInclination
    }
}
