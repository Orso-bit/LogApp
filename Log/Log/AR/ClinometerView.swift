//
//  Project.swift
//  Log
//
//  Created by Giovanni Jr Di Fenza on 21/05/25.
//

import SwiftUI
import CoreMotion

struct ClinometerView: View {
    @StateObject private var motionManager = MotionManager()
    @State private var savedMeasurements: [Measurement] = []
    @State private var showingSavedList = false
    @State private var treeName = ""
    @State private var showingNamePrompt = false
    @State private var activeAxis: MeasurementAxis = .longitudinal
    @State private var isCalibrating = false
    @State private var calibrationOffset: (pitch: Double, roll: Double) = (0, 0)
    @State private var measurementMode: MeasurementMode = .treeLean
    @State private var distanceToTree: Double = 20.0 // Meters
    
    var body: some View {
        NavigationView {
            VStack {
                // App title
                Text("Clinometro Forestale Pro")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Measurement mode selector
                Picker("Modalità di misurazione", selection: $measurementMode) {
                    ForEach(MeasurementMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Description of selected mode
                Text(measurementMode.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 5)
                
                // Axis selector (only shown for tree lean mode)
                if measurementMode == .treeLean {
                    Picker("Asse di Misurazione", selection: $activeAxis) {
                        ForEach(MeasurementAxis.allCases) { axis in
                            Text(axis.rawValue).tag(axis)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                }
                
                // Distance slider (only for tree height mode)
                if measurementMode == .treeHeight {
                    HStack {
                        Text("Distanza: \(Int(distanceToTree)) m")
                        Slider(value: $distanceToTree, in: 5...100, step: 1)
                    }
                    .padding()
                }
                
                // Inclinometer visualization
                InclinometerView(
                    angle: getRelevantAngle(),
                    axisLabel: getAxisLabel(),
                    mode: measurementMode
                )
                .frame(height: 300)
                .padding()
                
                // Measurement readout
                VStack(spacing: 15) {
                    switch measurementMode {
                    case .treeLean:
                        treeLeanReadout()
                    case .slopeGrade:
                        slopeGradeReadout()
                    case .treeHeight:
                        treeHeightReadout()
                    }
                }
                .padding()
                
                // Calibration button
                Button(action: toggleCalibration) {
                    HStack {
                        Image(systemName: isCalibrating ? "checkmark.circle.fill" : "scope")
                        Text(isCalibrating ? "Termina Calibrazione" : "Calibra Sensore")
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(isCalibrating ? Color.green : Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.bottom)
                
                Spacer()
                
                // Save and view measurements buttons
                HStack {
                    Button(action: { showingNamePrompt = true }) {
                        Text("Salva Misurazione")
                            .font(.headline)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Spacer()
                    
                    Button(action: { showingSavedList = true }) {
                        Text("Misurazioni Salvate")
                            .font(.headline)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            .padding()
            .sheet(isPresented: $showingSavedList) {
                SavedMeasurementsView(measurements: $savedMeasurements)
            }
            .alert("Nome dell'albero", isPresented: $showingNamePrompt) {
                TextField("Inserisci il nome dell'albero", text: $treeName)
                Button("Annulla", role: .cancel) {}
                Button("Salva") {
                    saveMeasurement()
                }
            } message: {
                Text("Inserisci un nome per identificare l'albero misurato")
            }
            .navigationBarTitle("", displayMode: .inline)
            .onAppear {
                motionManager.startUpdating()
            }
            .onDisappear {
                motionManager.stopUpdating()
            }
        }
    }
    
    // Tree lean readout
    private func treeLeanReadout() -> some View {
        return VStack {
            HStack {
                Text("\(activeAxis.rawValue):")
                    .font(.title)
                Text(String(format: "%.1f°", getRelevantAngle()))
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            // Display other axis measurement
            HStack {
                Text(activeAxis == .longitudinal ? "Laterale:" : "Longitudinale:")
                    .font(.subheadline)
                Text(String(format: "%.1f°", getOtherAxisAngle()))
                    .font(.subheadline)
            }
            
            // Stability assessment
            Text(treeLeanAssessment(angle: getRelevantAngle()))
                .font(.headline)
                .foregroundColor(treeLeanColor(angle: getRelevantAngle()))
                .padding(.top, 5)
        }
    }
    
    // Slope grade readout
    private func slopeGradeReadout() -> some View {
        let angle = getRelevantAngle()
        let percentGrade = tan(angle * .pi / 180.0) * 100.0
        
        return VStack {
            HStack {
                Text("Angolo:")
                    .font(.title)
                Text(String(format: "%.1f°", angle))
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            HStack {
                Text("Pendenza:")
                    .font(.title2)
                Text(String(format: "%.1f%%", percentGrade))
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            // Slope difficulty assessment
            Text(slopeAssessment(percentGrade: percentGrade))
                .font(.headline)
                .foregroundColor(slopeColor(percentGrade: percentGrade))
                .padding(.top, 5)
        }
    }
    
    // Tree height readout
    private func treeHeightReadout() -> some View {
        let angle = abs(getRelevantAngle())
        let height = calculateTreeHeight(angle: angle, distance: distanceToTree)
        
        return VStack {
            HStack {
                Text("Angolo:")
                    .font(.title2)
                Text(String(format: "%.1f°", angle))
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            HStack {
                Text("Altezza stimata:")
                    .font(.title)
                Text(String(format: "%.1f m", height))
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            Text("Punta il dispositivo verso la cima dell'albero")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 5)
        }
    }
    
    // Toggle calibration state
    private func toggleCalibration() {
        if isCalibrating {
            isCalibrating = false
        } else {
            calibrationOffset = (motionManager.pitch, motionManager.roll)
            isCalibrating = true
        }
    }
    
    // Save the current measurement
    private func saveMeasurement() {
        let newMeasurement = Measurement(
            treeName: treeName.isEmpty ? "Misura senza nome" : treeName,
            mode: measurementMode,
            primaryAngle: getRelevantAngle(),
            secondaryAngle: getOtherAxisAngle(),
            distance: measurementMode == .treeHeight ? distanceToTree : nil,
            estimatedHeight: measurementMode == .treeHeight ? calculateTreeHeight(angle: abs(getRelevantAngle()), distance: distanceToTree) : nil,
            date: Date(),
            notes: ""
        )
        savedMeasurements.append(newMeasurement)
        treeName = ""
    }
    
    // Get the relevant angle based on current mode and axis
    private func getRelevantAngle() -> Double {
        switch measurementMode {
        case .treeLean:
            // Deviation from vertical (90°)
            let rawAngle = activeAxis == .longitudinal ?
                motionManager.pitch - calibrationOffset.pitch :
                motionManager.roll - calibrationOffset.roll
            
            // Calculate deviation from vertical (90°)
            return 90.0 - rawAngle
        case .slopeGrade:
            // Slope is measured using the pitch (longitudinal) angle
            return motionManager.pitch - calibrationOffset.pitch
        case .treeHeight:
            // Use pitch angle for tree height measurement
            return motionManager.pitch - calibrationOffset.pitch
        }
    }
    
    // Get the secondary angle (for tree lean only)
    private func getOtherAxisAngle() -> Double {
        if measurementMode == .treeLean {
            let rawAngle = activeAxis == .longitudinal ?
                motionManager.roll - calibrationOffset.roll :
                motionManager.pitch - calibrationOffset.pitch
            
            return 90.0 - rawAngle
        }
        return 0
    }
    
    // Calculate tree height based on angle and distance
    private func calculateTreeHeight(angle: Double, distance: Double) -> Double {
        // tan(angle) = opposite/adjacent
        // height = distance * tan(angle)
        return distance * tan(angle * .pi / 180.0)
    }
    
    // Get the appropriate axis label
    private func getAxisLabel() -> String {
        switch measurementMode {
        case .treeLean:
            return activeAxis.rawValue
        case .slopeGrade:
            return "Pendenza"
        case .treeHeight:
            return "Elevazione"
        }
    }
    
    // Tree lean assessment text
    private func treeLeanAssessment(angle: Double) -> String {
        let absAngle = abs(angle)
        if absAngle < 1.5 {
            return "Perfettamente verticale"
        } else if absAngle < 5 {
            return "Inclinazione minima"
        } else if absAngle < 10 {
            return "Inclinazione moderata"
        } else if absAngle < 15 {
            return "Inclinazione significativa"
        } else {
            return "Grave inclinazione"
        }
    }
    
    // Tree lean color indicator
    private func treeLeanColor(angle: Double) -> Color {
        let absAngle = abs(angle)
        if absAngle < 1.5 {
            return .green
        } else if absAngle < 5 {
            return .green.opacity(0.7)
        } else if absAngle < 10 {
            return .yellow
        } else if absAngle < 15 {
            return .orange
        } else {
            return .red
        }
    }
    
    // Slope assessment text
    private func slopeAssessment(percentGrade: Double) -> String {
        let absGrade = abs(percentGrade)
        if absGrade < 5 {
            return "Terreno pianeggiante"
        } else if absGrade < 10 {
            return "Pendenza leggera"
        } else if absGrade < 20 {
            return "Pendenza moderata"
        } else if absGrade < 30 {
            return "Pendenza forte"
        } else {
            return "Pendenza molto ripida"
        }
    }
    
    // Slope color indicator
    private func slopeColor(percentGrade: Double) -> Color {
        let absGrade = abs(percentGrade)
        if absGrade < 5 {
            return .green
        } else if absGrade < 10 {
            return .green.opacity(0.7)
        } else if absGrade < 20 {
            return .yellow
        } else if absGrade < 30 {
            return .orange
        } else {
            return .red
        }
    }
}
