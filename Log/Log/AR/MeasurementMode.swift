//
//  MeasurementMode.swift
//  Log
//
//  Created by Giovanni Jr Di Fenza on 21/05/25.
//

import SwiftUI
import CoreMotion

enum MeasurementMode: String, CaseIterable, Identifiable {
    case treeLean = "Inclinazione Albero"
    case slopeGrade = "Pendenza Terreno"
    case treeHeight = "Altezza Albero"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .treeLean:
            return "Misura la deviazione dell'albero dalla verticale"
        case .slopeGrade:
            return "Misura la pendenza del terreno"
        case .treeHeight:
            return "Calcola l'altezza usando distanza e angolo"
        }
    }
}

// Measurement axes
enum MeasurementAxis: String, CaseIterable, Identifiable {
    case longitudinal = "Longitudinale" // forward/backward
    case lateral = "Laterale" // side to side
    
    var id: String { self.rawValue }
}
