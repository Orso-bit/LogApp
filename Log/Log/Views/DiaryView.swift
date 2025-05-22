//
//  SwiftUIView.swift
//  Log
//
//  Created by Alessandro Rippa on 22/05/25.
//

import SwiftUI

struct DiaryView: View {
    @State private var search : String = " "
    
    
    var body: some View {
        
        NavigationStack{
            
            List{
                
                ForEach(0..<10){ index in
                    
                    
                    NavigationLink{
                        ClusterView()
                    } label: {
                        
                        Text ("Cluster")
                        
                    }
                    
                }
                
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink{
                        ToolView()
                    } label:{
                        Image(systemName: "plus")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Clusters")
            .accessibilityLabel("Clusters")
            .searchable(text: $search)
        }
        
    }
    
}

#Preview {
    DiaryView()
}
