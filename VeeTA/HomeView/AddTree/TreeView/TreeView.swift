//
//  TreeView.swift
//  VeeTA
//
//  Created by Alessandro Rippa on 29/05/25.
//

import SwiftUI
import SwiftData

struct TreeView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var clusters: [Cluster]
    
    @Bindable var tree: Tree
    @State private var selectedTreeToEdit: Tree?
    @State private var mapIsSelected: Bool = false
    
    @State private var showingHeightMeasurement = false
    @State private var showingLengthMeasurement = false
    @State private var showingDiameterMeasurement = false
    @State private var showingClinometerMeasurement = false
    @State private var showingMeasurementHistory = false
    @State private var showingLengthHistory = false
    @State private var showingDiameterHistory = false
    @State private var showingClinometerHistory = false
    
    
    
    var body: some View {
        
        NavigationView{
                
            ScrollView(showsIndicators: false){
                
                Divider()
                
                VStack(spacing:20){
                    
                    HStack{
                        Text("CLUSTER")
                          
                        Spacer()
                        
                        Text("\(tree.name)")
                            .fontWeight(.light)
                        
                    }.padding(.horizontal,25)
                    
                    HStack{
                        Text("SPECIES")
                          
                        Spacer()
                        
                        Text("\(tree.species)")
                            .fontWeight(.light)
                        
                    }.padding(.horizontal,25)
                    
                    HStack{
                        Text("ADDED")
                          
                        Spacer()
                        
                        Text(tree.createdAt.formatted())
                            .fontWeight(.light)
                        
                    }.padding(.horizontal,25)
                    
                    HStack{
                        Text("LAST MODIFIED")
                          
                        Spacer()
                        
                        Text(tree.createdAt.formatted())
                            .fontWeight(.light)
                        //DA MODIFICARE!!! AL MOMENTO NON ESISTE LAST MODIFIED COME PARAMETRO
                        
                    }.padding(.horizontal,25)
                    

                }
                .padding(.vertical,25)
                
                
                MeasurementView(tree: tree)
                    .padding(.horizontal,10)
                    .padding(.vertical,25)
                
                VStack(spacing:5){
                    HStack{
                        Text("Notes")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.accent)
                        Spacer()
                    }
                    .padding(.horizontal, 25)
                    
                    Text("\(tree.extraNotes)")
                        .padding()
                        .background(.gray.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius:30))
                        .padding(.horizontal,20)
                }
            }
            .navigationTitle("Tree")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button{
                        selectedTreeToEdit = tree
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button{
                        mapIsSelected = true
                    } label: {
                        Image(systemName: "map.fill")
                    }
                }
            }
        }
        .sheet(item: $selectedTreeToEdit) { tree in
            NavigationStack {
                EditTreeView(tree: tree)
                
            }
        }
        .sheet(isPresented: $mapIsSelected){
            MapView()
        }
    }
}

#Preview {
    TreeView(tree: .init(name: "Albero", species: "Bertullo", extraNotes: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam nec tortor urna. Praesent id lacus vel orci fermentum lacinia vel non lorem. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Nullam aliquet auctor felis, ac blandit mauris venenatis id. Phasellus iaculis orci non ligula sollicitudin pellentesque. Proin quam nulla, euismod non ante eu, ultricies eleifend lacus. Integer euismod, sapien nec pellentesque luctus, nisl leo tristique nunc, quis auctor nisl enim ut est. Aenean tellus est, vehicula vitae tempor sed, eleifend vitae felis. Aenean et erat eu elit pharetra interdum. Praesent pretium mi eros, sit amet tristique leo finibus ut. Aenean et nulla pharetra sapien ultrices accumsan. Quisque venenatis egestas eros, non ultrices lectus volutpat eu. Vestibulum sed lorem a neque condimentum consequat at id velit. Nulla varius viverra lectus, non cursus sem accumsan id. "))
}
