//
//  SwiftUIView.swift
//  Log
//
//  Created by Alessandro Rippa on 22/05/25.
//

import SwiftUI

struct SwiftUIView: View {
    @State private var search : String = " "
    
    
    var body: some View {
        
        NavigationStack{
            
            List{
                
                ForEach(0..<10){ index in
                    
                    
                    NavigationLink{
                        DiaryView()
                    } label: {
                        ZStack{
                            Color.green
                                
                            
                            Text ("Cluster")
                        }
                        
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
    SwiftUIView()
}
