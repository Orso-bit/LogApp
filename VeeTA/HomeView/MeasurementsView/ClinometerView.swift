//
//  ClinometerView.swift
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

struct ClinometerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let tree: Tree
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
                                
                                Text("Albero: \(tree.name)")
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
                                    
                                    Button(action: saveMeasurement) {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                            Text("Salva")
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
                Button("OK") { }
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
    
    private func saveMeasurement() {
        let measurement = Clinometer(
            inclination: currentInclination,
            notes: notes,
            tree: tree
        )
        
        modelContext.insert(measurement)
        
        do {
            try modelContext.save()
            alertMessage = "Misurazione salvata con successo!"
            showingAlert = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } catch {
            alertMessage = "Errore nel salvare la misurazione: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

// Display del clinometro con visualizzazione grafica
struct ClinometerDisplay: View {
    let inclination: Double
    let isCalibrated: Bool
    let geometry: GeometryProxy
    
    private var displaySize: CGFloat {
        min(geometry.size.width, geometry.size.height) * 0.4
    }
    
    var body: some View {
        ZStack {
            // Cerchio esterno
            Circle()
                .stroke(Color.white, lineWidth: 3)
                .frame(width: displaySize, height: displaySize)
                .shadow(color: .black.opacity(0.5), radius: 3)
            
            // Marcatori di grado
            ForEach(Array(stride(from: -90, through: 90, by: 15)), id: \.self) { angle in
                DegreeMarker(angle: Double(angle), radius: displaySize/2, isMainMarker: angle % 30 == 0)
            }
            
            // Linea di livello (orizzontale)
            Rectangle()
                .fill(Color.green)
                .frame(width: displaySize * 0.8, height: 2)
                .shadow(color: .black.opacity(0.5), radius: 1)
            
            // Indicatore dell'inclinazione
            InclinationIndicator(
                inclination: inclination,
                radius: displaySize/2 - 20,
                isCalibrated: isCalibrated
            )
            
            // Centro del clinometro
            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
                .shadow(color: .black.opacity(0.5), radius: 1)
            
            // Bolla di livello virtuale
            BubbleLevel(inclination: inclination, size: displaySize * 0.15)
                .offset(y: displaySize/2 + 40)
        }
    }
}

// Marcatori dei gradi
struct DegreeMarker: View {
    let angle: Double
    let radius: CGFloat
    let isMainMarker: Bool
    
    var body: some View {
        let radians = angle * .pi / 180
        let x = cos(radians + .pi/2) * (radius - (isMainMarker ? 15 : 10))
        let y = sin(radians + .pi/2) * (radius - (isMainMarker ? 15 : 10))
        
        Group {
            Rectangle()
                .fill(Color.white)
                .frame(width: 2, height: isMainMarker ? 15 : 8)
                .offset(x: x, y: y)
                .rotationEffect(.degrees(angle))
            
            if isMainMarker {
                Text("\(Int(angle))°")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.7), radius: 1)
                    .offset(x: cos(radians + .pi/2) * (radius - 25),
                           y: sin(radians + .pi/2) * (radius - 25))
            }
        }
    }
}

// Indicatore dell'inclinazione
struct InclinationIndicator: View {
    let inclination: Double
    let radius: CGFloat
    let isCalibrated: Bool
    
    var body: some View {
        let clampedInclination = max(-90, min(90, inclination))
        let radians = clampedInclination * .pi / 180
        let x = cos(radians + .pi/2) * radius
        let y = sin(radians + .pi/2) * radius
        
        ZStack {
            // Linea dell'indicatore
            Rectangle()
                .fill(isCalibrated ? Color.red : Color.orange)
                .frame(width: 3, height: radius)
                .offset(y: -radius/2)
                .rotationEffect(.degrees(clampedInclination))
                .shadow(color: .black.opacity(0.5), radius: 2)
            
            // Punta dell'indicatore
            Circle()
                .fill(isCalibrated ? Color.red : Color.orange)
                .frame(width: 12, height: 12)
                .offset(x: x, y: y)
                .shadow(color: .black.opacity(0.5), radius: 2)
        }
    }
}

// Bolla di livello virtuale
struct BubbleLevel: View {
    let inclination: Double
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Container della bolla
            Capsule()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: size * 2, height: size * 0.4)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.3))
                )
            
            // Bolla
            Circle()
                .fill(inclination.magnitude < 2 ? Color.green : Color.red)
                .frame(width: size * 0.3, height: size * 0.3)
                .offset(x: max(-size * 0.7, min(size * 0.7, CGFloat(inclination) * 8)))
                .shadow(color: .black.opacity(0.5), radius: 2)
                .animation(.easeInOut(duration: 0.2), value: inclination)
        }
    }
}
