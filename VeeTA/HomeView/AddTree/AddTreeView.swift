//
//  AddTreeView.swift
//  SwiftDataLog
//
//  Created by Vincenzo Salzano on 22/05/25.
//

import SwiftData
import AVFoundation
import SwiftUI
import ARKit
import RealityKit

struct AddTreeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var clusters: [Cluster]
    
    @State private var treeName = ""
    @State private var treeSpecies = ""
    @State private var extraNotes = ""
    @State private var selectedCluster: Cluster?
    @State private var showingAddCluster = false
    @State private var showingHeightMeasurement = false
    @State private var showingLengthMeasurement = false
    @State private var showingDiameterMeasurement = false
    @State private var showingClinometerMeasurement = false
    
    var body: some View {
        NavigationView {
            Form {
                //VTA
                Section("Informazioni Albero") {
                    TextField("Nome albero", text: $treeName)
                    TextField("Specie", text: $treeSpecies)
                    TextField("Note extra", text: $extraNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
                //Creazione o inserimento cluster
                Section("Cluster") {
                    if clusters.isEmpty {
                        Button("Crea nuovo cluster") {
                            showingAddCluster = true
                        }
                        .foregroundColor(.blue)
                    } else {
                        Picker("Seleziona cluster", selection: $selectedCluster) {
                            Text("Nessun cluster").tag(nil as Cluster?)
                            ForEach(clusters, id: \.self) { cluster in
                                Text(cluster.name).tag(cluster as Cluster?)
                            }
                        }
                        
                        Button("Crea nuovo cluster") {
                            showingAddCluster = true
                        }
                        .foregroundColor(.blue)
                    }
                }
                //Altimetro
                Section("Misurazione Altezza") {
                    Button(action: {
                        showingHeightMeasurement = true
                    }) {
                        HStack {
                            Image(systemName: "ruler")
                                .foregroundColor(.orange)
                            Text("Misura Altezza")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .disabled(treeName.isEmpty || treeSpecies.isEmpty)
                    
                    if treeName.isEmpty || treeSpecies.isEmpty {
                        Text("Inserisci nome e specie dell'albero per abilitare la misurazione")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                //Larghezza Tronco
                Section("Misurazione Larghezza") {
                    Button(action: {
                        showingLengthMeasurement = true
                    }) {
                        HStack {
                            Image(systemName: "ruler")
                                .foregroundColor(.orange)
                            Text("Misura Larghezza")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .disabled(treeName.isEmpty || treeSpecies.isEmpty)
                    
                    if treeName.isEmpty || treeSpecies.isEmpty {
                        Text("Inserisci nome e specie dell'albero per abilitare la misurazione")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                //Diametro Chioma
                Section("Misurazione Proiezione Chioma") {
                    Button(action: {
                        showingDiameterMeasurement = true
                    }) {
                        HStack {
                            Image(systemName: "ruler")
                                .foregroundColor(.orange)
                            Text("Misura Diametro Proiezione")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .disabled(treeName.isEmpty || treeSpecies.isEmpty)
                    
                    if treeName.isEmpty || treeSpecies.isEmpty {
                        Text("Inserisci nome e specie dell'albero per abilitare la misurazione")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                //Clinometro - Inclinazione Tronco
                Section("Misurazione Inclinazione Tronco") {
                    Button(action: {
                        showingClinometerMeasurement = true
                    }) {
                        HStack {
                            Image(systemName: "level")
                                .foregroundColor(.purple)
                            Text("Misura Inclinazione")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .disabled(treeName.isEmpty || treeSpecies.isEmpty)
                    
                    if treeName.isEmpty || treeSpecies.isEmpty {
                        Text("Inserisci nome e specie dell'albero per abilitare la misurazione")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
            }
            .navigationTitle("Aggiungi Albero")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salva") {
                        saveTree()
                    }
                    .disabled(treeName.isEmpty || treeSpecies.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddCluster) {
                AddClusterView()
            }
            .sheet(isPresented: $showingHeightMeasurement) {
                HeightMeasurementForNewTreeView(
                    treeName: treeName,
                    treeSpecies: treeSpecies,
                    extraNotes: extraNotes,
                    cluster: selectedCluster,
                    onSave: { tree in
                        // Inserisci l'albero con le misurazioni nel contesto
                        modelContext.insert(tree)
                        //dismiss()
                    }
                )
            }
            .sheet(isPresented: $showingLengthMeasurement) {
                LengthMeasurementForNewTreeView(
                    treeName: treeName,
                    treeSpecies: treeSpecies,
                    extraNotes: extraNotes,
                    cluster: selectedCluster,
                    onSave: { tree in
                        // Inserisci l'albero con le misurazioni nel contesto
                        modelContext.insert(tree)
                        // dismiss()
                    }
                )
            }
            .sheet(isPresented: $showingDiameterMeasurement) {
                DiameterMeasurementForNewTreeView(
                    treeName: treeName,
                    treeSpecies: treeSpecies,
                    extraNotes: extraNotes,
                    cluster: selectedCluster,
                    onSave: { tree in
                        // Inserisci l'albero con le misurazioni nel contesto
                        modelContext.insert(tree)
                        // dismiss()
                    }
                )
            }
            .sheet(isPresented: $showingClinometerMeasurement) {
                ClinometerForNewTreeView(
                    treeName: treeName,
                    treeSpecies: treeSpecies,
                    extraNotes: extraNotes,
                    cluster: selectedCluster,
                    onSave: { tree in
                        // Inserisci l'albero con le misurazioni nel contesto
                        modelContext.insert(tree)
                        // dismiss()
                    }
                )
            }
        }
    }
    
    private func saveTree() {
        let newTree = Tree(
            name: treeName,
            species: treeSpecies,
            extraNotes: extraNotes,
            cluster: selectedCluster
        )
        
        modelContext.insert(newTree)
        dismiss()
    }
}
