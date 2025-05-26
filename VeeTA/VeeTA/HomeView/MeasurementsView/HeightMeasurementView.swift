//
//  HeightMeasurementView.swift
//  SwiftDataLog
//
//  Created by Vincenzo Salzano on 24/05/25.
//

import AVFoundation
import SwiftUI
import ARKit
import RealityKit

struct HeightMeasurementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let tree: Tree?
    
    @State private var arView = ARView(frame: .zero)
    @State private var isPlacingPoints = false
    @State private var startPoint: SIMD3<Float>?
    @State private var endPoint: SIMD3<Float>?
    @State private var measuredHeight: Double = 0.0
    @State private var measurementNotes = ""
    @State private var showingResult = false
    @State private var isARSessionReady = false
    @State private var showingPermissionAlert = false
    @State private var permissionDenied = false
    @State private var sessionError: String?
    
    var body: some View {
        NavigationView {
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
                        
                        Text("Per utilizzare la misurazione AR è necessario consentire l'accesso alla fotocamera nelle impostazioni dell'app.")
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
                    ARViewContainer(
                        arView: arView,
                        onTapGesture: handleTapGesture,
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
                    .ignoresSafeArea()
                    
                    VStack {
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
                            if startPoint == nil {
                                InstructionCard(
                                    title: "Punto di partenza",
                                    description: "Tocca la base dell'albero per iniziare la misurazione",
                                    icon: "location.circle"
                                )
                            } else if endPoint == nil {
                                InstructionCard(
                                    title: "Punto finale",
                                    description: "Tocca la cima dell'albero per completare la misurazione",
                                    icon: "location.circle.fill"
                                )
                            }
                            
                            if startPoint != nil && endPoint != nil {
                                ResultCard(height: measuredHeight) {
                                    showingResult = true
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Misura Altezza")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        resetMeasurement()
                    }
                    .disabled(startPoint == nil || !isARSessionReady)
                }
            }
            .sheet(isPresented: $showingResult) {
                SaveMeasurementView(
                    height: measuredHeight,
                    notes: $measurementNotes,
                    tree: tree,
                    onSave: { height, notes in
                        saveMeasurement(height: height, notes: notes)
                    }
                )
            }
        }
        .onAppear {
            checkCameraPermission()
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Permesso già concesso
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
                // Correzione: usa .resetSceneReconstruction invece di .removeAllAnchors
                arView.session.run(config, options: [.resetTracking, .resetSceneReconstruction])
            } else {
                sessionError = "AR non supportato su questo dispositivo"
            }
        }
    }
    
    private func handleTapGesture(at location: CGPoint) {
        guard isARSessionReady && !permissionDenied && sessionError == nil else { return }
        
        let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any)
        
        guard let result = results.first else {
            // Prova con un raycast più permissivo se il primo fallisce
            let results2 = arView.raycast(from: location, allowing: .existingPlaneGeometry, alignment: .any)
            guard let result2 = results2.first else { return }
            processRaycastResult(result2)
            return
        }
        
        processRaycastResult(result)
    }
    
    private func processRaycastResult(_ result: ARRaycastResult) {
        let position = result.worldTransform.columns.3
        let point = SIMD3<Float>(position.x, position.y, position.z)
        
        if startPoint == nil {
            startPoint = point
            addSphere(at: point, color: .green)
        } else if endPoint == nil {
            endPoint = point
            addSphere(at: point, color: .red)
            
            if let start = startPoint, let end = endPoint {
                let distance = distance(start, end)
                measuredHeight = Double(distance)
                addLine(from: start, to: end)
            }
        }
    }
    
    private func addSphere(at position: SIMD3<Float>, color: UIColor) {
        let sphere = MeshResource.generateSphere(radius: 0.02)
        let material = SimpleMaterial(color: color, isMetallic: false)
        let entity = ModelEntity(mesh: sphere, materials: [material])
        
        let anchor = AnchorEntity(world: position)
        anchor.addChild(entity)
        arView.scene.addAnchor(anchor)
    }
    
    private func addLine(from start: SIMD3<Float>, to end: SIMD3<Float>) {
        let distance = distance(start, end)
        let midPoint = (start + end) / 2
        
        let cylinder = MeshResource.generateCylinder(height: distance, radius: 0.002)
        let material = SimpleMaterial(color: .yellow, isMetallic: false)
        let entity = ModelEntity(mesh: cylinder, materials: [material])
        
        // Calcola la rotazione per allineare il cilindro tra i due punti
        let direction = normalize(end - start)
        let up = SIMD3<Float>(0, 1, 0)
        let right = normalize(cross(direction, up))
        let realUp = cross(right, direction)
        
        let rotationMatrix = float3x3(right, realUp, -direction)
        entity.transform.rotation = simd_quatf(rotationMatrix)
        
        let anchor = AnchorEntity(world: midPoint)
        anchor.addChild(entity)
        arView.scene.addAnchor(anchor)
    }
    
    private func resetMeasurement() {
        startPoint = nil
        endPoint = nil
        measuredHeight = 0.0
        arView.scene.anchors.removeAll()
    }
    
    private func saveMeasurement(height: Double, notes: String) {
        let measurement = Measurement(height: height, notes: notes, tree: tree)
        modelContext.insert(measurement)
        dismiss()
    }
}

