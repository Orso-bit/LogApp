//
//  UIAssets.swift
//  VeeTA
//
//  Created by Alessandro Rippa on 29/05/25.
//

import SwiftUI
import SwiftData

struct MeasurementView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var clusters: [Cluster]
    
    @Bindable var tree: Tree
    
    
    @State private var showingHeightMeasurement = false
    @State private var showingLengthMeasurement = false
    @State private var showingDiameterMeasurement = false
    @State private var showingClinometerMeasurement = false
    @State private var showingMeasurementHistory = false
    @State private var showingLengthHistory = false
    @State private var showingDiameterHistory = false
    @State private var showingClinometerHistory = false
    
    
    var body: some View {
        
        var projection: Int = 30
        
        VStack{
            HStack{
                
                    ZStack{
                        RoundedRectangle(cornerRadius: 15)
                            .frame(height:100)
                            .foregroundStyle(.accent)
                        
                        VStack{
                            Image(systemName: "ruler.fill")
                                .foregroundStyle(.white)
                            if let currentHeight = tree.currentHeight{
                                VStack{
                                    Text(currentHeight)
                                        .lineLimit(1)
                                        .font(.title)
                                        .fontWeight(.regular)
                                        .foregroundColor(Color.white)
                                }
                            } else {
                                Text ("unknown")
                                    .font(.title)
                                    .fontWeight(.regular)
                                    .foregroundColor(Color.white)
                            }
                            Text("height")
                                .font(.title3)
                                .fontWeight(.thin)
                                .foregroundColor(Color.white)
                        }
                        
                    }
                
                
                
                    ZStack{
                        RoundedRectangle(cornerRadius: 15)
                            .frame(height:100)
                            .foregroundStyle(.accent)
                        
                        VStack{
                            Image(systemName: "ruler.fill")
                                .foregroundStyle(.white)
                            if let currentLength = tree.currentLength{
                                VStack{
                                    Text(currentLength)
                                        .lineLimit(1)
                                        .font(.title)
                                        .fontWeight(.regular)
                                        .foregroundColor(Color.white)
                                }
                            } else {
                                Text ("unknown")
                                    .font(.title)
                                    .fontWeight(.regular)
                                    .foregroundColor(Color.white)
                            }
                            Text("trunk diameter")
                                .font(.title3)
                                .fontWeight(.thin)
                                .foregroundColor(Color.white)
                        }
                        
                        
                    }
                
                
            }
            HStack{
                //if let current
                ZStack{
                    RoundedRectangle(cornerRadius: 15)
                        .frame(height:100)
                        .foregroundStyle(.accent)
                    
                    VStack{
                        Image(systemName: "angle")
                            .foregroundStyle(.white)
                        if let currentInclination = tree.currentInclination{
                            VStack{
                                Text(currentInclination)
                                    .lineLimit(1)
                                    .font(.title)
                                    .fontWeight(.regular)
                                    .foregroundColor(Color.white)
                            }
                        } else {
                            Text ("unknown")
                                .font(.title)
                                .fontWeight(.regular)
                                .foregroundColor(Color.white)
                        }
                        Text("inclination")
                            .font(.title3)
                            .fontWeight(.thin)
                            .foregroundColor(Color.white)
                    }
            
                    
                }
                
                ZStack{
                    RoundedRectangle(cornerRadius: 15)
                        .frame(height:100)
                        .foregroundStyle(.accent)
                    
                    VStack{
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(.white)
                        if let currentProjection = tree.currentDiameter{
                            VStack{
                                Text(currentProjection)
                                    .lineLimit(1)
                                    .font(.title)
                                    .fontWeight(.regular)
                                    .foregroundColor(Color.white)
                            }
                        } else {
                            Text ("unknown")
                                .font(.title)
                                .fontWeight(.regular)
                                .foregroundColor(Color.white)
                        }
                        Text("crown projection")
                            .font(.title3)
                            .fontWeight(.thin)
                            .foregroundColor(Color.white)
                    }
            
                    
                }
            }
        }
    }
}

#Preview {
    MeasurementView(tree: .init(name: "Albero", species: "Bertullo", extraNotes: "Non è un vero albero"))
}
