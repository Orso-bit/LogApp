//
//  HomeView.swift
//  SwiftDataLog
//
//  Created by Vincenzo Salzano on 22/05/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var clusters: [Cluster]
    @Query private var trees: [Tree]
    
    @State private var showingAddOptions = false
    @State private var showingAddTree = false
    @State private var showingAddCluster = false
    @State private var showingEditTree = false
    @State private var selectedTreeToEdit: Tree?
    
    var orphanTrees: [Tree] {
        trees.filter { $0.cluster == nil }
    }
    
    var body: some View {
        NavigationSplitView {
            List {
                // Sezione Cluster
                if !clusters.isEmpty {
                    Section("Cluster") {
                        ForEach(clusters, id: \.self) { cluster in
                            NavigationLink {
                                ClusterDetailView(cluster: cluster)
                            } label: {
                                HStack {
                                    Image(systemName: "folder")
                                        .foregroundColor(.blue)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(cluster.name)
                                            .font(.headline)
                                        Text("\(cluster.trees.count) alberi")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteClusters)
                    }
                }
                
                // Sezione Alberi senza cluster
                if !orphanTrees.isEmpty {
                    Section("Alberi senza cluster") {
                        ForEach(orphanTrees) { tree in
                            Button(action: {
                                selectedTreeToEdit = tree
                                showingEditTree = true
                            }) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tree.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(tree.species)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    if !tree.extraNotes.isEmpty {
                                        Text(tree.extraNotes)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                                .padding(.vertical, 2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .onDelete(perform: deleteOrphanTrees)
                    }
                }
                
                // Messaggio se non ci sono dati
                if clusters.isEmpty && orphanTrees.isEmpty {
                    ContentUnavailableView(
                        "Inizia la tua VTA",
                        systemImage: "tree.circle",
                        description: Text("Crea il tuo primo cluster o aggiungi un albero per iniziare")
                    )
                }
            }
            .navigationTitle("VTA")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddOptions = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .confirmationDialog("Aggiungi", isPresented: $showingAddOptions) {
                Button("Nuovo Albero") {
                    showingAddTree = true
                }
                Button("Nuovo Cluster") {
                    showingAddCluster = true
                }
                Button("Annulla", role: .cancel) { }
            }
            .sheet(isPresented: $showingAddTree) {
                AddTreeView()
            }
            .sheet(isPresented: $showingAddCluster) {
                AddClusterView()
            }
            .sheet(isPresented: $showingEditTree) {
                if let tree = selectedTreeToEdit {
                    EditTreeView(tree: tree)
                }
            }
        } detail: {
            VStack {
                Image(systemName: "tree.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                Text("Visual Tree Assessment")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Seleziona un cluster per visualizzare i suoi alberi")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
    
    private func deleteClusters(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(clusters[index])
            }
        }
    }
    
    private func deleteOrphanTrees(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(orphanTrees[index])
            }
        }
    }
}

#Preview {
    let modelContainer = try! ModelContainer(for: Cluster.self, Tree.self, configurations: .init(isStoredInMemoryOnly: true))
    
    return HomeView()
        .modelContainer(modelContainer)
}

