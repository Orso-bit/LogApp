//
//  ClusterDetailView.swift
//  SwiftDataLog
//
//  Created by Vincenzo Salzano on 22/05/25.
//

import SwiftUI
import SwiftData

struct ClusterDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let cluster: Cluster
    
    @State private var showingAddTree = false
    @State private var selectedTreeToEdit: Tree?
    @State private var searchableText: String = ""
    
    var body: some View {
        NavigationStack{
        List {
            if cluster.trees.isEmpty {
                ContentUnavailableView(
                    "Nessun albero",
                    systemImage: "tree",
                    description: Text("Aggiungi il primo albero a questo cluster")
                )
            } else {
                ForEach(cluster.trees) { tree in
                    NavigationLink{
                        TreeView(tree: tree)
                    }label:{
                        VStack(alignment: .leading, spacing: 4) {
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
                            }
                            Text("Creato: \(tree.createdAt, format: Date.FormatStyle(date: .abbreviated, time: .shortened))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .onDelete(perform: deleteTrees)
            }
        }
        .searchable(text: $searchableText)
        .listStyle(.plain)
        .navigationTitle(cluster.name)
        //.navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem() {
                Button(action: {
                    showingAddTree = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        
    }
        .sheet(isPresented: $showingAddTree) {
            AddTreeView()
        }
        /*
        .sheet(item: $selectedTreeToEdit) { tree in
            NavigationStack {
                //EditTreeView(tree: tree)
                TreeView(tree:tree)
            }
        }
         */
    }
    
    private func deleteTrees(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(cluster.trees[index])
            }
        }
    }
}
