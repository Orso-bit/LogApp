//
//  SavedPinsView.swift
//  MapLocation
//
//  Created by Raffaele Turcio on 20/05/25.
//

// SavedPinsView.swift
import SwiftUI
import MapKit

struct SavedPinsView: View {
    @EnvironmentObject private var locationStore: LocationStore
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedPin: SavedLocation?
    @State private var showDeleteConfirmation = false
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    
    var body: some View {
        NavigationView {
            VStack {
                if locationStore.savedLocations.isEmpty {
                    emptyStateView
                } else {
                    locationsList
                }
            }
            .navigationTitle("Saved Locations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            // Prepare the export
                            exportURL = locationStore.exportLocations()
                            if exportURL != nil {
                                showExportSheet = true
                            }
                        }) {
                            Label("Export Locations", systemImage: "square.and.arrow.up")
                        }
                        
                        // Import would typically use a document picker, which is complex for this example
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showExportSheet, onDismiss: {
                exportURL = nil
            }) {
                if let url = exportURL {
                    ActivityView(activityItems: [url])
                }
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Location"),
                    message: Text("Are you sure you want to delete this saved location?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let pin = selectedPin {
                            locationStore.removeLocation(withID: pin.id)
                            selectedPin = nil
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 70))
                .foregroundColor(.gray)
            
            Text("No Saved Locations")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Locations you save will appear here")
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var locationsList: some View {
        List {
            ForEach(locationStore.savedLocations.sorted(by: { $0.timestamp > $1.timestamp })) { location in
                locationCell(for: location)
            }
            .onDelete { indexSet in
                locationStore.removeLocation(at: indexSet)
            }
        }
    }
    
    private func locationCell(for location: SavedLocation) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 36))
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(location.title)
                    .font(.headline)
                
                Text(location.formattedCoordinates())
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(location.formattedDate())
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                selectedPin = location
                showDeleteConfirmation = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

// Activity view for sharing files
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview
