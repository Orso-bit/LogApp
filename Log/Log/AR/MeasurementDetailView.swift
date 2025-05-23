//
//  MeasurementDetailView.swift
//  Log
//
//  Created by Giovanni Jr Di Fenza on 21/05/25.
//

import SwiftUI
import CoreMotion

struct MeasurementDetailView: View {
    var measurement: Measurement
    @Binding var editingNotes: String
    var onSave: (String) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informazioni")) {
                    HStack {
                        Text("Nome:")
                        Spacer()
                        Text(measurement.treeName)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Modalità:")
                        Spacer()
                        Text(measurement.mode.rawValue)
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("Data:")
                        Spacer()
                        Text(formatDate(measurement.date))
                    }
                }
                
                Section(header: Text("Misurazioni")) {
                    HStack {
                        switch measurement.mode {
                        case .treeLean:
                            Text("Principale:")
                        case .slopeGrade:
                            Text("Pendenza:")
                        case .treeHeight:
                            Text("Altezza:")
                        }
                        Spacer()
                        Text(measurement.formattedPrimaryValue)
                            .fontWeight(.medium)
                    }
                    
                    if !measurement.secondaryLabel.isEmpty {
                        HStack {
                            Text(measurement.secondaryLabel)
                            Spacer()
                            Text(measurement.formattedSecondaryValue)
                                .fontWeight(.medium)
                        }
                    }
                    
                    if measurement.mode != .treeHeight {
                        HStack {
                            Text("Valutazione:")
                            Spacer()
                            Text(measurement.statusLevel.rawValue)
                                .foregroundColor(measurement.statusLevel.color)
                                .fontWeight(.bold)
                        }
                    }
                }
                
                Section(header: Text("Note")) {
                    TextEditor(text: $editingNotes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Button("Salva note") {
                        onSave(editingNotes)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.blue)
                }
            }
            .navigationBarTitle("Dettagli Misurazione", displayMode: .inline)
            .navigationBarItems(trailing: Button("Chiudi") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