struct InstructionCard: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

struct ResultCard: View {
    let height: Double
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "ruler")
                .font(.title)
                .foregroundColor(.green)
            
            Text("Altezza misurata")
                .font(.headline)
            
            Text(String(format: "%.2f metri", height))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Button("Salva Misurazione") {
                onSave()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

struct SaveMeasurementView: View {
    @Environment(\.dismiss) private var dismiss
    
    let height: Double
    @Binding var notes: String
    let tree: Tree?
    let onSave: (Double, String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Misurazione") {
                    HStack {
                        Text("Altezza:")
                        Spacer()
                        Text(String(format: "%.2f m", height))
                            .fontWeight(.semibold)
                    }
                    
                    if let tree = tree {
                        HStack {
                            Text("Albero:")
                            Spacer()
                            Text(tree.name)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Note") {
                    TextField("Note aggiuntive (opzionale)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Salva Misurazione")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salva") {
                        onSave(height, notes)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    let arView: ARView
    let onTapGesture: (CGPoint) -> Void
    let onSessionReady: () -> Void
    let onPermissionDenied: () -> Void
    let onSessionError: (String) -> Void
    
    func makeUIView(context: Context) -> ARView {
        // Controlla se AR è supportato
        guard ARWorldTrackingConfiguration.isSupported else {
            DispatchQueue.main.async {
                onSessionError("AR non supportato su questo dispositivo")
            }
            return arView
        }
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        
        // Aggiungi gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        // Delega per monitorare lo stato della sessione
        arView.session.delegate = context.coordinator
        
        // Avvia la sessione AR
        arView.session.run(config)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Aggiornamenti se necessari
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            onTapGesture: onTapGesture,
            onSessionReady: onSessionReady,
            onPermissionDenied: onPermissionDenied,
            onSessionError: onSessionError
        )
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        let onTapGesture: (CGPoint) -> Void
        let onSessionReady: () -> Void
        let onPermissionDenied: () -> Void
        let onSessionError: (String) -> Void
        private var sessionReady = false
        
        init(onTapGesture: @escaping (CGPoint) -> Void,
             onSessionReady: @escaping () -> Void,
             onPermissionDenied: @escaping () -> Void,
             onSessionError: @escaping (String) -> Void) {
            self.onTapGesture = onTapGesture
            self.onSessionReady = onSessionReady
            self.onPermissionDenied = onPermissionDenied
            self.onSessionError = onSessionError
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: gesture.view)
            onTapGesture(location)
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            if !sessionReady && frame.camera.trackingState == .normal {
                sessionReady = true
                DispatchQueue.main.async {
                    self.onSessionReady()
                }
            }
        }
        
        func session(_ session: ARSession, didFailWithError error: Error) {
            DispatchQueue.main.async {
                if let arError = error as? ARError {
                    switch arError.errorCode {
                    case 102: // Camera access denied
                        self.onPermissionDenied()
                    default:
                        self.onSessionError("Errore AR: \(arError.localizedDescription)")
                    }
                } else {
                    self.onSessionError("Errore sconosciuto: \(error.localizedDescription)")
                }
            }
        }
        
        func sessionWasInterrupted(_ session: ARSession) {
            DispatchQueue.main.async {
                self.onSessionError("Sessione AR interrotta")
            }
        }
    }
}
