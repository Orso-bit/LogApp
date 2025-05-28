//
//  LengthHistoryView.swift
//  SwiftDataLog
//
//  Created by Vincenzo Salzano on 25/05/25.
//

import SwiftUI
import SwiftData

struct LengthHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let tree: Tree
    @Query private var lengthMeasurements: [LengthMeasurement]
    @State private var showingNewLengthMeasurement = false
    
    init(tree: Tree) {
        self.tree = tree
        // Filtra le misurazioni per questo specifico albero
        let treeId = tree.persistentModelID
        _lengthMeasurements = Query(
            filter: #Predicate<LengthMeasurement> { lengthMeasurement in
                lengthMeasurement.tree?.persistentModelID == treeId
            },
            sort: \LengthMeasurement.lengthmeasurementDate,
            order: .reverse
        )
    }
    
    var body: some View {
        NavigationView {
            List {
                if lengthMeasurements.isEmpty {
                    ContentUnavailableView(
                        "Nessuna misurazione",
                        systemImage: "ruler",
                        description: Text("Effettua la prima misurazione della larghezza del tronco")
                    )
                } else {
                    Section("Storico Misurazioni") {
                        ForEach(lengthMeasurements) { lengthMeasurement in
                            LengthMeasurementRowView(
                                lengthMeasurement: lengthMeasurement,
                                isLatest: lengthMeasurement.id == lengthMeasurements.first?.id
                            )
                        }
                        .onDelete(perform: deleteMeasurements)
                    }
                    
                    if lengthMeasurements.count > 1 {
                        Section("Statistiche") {
                            LengthStatisticsView(lengthMeasurements: lengthMeasurements)
                        }
                    }
                }
            }
            .navigationTitle("Misurazioni Larghezza")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Nuova Misurazione") {
                        showingNewLengthMeasurement = true
                    }
                }
            }
            .sheet(isPresented: $showingNewLengthMeasurement) {
                LengthMeasurementView(tree: tree)
            }
        }
    }
    
    private func deleteMeasurements(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(lengthMeasurements[index])
            }
        }
    }
}

struct LengthMeasurementRowView: View {
    let lengthMeasurement: LengthMeasurement
    let isLatest: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "ruler.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(lengthMeasurement.formattedLength)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(lengthMeasurement.lengthmeasurementDate, format: .dateTime.day().month().year().hour().minute())
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
            
            if !lengthMeasurement.notes.isEmpty {
                Text(lengthMeasurement.notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.leading, 28)
            }
        }
        .padding(.vertical, 4)
    }
}

struct LengthStatisticsView: View {
    let lengthMeasurements: [LengthMeasurement]
    
    private var averageLength: Double {
        let total = lengthMeasurements.reduce(0) { $0 + $1.length }
        return total / Double(lengthMeasurements.count)
    }
    
    private var maxLength: Double {
        lengthMeasurements.map(\.length).max() ?? 0
    }
    
    private var minLength: Double {
        lengthMeasurements.map(\.length).min() ?? 0
    }
    
    private var lengthVariation: Double {
        maxLength - minLength
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                LengthStatisticBox(
                    title: "Media",
                    value: String(format: "%.2f m", averageLength),
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                LengthStatisticBox(
                    title: "Massima",
                    value: String(format: "%.2f m", maxLength),
                    icon: "arrow.up.circle.fill"
                )
            }
            
            HStack {
                LengthStatisticBox(
                    title: "Minima",
                    value: String(format: "%.2f m", minLength),
                    icon: "arrow.down.circle.fill"
                )
                
                LengthStatisticBox(
                    title: "Variazione",
                    value: String(format: "%.2f m", lengthVariation),
                    icon: "arrow.up.arrow.down.circle"
                )
            }
            
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("Basato su \(lengthMeasurements.count) misurazioni")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct LengthStatisticBox: View {
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
