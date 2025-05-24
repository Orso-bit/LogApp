//
//  TreeView.swift
//  Log
//
//  Created by Alessandro Rippa on 22/05/25.
//

import SwiftUI

struct TreeView: View {
    var body: some View {
        NavigationStack {
            Text("TREE")
                .font(.largeTitle)
            NavigationLink{
                MapView()
            } label: {
                
                Image(systemName: "map")
            }
        }
    }
}

#Preview {
    TreeView()
}
