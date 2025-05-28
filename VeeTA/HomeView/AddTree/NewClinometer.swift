//
//  ClinometerForNewTreeView.swift
//  VeeTA
//
//  Created by Vincenzo Salzano on 27/05/25.
//

import SwiftUI
import SwiftData
import ARKit
import RealityKit
import CoreMotion
import AVFoundation

struct ClinometerForNewTreeView: View {
    @Environment(\.dismiss) private var dismiss
    
    let treeName: String
    let treeSpecies: String
    let extraNotes: String
    let cluster: Cluster?
    let onSave: (Tree) -> Void
    
    @State private var arView = ARView(frame: .zero)
    @State private var motionManager = CMMotionManager()
    @State private var currentInclination: Double = 0.0
    @State private var isCalibrated = false
    @State private var zeroReferenceAngle: Double = 0.0
    @State private var notes = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isARSessionReady = false
    @State private var permissionDenied = false
    @State private var sessionError: String?
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    if permissionDenied {
                        // Schermata di errore per permessi negati
                        VStack(spacing: 20) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("Accesso fotocamera richiesto")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Per utilizzare la visualizzazione AR del clinometro è necessario consentire l'accesso alla fotocamera nelle impostazioni dell'app.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            Button("Apri Impostazioni") {
                                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    } else if let error = sessionError {
                        // Schermata di errore per problemi di sessione AR
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            
                            Text("Errore AR")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(error)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            Button("Riprova") {
                                resetARSession()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    } else {
                        // ARView per vedere attraverso la fotocamera
                        ARViewContainer(
                            arView: arView,
                            onTapGesture: { _ in }, // Non serve per il clinometro
                            onSessionReady: {
                                isARSessionReady = true
                            },
                            onPermissionDenied: {
                                permissionDenied = true
                            },
                            onSessionError: { error in
                                sessionError = error
                            }
                        )
                        .edgesIgnoringSafeArea(.all)
                        
                        // Overlay del clinometro
                        VStack {
                            // Header con informazioni
                            VStack(spacing: 8) {
                                Text("Clinometro Forestale")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 2)
                                
                                Text("Nuovo Albero: \(treeName)")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 1)
                            }
                            .padding(.top, 20)
                            
                            Spacer()
                            
                            if !isARSessionReady && !permissionDenied && sessionError == nil {
                                VStack(spacing: 16) {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                    Text("Inizializzazione AR...")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.black.opacity(0.7))
                                        .cornerRadius(10)
                                }
                            } else if isARSessionReady {
                                // Clinometro centrale
                                ClinometerDisplay(
                                    inclination: currentInclination,
                                    isCalibrated: isCalibrated,
                                    geometry: geometry
                                )
                            }
                            
                            Spacer()
                            
                            // Controlli inferiori
                            VStack(spacing: 16) {
                                // Display dell'inclinazione
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Inclinazione")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                        Text(String(format: "%.2f°", currentInclination))
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .shadow(color: .black.opacity(0.5), radius: 2)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Stato")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                        Text(isCalibrated ? "Calibrato" : "Non calibrato")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(isCalibrated ? .green : .orange)
                                            .shadow(color: .black.opacity(0.5), radius: 1)
                                    }
                                }
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(12)
                                
                                // Note
                                TextField("Note (opzionale)", text: $notes)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(8)
                                
                                // Pulsanti di controllo
                                HStack(spacing: 16) {
                                    Button(action: calibrateZero) {
                                        HStack {
                                            Image(systemName: "scope")
                                            Text("Calibra Zero")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                    }
                                    .disabled(!isARSessionReady)
                                    
                                    Button(action: saveMeasurementAndTree) {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                            Text("Salva Albero")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(isCalibrated && isARSessionReady ? Color.green : Color.gray)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                    }
                                    .disabled(!isCalibrated || !isARSessionReady)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear(perform: setupClinometer)
            .onDisappear(perform: stopClinometer)
            .alert("Clinometro", isPresented: $showingAlert) {
                Button("OK") {
                    if alertMessage.contains("successo") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .overlay(alignment: .topLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .padding()
            }
        }
    }
    
    private func setupClinometer() {
        checkCameraPermission()
        
        // Configura motion manager per l'inclinometro
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(to: .main) { motion, error in
                guard let motion = motion else { return }
                
                // Calcola l'inclinazione basata sulla rotazione del device
                let pitch = motion.attitude.pitch * 180 / .pi
                
                if isCalibrated {
                    currentInclination = pitch - zeroReferenceAngle
                } else {
                    currentInclination = pitch
                }
            }
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if !granted {
                        permissionDenied = true
                    }
                }
            }
        case .denied, .restricted:
            permissionDenied = true
        @unknown default:
            permissionDenied = true
        }
    }
    
    private func resetARSession() {
        sessionError = nil
        isARSessionReady = false
        arView.session.pause()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let config = ARWorldTrackingConfiguration()
            if ARWorldTrackingConfiguration.isSupported {
                config.planeDetection = [.horizontal, .vertical]
                arView.session.run(config, options: [.resetTracking, .resetSceneReconstruction])
            } else {
                sessionError = "AR non supportato su questo dispositivo"
            }
        }
    }
    
    private func stopClinometer() {
        motionManager.stopDeviceMotionUpdates()
        arView.session.pause()
    }
    
    private func calibrateZero() {
        zeroReferenceAngle = currentInclination
        isCalibrated = true
        currentInclination = 0.0
        
        alertMessage = "Calibrazione completata! Il punto attuale è ora impostato come riferimento zero."
        showingAlert = true
    }
    
    private func saveMeasurementAndTree() {
        // Crea il nuovo albero
        let newTree = Tree(
            name: treeName,
            species: treeSpecies,
            extraNotes: extraNotes,
            cluster: cluster
        )
        
        // Crea la misurazione dell'inclinazione
        let measurement = Clinometer(
            inclination: currentInclination,
            notes: notes,
            tree: newTree
        )
        
        // Aggiungi la misurazione all'albero
        newTree.clinometer.append(measurement)
        
        // Salva tramite callback
        onSave(newTree)
        
        alertMessage = "Albero e misurazione dell'inclinazione salvati con successo!"
        showingAlert = true
    }
}
