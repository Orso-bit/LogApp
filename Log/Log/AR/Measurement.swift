//
//  Measurement.swift
//  Log
//
//  Created by Giovanni Jr Di Fenza on 21/05/25.
//

import SwiftUI
import CoreMotion

struct Measurement: Identifiable {
    let id = UUID()
    let treeName: String
    let mode: MeasurementMode
    let primaryAngle: Double
    let secondaryAngle: Double
    let distance: Double?
    let estimatedHeight: Double?
    let date: Date
    var notes: String
    
    var formattedPrimaryValue: String {
        switch mode {
        case .treeLean:
            return String(format: "%.1f°", primaryAngle)
        case .slopeGrade:
            let percentGrade = tan(primaryAngle * .pi / 180.0) * 100.0
            return String(format: "%.1f° (%.1f%%)", primaryAngle, percentGrade)
        case .treeHeight:
            return String(format: "%.1f m", estimatedHeight ?? 0)
        }
    }
    
    var formattedSecondaryValue: String {
        switch mode {
        case .treeLean:
            return String(format: "%.1f°", secondaryAngle)
        case .slopeGrade:
            return ""
        case .treeHeight:
            return distance != nil ? String(format: "%.0f m", distance!) : ""
        }
    }
    
    var secondaryLabel: String {
        switch mode {
        case .treeLean:
            return "Secondaria:"
        case .slopeGrade:
            return ""
        case .treeHeight:
            return "Distanza:"
        }
    }
    
    var statusLevel: StatusLevel {
        switch mode {
        case .treeLean:
            let maxInclination = max(abs(primaryAngle), abs(secondaryAngle))
            if maxInclination < 1.5 {
                return .optimal
            } else if maxInclination < 5 {
                return .good
            } else if maxInclination < 10 {
                return .warning
            } else if maxInclination < 15 {
                return .concern
            } else {
                return .critical
            }
        case .slopeGrade:
            let percentGrade = abs(tan(primaryAngle * .pi / 180.0) * 100.0)
            if percentGrade < 5 {
                return .optimal
            } else if percentGrade < 10 {
                return .good
            } else if percentGrade < 20 {
                return .warning
            } else if percentGrade < 30 {
                return .concern
            } else {
                return .critical
            }
        case .treeHeight:
            return .neutral
        }
    }
}

enum StatusLevel: String {
    case optimal = "Ottimale"
    case good = "Buono"
    case warning = "Attenzione"
    case concern = "Preoccupante"
    case critical = "Critico"
    case neutral = "Neutro"
    
    var color: Color {
        switch self {
        case .optimal: return .green
        case .good: return .green.opacity(0.7)
        case .warning: return .yellow
        case .concern: return .orange
        case .critical: return .red
        case .neutral: return .blue
        }
    }
}
