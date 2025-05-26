//
//  NewWeight.swift
//  SwiftDataLog
//
//  Created by Vincenzo Salzano on 25/05/25.
//

import SwiftData
import AVFoundation
import SwiftUI
import ARKit
import RealityKit

// Nuova view specifica per la misurazione durante la creazione di un nuovo albero
struct LengthMeasurementForNewTreeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let treeName: String
    let treeSpecies: String
    let extraNotes: String
    let cluster: Cluster?
    let onSave: (Tree) -> Void

    @State private var arView = ARView(frame: .zero)
    @State private var startPoint: SIMD3<Float>?
    @State private var endPoint: SIMD3<Float>?
    @State private var measuredLength: Double = 0.0
    @State private var lengthmeasurementNotes = ""
    @State private var showingResult = false
    @State private var isARSessionReady = false
    @State private var showingPermissionAlert = false
    @State private var permissionDenied = false
    @State private var sessionError: String?

    var body: some View {
        NavigationView {
            ZStack {
                if permissionDenied {
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
                                    description: "Tocca un estremo del tronco per iniziare la misurazione",
                                    icon: "location.circle"
                                )
                            } else if endPoint == nil {
                                InstructionCard(
                                    title: "Punto finale",
                                    description: "Tocca l'estremo opposto per completare la misurazione",
                                    icon: "location.circle.fill"
                                )
                            }

                            if startPoint != nil && endPoint != nil {
                                ResultCard(height: measuredLength) {
                                    showingResult = true
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Misura Larghezza")
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
                SaveNewTreeLengthMeasurementView(
                    length: measuredLength,
                    notes: $lengthmeasurementNotes,
                    treeName: treeName,
                    treeSpecies: treeSpecies,
                    onSave: { length, notes in
                        saveTreeWithMeasurement(length: length, notes: notes)
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

    private func handleTapGesture(at location: CGPoint) {
        guard isARSessionReady && !permissionDenied && sessionError == nil else { return }

        let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any)

        guard let result = results.first else {
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
                measuredLength = Double(distance)
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

        // Crea un cilindro più visibile per la linea
        let cylinder = MeshResource.generateCylinder(height: distance, radius: 0.005)
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
        measuredLength = 0.0
        arView.scene.anchors.removeAll()
    }

    private func saveTreeWithMeasurement(length: Double, notes: String) {
        // Crea il nuovo albero
        let newTree = Tree(
            name: treeName,
            species: treeSpecies,
            extraNotes: extraNotes,
            cluster: cluster
        )

        // Crea la misurazione
        let lengthMeasurement = LengthMeasurement(length: length, notes: notes, tree: newTree)

        // Aggiungi la misurazione all'albero
        newTree.lengthMeasurements.append(lengthMeasurement)

        // Chiama il callback per salvare
        onSave(newTree)
        dismiss()
    }
}

struct SaveNewTreeLengthMeasurementView: View {
    @Environment(\.dismiss) private var dismiss

    let length: Double
    @Binding var notes: String
    let treeName: String
    let treeSpecies: String
    let onSave: (Double, String) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section("Nuovo Albero") {
                    HStack {
                        Text("Nome:")
                        Spacer()
                        Text(treeName)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Specie:")
                        Spacer()
                        Text(treeSpecies)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Misurazione") {
                    HStack {
                        Text("Larghezza:")
                        Spacer()
                        Text(String(format: "%.2f m", length))
                            .fontWeight(.semibold)
                    }
                }

                Section("Note") {
                    TextField("Note aggiuntive (opzionale)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Salva Albero")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salva") {
                        onSave(length, notes)
                        dismiss()
                    }
                }
            }
        }
    }
}
