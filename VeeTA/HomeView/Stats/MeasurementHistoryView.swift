//
//  MeasurementHistoryView.swift
//  SwiftDataLog
//
//  Created by Vincenzo Salzano on 24/05/25.
//


import SwiftUI
import SwiftData

struct MeasurementHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let tree: Tree
    @Query private var measurements: [Measurement]
    @State private var showingNewMeasurement = false
    
    init(tree: Tree) {
        self.tree = tree
        // Filtra le misurazioni per questo specifico albero
        let treeId = tree.persistentModelID
        _measurements = Query(
            filter: #Predicate<Measurement> { measurement in
                measurement.tree?.persistentModelID == treeId
            },
            sort: \Measurement.measurementDate,
            order: .reverse
        )
    }
    
    var body: some View {
        NavigationView {
            List {
                if measurements.isEmpty {
                    ContentUnavailableView(
                        "Nessuna misurazione",
                        systemImage: "ruler",
                        description: Text("Effettua la prima misurazione dell'altezza")
                    )
                } else {
                    Section("Storico Misurazioni") {
                        ForEach(measurements) { measurement in
                            MeasurementRowView(measurement: measurement, isLatest: measurement.id == measurements.first?.id)
                        }
                        .onDelete(perform: deleteMeasurements)
                    }
                    
                    if measurements.count > 1 {
                        Section("Statistiche") {
                            StatisticsView(measurements: measurements)
                        }
                    }
                }
            }
            .navigationTitle("Misurazioni")
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
                HeightMeasurementView(tree: tree)
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

struct MeasurementRowView: View {
    let measurement: Measurement
    let isLatest: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "ruler.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(measurement.formattedHeight)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(measurement.measurementDate, format: .dateTime.day().month().year().hour().minute())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
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
    
    private var measurements: [Measurement] {
        // Questo è un workaround per accedere alle misurazioni ordinate
        // In un'implementazione reale dovresti passare l'array ordinato come parametro
        return []
    }
}

struct StatisticsView: View {
    let measurements: [Measurement]
    
    private var averageHeight: Double {
        let total = measurements.reduce(0) { $0 + $1.height }
        return total / Double(measurements.count)
    }
    
    private var maxHeight: Double {
        measurements.map(\.height).max() ?? 0
    }
    
    private var minHeight: Double {
        measurements.map(\.height).min() ?? 0
    }
    
    private var heightVariation: Double {
        maxHeight - minHeight
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                StatisticBox(
                    title: "Media",
                    value: String(format: "%.2f m", averageHeight),
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                StatisticBox(
                    title: "Massima",
                    value: String(format: "%.2f m", maxHeight),
                    icon: "arrow.up.circle.fill"
                )
            }
            
            HStack {
                StatisticBox(
                    title: "Minima",
                    value: String(format: "%.2f m", minHeight),
                    icon: "arrow.down.circle.fill"
                )
                
                StatisticBox(
                    title: "Variazione",
                    value: String(format: "%.2f m", heightVariation),
                    icon: "arrow.up.arrow.down.circle"
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
}

struct StatisticBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
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
