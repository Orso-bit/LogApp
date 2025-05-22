//
//  DiaryView.swift
//  Log
//
//  Created by Alessandro Rippa on 22/05/25.
//

import SwiftUI

struct DiaryView: View {
    @State private var search : String = ""
    
    
    var body: some View {
        
        NavigationStack{
            List {
                
                NavigationLink{
                    TreeView()
                } label: {
                    Text ("Tree")
                }
                
            }
            .listStyle(.plain)
            .navigationTitle("Cluster name")
            .searchable(text: $search)
        }
    }
}

#Preview {
    DiaryView()
}
