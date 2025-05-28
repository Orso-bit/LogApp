//
//  ClinometerHistoryView.swift
//  VeeTA
//
//  Created by Vincenzo Salzano on 27/05/25.
//


//
//  ClinometerHistoryView.swift
//  VeeTA
//
//  Created by Vincenzo Salzano on 27/05/25.
//

import SwiftUI
import SwiftData

struct ClinometerHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let tree: Tree
    @Query private var measurements: [Clinometer]
    @State private var showingNewMeasurement = false
    
    init(tree: Tree) {
        self.tree = tree
        // Filtra le misurazioni del clinometro per questo specifico albero
        let treeId = tree.persistentModelID
        _measurements = Query(
            filter: #Predicate<Clinometer> { measurement in
                measurement.tree?.persistentModelID == treeId
            },
            sort: \Clinometer.inclinationDate,
            order: .reverse
        )
    }
    
    var body: some View {
        NavigationView {
            List {
                if measurements.isEmpty {
                    ContentUnavailableView(
                        "Nessuna misurazione",
                        systemImage: "level",
                        description: Text("Effettua la prima misurazione dell'inclinazione del tronco")
                    )
                } else {
                    Section("Storico Misurazioni Inclinazione") {
                        ForEach(measurements) { measurement in
                            ClinometerRowView(measurement: measurement, isLatest: measurement.id == measurements.first?.id)
                        }
                        .onDelete(perform: deleteMeasurements)
                    }
                    
                    if measurements.count > 1 {
                        Section("Statistiche Inclinazione") {
                            ClinometerStatisticsView(measurements: measurements)
                        }
                    }
                }
            }
            .navigationTitle("Misurazioni Inclinazione")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Nuova Misurazione") {
                        showingNewMeasurement = true
                    }
                }
            }
            .sheet(isPresented: $showingNewMeasurement) {
                ClinometerView(tree: tree)
            }
        }
    }
    
    private func deleteMeasurements(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(measurements[index])
            }
        }
    }
}

struct ClinometerRowView: View {
    let measurement: Clinometer
    let isLatest: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "level.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.2f°", measurement.inclination))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(measurement.inclinationDate, format: .dateTime.day().month().year().hour().minute())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Indicatore visivo dell'inclinazione
                InclinationIndicatorSmall(inclination: measurement.inclination)
                
                if isLatest {
                    Text("Più recente")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                }
            }
            
            if !measurement.notes.isEmpty {
                Text(measurement.notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.leading, 28)
            }
        }
        .padding(.vertical, 4)
    }
}

// Piccolo indicatore visivo dell'inclinazione
struct InclinationIndicatorSmall: View {
    let inclination: Double
    
    private var inclinationColor: Color {
        let absInclination = abs(inclination)
        switch absInclination {
        case 0..<5:
            return .green
        case 5..<15:
            return .yellow
        case 15..<30:
            return .orange
        default:
            return .red
        }
    }
    
    private var inclinationCategory: String {
        let absInclination = abs(inclination)
        switch absInclination {
        case 0..<5:
            return "A"
        case 5..<15:
            return "B"
        case 15..<30:
            return "C"
        case 30..<80:
            return "C-D"
        default:
            return "D"
        }
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            // Indicatore grafico mini
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 30, height: 20)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(inclinationColor)
                    .frame(width: 2, height: 16)
                    .rotationEffect(.degrees(max(-45, min(45, inclination))))
            }
            
            Text(inclinationCategory)
                .font(.caption2)
                .foregroundColor(inclinationColor)
                .fontWeight(.medium)
        }
    }
}

struct ClinometerStatisticsView: View {
    let measurements: [Clinometer]
    
    private var averageInclination: Double {
        let total = measurements.reduce(0) { $0 + $1.inclination }
        return total / Double(measurements.count)
    }
    
    private var maxInclination: Double {
        measurements.map(\.inclination).max() ?? 0
    }
    
    private var minInclination: Double {
        measurements.map(\.inclination).min() ?? 0
    }
    
    private var inclinationRange: Double {
        maxInclination - minInclination
    }
    
    private var standardDeviation: Double {
        let mean = averageInclination
        let variance = measurements.reduce(0) { sum, measurement in
            sum + pow(measurement.inclination - mean, 2)
        } / Double(measurements.count)
        return sqrt(variance)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                ClinometerStatisticBox(
                    title: "Media",
                    value: String(format: "%.2f°", averageInclination),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                )
                
                ClinometerStatisticBox(
                    title: "Massima",
                    value: String(format: "%.2f°", maxInclination),
                    icon: "arrow.up.circle.fill",
                    color: .red
                )
            }
            
            HStack {
                ClinometerStatisticBox(
                    title: "Minima",
                    value: String(format: "%.2f°", minInclination),
                    icon: "arrow.down.circle.fill",
                    color: .green
                )
                
                ClinometerStatisticBox(
                    title: "Variazione",
                    value: String(format: "%.2f°", inclinationRange),
                    icon: "arrow.up.arrow.down.circle",
                    color: .orange
                )
            }
            
            HStack {
                ClinometerStatisticBox(
                    title: "Dev. Standard",
                    value: String(format: "%.2f°", standardDeviation),
                    icon: "waveform.path.ecg",
                    color: .purple
                )
                
                ClinometerStatisticBox(
                    title: "Stabilità",
                    value: stabilityCategory,
                    icon: "checkmark.shield.fill",
                    color: stabilityColor
                )
            }
            
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("Basato su \(measurements.count) misurazioni")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var stabilityCategory: String {
        switch standardDeviation {
        case 0..<2:
            return "Ottima"
        case 2..<5:
            return "Buona"
        case 5..<10:
            return "Discreta"
        default:
            return "Variabile"
        }
    }
    
    private var stabilityColor: Color {
        switch standardDeviation {
        case 0..<2:
            return .green
        case 2..<5:
            return .blue
        case 5..<10:
            return .orange
        default:
            return .red
        }
    }
}

struct ClinometerStatisticBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
