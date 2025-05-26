//
//  DiameterView.swift
//  VeeTA
//
//  Created by Vincenzo Salzano on 26/05/25.
//

import AVFoundation
import SwiftUI
import ARKit
import RealityKit

struct DiameterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let tree: Tree?
    
    @State private var arView = ARView(frame: .zero)
    @State private var isPlacingPoints = false
    @State private var startPoint: SIMD3<Float>?
    @State private var endPoint: SIMD3<Float>?
    @State private var measuredDiameter: Double = 0.0
    @State private var diameterNotes = ""
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
                                DiameterInstructionCard(
                                    title: "Punto di partenza",
                                    description: "Segna il punto di partenza e inizia a camminare lentamente",
                                    icon: "location.circle"
                                )
                            } else if endPoint == nil {
                                DiameterInstructionCard(
                                    title: "Punto finale",
                                    description: "Segna il punto in cui finisce di camminare ",
                                    icon: "location.circle.fill"
                                )
                            }
                            
                            if startPoint != nil && endPoint != nil {
                                DiameterResultCard(diameter: measuredDiameter) {
                                    showingResult = true
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Misura Diametro Chioma:")
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
                SaveDiameterView(
                    diameter: measuredDiameter,
                    notes: $diameterNotes,
                    tree: tree,
                    onSave: { diameter, notes in
                        saveDiameter(diameter: diameter, notes: notes)
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
                measuredDiameter = Double(distance)
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
        measuredDiameter = 0.0
        arView.scene.anchors.removeAll()
    }
    
    private func saveDiameter(diameter: Double, notes: String) {
        let treeProiection = TreeProiection(diameter: diameter, notes: notes, tree: tree)
        modelContext.insert(treeProiection)
        dismiss()
    }
}

struct DiameterInstructionCard: View {
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

struct DiameterResultCard: View {
    let diameter: Double
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "ruler")
                .font(.title)
                .foregroundColor(.green)
            
            Text("Diametro misurato")
                .font(.headline)
            
            Text(String(format: "%.2f metri", diameter))
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

struct SaveDiameterView: View {
    @Environment(\.dismiss) private var dismiss
    
    let diameter: Double
    @Binding var notes: String
    let tree: Tree?
    let onSave: (Double, String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Misurazione") {
                    HStack {
                        Text("Diametro:")
                        Spacer()
                        Text(String(format: "%.2f m", diameter))
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
                        onSave(diameter, notes)
                        dismiss()
                    }
                }
            }
        }
    }
}
