//
//  EditTreeView.swift
//  SwiftDataLog
//
//  Created by Vincenzo Salzano on 22/05/25.
//

import SwiftUI
import SwiftData

struct EditTreeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var clusters: [Cluster]
    
    @Bindable var tree: Tree
    
    @State private var showingHeightMeasurement = false
    @State private var showingLengthMeasurement = false
    @State private var showingDiameterMeasurement = false
    @State private var showingClinometerMeasurement = false
    @State private var showingMeasurementHistory = false
    @State private var showingLengthHistory = false
    @State private var showingDiameterHistory = false
    @State private var showingClinometerHistory = false
    
    var body: some View {
        NavigationStack {
            Form {
                //VTA
                Section("Informazioni Albero") {
                    TextField("Nome albero", text: $tree.name)
                    TextField("Specie", text: $tree.species)
                    TextField("Note extra", text: $tree.extraNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
                //Cluster
                Section("Cluster") {
                    Picker("Seleziona cluster", selection: $tree.cluster) {
                        Text("Nessun cluster").tag(nil as Cluster?)
                        ForEach(clusters, id: \.self) { cluster in
                            Text(cluster.name).tag(cluster as Cluster?)
                        }
                    }
                }
                //Altimetro
                Section("Misurazioni Altezza") {
                    if let currentHeight = tree.currentHeight {
                        HStack {
                            Image(systemName: "ruler.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Altezza attuale")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(currentHeight)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    
                    Button(action: {
                        showingHeightMeasurement = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.orange)
                            Text("Nuova Misurazione")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    if !tree.measurements.isEmpty {
                        Button(action: {
                            showingMeasurementHistory = true
                        }) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.blue)
                                Text("Storico Misurazioni")
                                Spacer()
                                Text("\(tree.measurements.count)")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
                //Larghezza tronco
                Section("Misurazioni Larghezza") {
                    if let currentLength = tree.currentLength {
                        HStack {
                            Image(systemName: "ruler.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Larghezza attuale")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(currentLength)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    
                    Button(action: {
                        showingLengthMeasurement = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.orange)
                            Text("Nuova Misurazione")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    if !tree.lengthMeasurements.isEmpty {
                        Button(action: {
                            showingLengthHistory = true
                        }) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.blue)
                                Text("Storico Misurazioni")
                                Spacer()
                                Text("\(tree.lengthMeasurements.count)")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
                //Chioma
                Section("Misurazioni Diametro Chioma") {
                    if let currentDiameter = tree.currentDiameter {
                        HStack {
                            Image(systemName: "ruler.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Diametro attuale")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(currentDiameter)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    
                    Button(action: {
                        showingDiameterMeasurement = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.orange)
                            Text("Nuova Misurazione")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    if !tree.treeProiection.isEmpty {
                        Button(action: {
                            showingDiameterHistory = true
                        }) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.blue)
                                Text("Storico Misurazioni")
                                Spacer()
                                Text("\(tree.treeProiection.count)")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                //Clinometro - Inclinazione Tronco
                Section("Misurazioni Inclinazione Tronco") {
                    if let currentInclination = tree.currentInclination {
                        HStack {
                            Image(systemName: "level.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Inclinazione attuale")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(currentInclination)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    
                    Button(action: {
                        showingClinometerMeasurement = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.purple)
                            Text("Nuova Misurazione")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    if !tree.clinometer.isEmpty {
                        Button(action: {
                            showingClinometerHistory = true
                        }) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.blue)
                                Text("Storico Misurazioni")
                                Spacer()
                                Text("\(tree.clinometer.count)")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                Section("Informazioni") {
                    HStack {
                        Text("Creato il:")
                        Spacer()
                        Text(tree.createdAt, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                            .foregroundColor(.secondary)
                    }
                    
                    if !tree.measurements.isEmpty {
                        HStack {
                            Text("Misurazioni Altezza:")
                            Spacer()
                            Text("\(tree.measurements.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                    if !tree.lengthMeasurements.isEmpty {
                        HStack {
                            Text("Misurazioni Larghezza:")
                            Spacer()
                            Text("\(tree.lengthMeasurements.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                    if !tree.treeProiection.isEmpty {
                        HStack {
                            Text("Misurazioni Chioma:")
                            Spacer()
                            Text("\(tree.treeProiection.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                    if !tree.clinometer.isEmpty {
                        HStack {
                            Text("Misurazioni Inclinazione:")
                            Spacer()
                            Text("\(tree.clinometer.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Modifica Albero")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salva") {
                        saveChanges()
                        dismiss()
                    }
                    .disabled(tree.name.isEmpty || tree.species.isEmpty)
                }
            }
            .sheet(isPresented: $showingHeightMeasurement) {
                HeightMeasurementView(tree: tree)
            }
            .sheet(isPresented: $showingMeasurementHistory) {
                MeasurementHistoryView(tree: tree)
            }
            .sheet(isPresented: $showingLengthMeasurement) {
                LengthMeasurementView(tree: tree)
            }
            .sheet(isPresented: $showingLengthHistory) {
                LengthHistoryView(tree: tree)
            }
            .sheet(isPresented: $showingDiameterMeasurement) {
                DiameterView(tree: tree)
            }
            .sheet(isPresented: $showingDiameterHistory) {
                DiameterHistoryView(tree: tree)
            }
            .sheet(isPresented: $showingClinometerMeasurement) {
                ClinometerView(tree: tree)
            }
            .sheet(isPresented: $showingClinometerHistory) {
                ClinometerHistoryView(tree: tree)
            }
        }
    }
    
    private func saveChanges() {
        // Con @Bindable, le modifiche vengono salvate automaticamente
        // Ma possiamo forzare il salvataggio se necessario
        do {
            try modelContext.save()
        } catch {
            print("Errore nel salvare le modifiche: \(error)")
        }
    }
}
