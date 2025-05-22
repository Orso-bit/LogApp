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
    
    var body: some View {
        NavigationView {
            Form {
                Section("Informazioni Albero") {
                    TextField("Nome albero", text: $tree.name)
                    TextField("Specie", text: $tree.species)
                    TextField("Note extra", text: $tree.extraNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Cluster") {
                    Picker("Seleziona cluster", selection: $tree.cluster) {
                        Text("Nessun cluster").tag(nil as Cluster?)
                        ForEach(clusters, id: \.self) { cluster in
                            Text(cluster.name).tag(cluster as Cluster?)
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
                        dismiss()
                    }
                    .disabled(tree.name.isEmpty || tree.species.isEmpty)
                }
            }
        }
    }
}
