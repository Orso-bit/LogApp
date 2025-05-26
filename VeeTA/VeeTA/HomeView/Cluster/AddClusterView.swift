//
//  AddClusterView.swift
//  SwiftDataLog
//
//  Created by Vincenzo Salzano on 22/05/25.
//

import SwiftUI
import SwiftData

struct AddClusterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var clusterName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Informazioni Cluster") {
                    TextField("Nome cluster", text: $clusterName)
                }
            }
            .navigationTitle("Nuovo Cluster")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salva") {
                        saveCluster()
                    }
                    .disabled(clusterName.isEmpty)
                }
            }
        }
    }
    
    private func saveCluster() {
        let newCluster = Cluster(name: clusterName)
        modelContext.insert(newCluster)
        dismiss()
    }
}
