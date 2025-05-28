//
//  DiameterHistoryView.swift
//  VeeTA
//
//  Created by Vincenzo Salzano on 26/05/25.
//


import SwiftUI
import SwiftData

struct DiameterHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let tree: Tree
    @Query private var diameters: [TreeProiection]
    @State private var showingNewDiameter = false
    
    init(tree: Tree) {
        self.tree = tree
        // Filtra le misurazioni per questo specifico albero
        let treeId = tree.persistentModelID
        _diameters = Query(
            filter: #Predicate<TreeProiection> { treeProiection in
                treeProiection.tree?.persistentModelID == treeId
            },
            sort: \TreeProiection.diameterDate,
            order: .reverse
        )
    }
    
    var body: some View {
        NavigationView {
            List {
                if diameters.isEmpty {
                    ContentUnavailableView(
                        "Nessuna misurazione",
                        systemImage: "ruler",
                        description: Text("Effettua la prima misurazione della proiezione della chioma")
                    )
                } else {
                    Section("Storico Misurazioni") {
                        ForEach(diameters) { treeProiection in
                            DiameterRowView(treeProiection: treeProiection, isLatest: treeProiection.id == diameters.first?.id)
                        }
                        .onDelete(perform: deleteMeasurements)
                    }
                    
                    if diameters.count > 1 {
                        Section("Statistiche") {
                            DiameterStatisticsView(diameters: diameters)
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
                        showingNewDiameter = true
                    }
                }
            }
            .sheet(isPresented: $showingNewDiameter) {
                DiameterView(tree: tree)
            }
        }
    }
    
    private func deleteMeasurements(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(diameters[index])
            }
        }
    }
}

struct DiameterRowView: View {
    let treeProiection: TreeProiection
    let isLatest: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "ruler.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(treeProiection.formattedDiameter)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(treeProiection.diameterDate, format: .dateTime.day().month().year().hour().minute())
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
            
            if !treeProiection.notes.isEmpty {
                Text(treeProiection.notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.leading, 28)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var diameters: [TreeProiection] {
        // Questo è un workaround per accedere alle misurazioni ordinate
        // In un'implementazione reale dovresti passare l'array ordinato come parametro
        return []
    }
}

struct DiameterStatisticsView: View {
    let diameters: [TreeProiection]
    
    private var averageDiameter: Double {
        let total = diameters.reduce(0) { $0 + $1.diameter }
        return total / Double(diameters.count)
    }
    
    private var maxDiameter: Double {
        diameters.map(\.diameter).max() ?? 0
    }
    
    private var minDiameter: Double {
        diameters.map(\.diameter).min() ?? 0
    }
    
    private var diameterVariation: Double {
        maxDiameter - minDiameter
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                DiameterStatisticBox(
                    title: "Media",
                    value: String(format: "%.2f m", averageDiameter),
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                DiameterStatisticBox(
                    title: "Massima",
                    value: String(format: "%.2f m", maxDiameter),
                    icon: "arrow.up.circle.fill"
                )
            }
            
            HStack {
                DiameterStatisticBox(
                    title: "Minima",
                    value: String(format: "%.2f m", minDiameter),
                    icon: "arrow.down.circle.fill"
                )
                
                DiameterStatisticBox(
                    title: "Variazione",
                    value: String(format: "%.2f m", diameterVariation),
                    icon: "arrow.up.arrow.down.circle"
                )
            }
            
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("Basato su \(diameters.count) misurazioni")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct DiameterStatisticBox: View {
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
