//
//  AddTreeView.swift
//  SwiftDataLog
//
//  Created by Vincenzo Salzano on 22/05/25.
//

import SwiftUI
import SwiftData

struct AddTreeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var clusters: [Cluster]
    
    @State private var treeName = ""
    @State private var treeSpecies = ""
    @State private var extraNotes = ""
    @State private var selectedCluster: Cluster?
    @State private var showingAddCluster = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Informazioni Albero") {
                    TextField("Nome albero", text: $treeName)
                    TextField("Specie", text: $treeSpecies)
                    TextField("Note extra", text: $extraNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
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
                    .disabled(treeName.isEmpty || treeSpecies.isEmpty || selectedCluster == nil)
                }
            }
            .sheet(isPresented: $showingAddCluster) {
                AddClusterView()
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
