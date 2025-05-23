//
//  SavedMeasurementsView.swift
//  Log
//
//  Created by Giovanni Jr Di Fenza on 21/05/25.
//

import SwiftUI
import CoreMotion

struct SavedMeasurementsView: View {
    @Binding var measurements: [Measurement]
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedMeasurement: Measurement?
    @State private var showingDetails = false
    @State private var editingNotes = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(measurements) { measurement in
                    Button(action: {
                        selectedMeasurement = measurement
                        editingNotes = measurement.notes
                        showingDetails = true
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(measurement.treeName)
                                    .font(.headline)
                                
                                HStack {
                                    Text(measurement.mode.rawValue)
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                                
                                Text(formatDate(measurement.date))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            if measurement.mode != .treeHeight {
                                Circle()
                                    .fill(measurement.statusLevel.color)
                                    .frame(width: 20, height: 20)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: deleteMeasurement)
            }
            .navigationBarTitle("Misurazioni Salvate", displayMode: .inline)
            .navigationBarItems(
                leading: EditButton(),
                trailing: Button("Chiudi") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $showingDetails) {
                if let measurement = selectedMeasurement {
                    MeasurementDetailView(
                        measurement: measurement,
                        editingNotes: $editingNotes,
                        onSave: { notes in
                            if let index = measurements.firstIndex(where: { $0.id == measurement.id }) {
                                var updatedMeasurement = measurement
                                updatedMeasurement.notes = notes
                                measurements[index] = updatedMeasurement
                            }
                        }
                    )
                }
            }
        }
    }
    
    private func deleteMeasurement(at offsets: IndexSet) {
        measurements.remove(atOffsets: offsets)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
