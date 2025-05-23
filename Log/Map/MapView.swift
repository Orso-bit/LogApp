//
//  MapView.swift
//  Log
//
//  Created by Giovanni Jr Di Fenza on 21/05/25.
//

import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject private var locationStore: LocationStore
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 55.35673780, longitude: -122.03121860),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var coordinatesText = "Current location will be shown here"
    @State private var isTrackingUser = true
    @State private var showingPinList = false
    @State private var isAddingPin = false
    @State private var tapLocation: CLLocationCoordinate2D?
    @State private var showingUserLocationAccuracy = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Map container with controls
            mapContainer
            
            // Bottom info panel
            VStack(spacing: 15) {
                HStack {
                    Button(action: { isAddingPin.toggle() }) {
                        Label(isAddingPin ? "Cancel Pin" : "Add Pin", systemImage: isAddingPin ? "xmark.circle" : "mappin.and.ellipse")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                            .background(isAddingPin ? Color.orange : Color.blue)
                            .cornerRadius(10)
                    }
                    
                    Button(action: { showingPinList = true }) {
                        Label("Saved Pins", systemImage: "list.bullet")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                Text(coordinatesText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .font(.system(size: 14))
                
                if showingUserLocationAccuracy, let location = locationManager.location {
                    Text("Accuracy: \(String(format: "%.1f", location.horizontalAccuracy)) meters")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .onTapGesture {
                            showingUserLocationAccuracy.toggle()
                        }
                }
            }
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(radius: 3)
            )
            .padding([.horizontal, .bottom])
        }
        .ignoresSafeArea(edges: .top)
        .onAppear {
            locationManager.onLocationUpdate = { location in
                updateLocationText(location)
                if isTrackingUser {
                    withAnimation {
                        region = MKCoordinateRegion(
                            center: location.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    }
                }
            }
            locationManager.startUpdatingLocation()
        }
        .sheet(isPresented: $showingPinList) {
            SavedPinsView()
                .environmentObject(locationStore)
        }
    }
    
    // MARK: - UI Components
    
    private var mapContainer: some View {
        ZStack(alignment: .topTrailing) {
            Map(coordinateRegion: $region, showsUserLocation: true,
                annotationItems: locationStore.savedLocations) { pin in
                MapAnnotation(coordinate: pin.coordinate) {
                    VStack {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title)
                            .foregroundColor(.red)
                        
                        Text(pin.title)
                            .font(.caption)
                            .padding(5)
                            .background(Color.white.opacity(0.7))
                            .cornerRadius(5)
                    }
                    .onTapGesture {
                        withAnimation {
                            region = MKCoordinateRegion(
                                center: pin.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )
                        }
                    }
                }
            }
            .onTapGesture { location in
                isTrackingUser = false
                
                if isAddingPin {
                    // Convert tap to map coordinate
                    let tapPoint = location
                    
                    // Get the size of the map view
                    guard let window = UIApplication.shared.windows.first else { return }
                    let mapFrame = window.frame
                    
                    // Calculate the tap location as a percentage of the map view
                    let tapX = tapPoint.x / mapFrame.width
                    let tapY = tapPoint.y / mapFrame.height
                    
                    // Interpolate to get the map coordinate
                    let span = region.span
                    let centerLat = region.center.latitude
                    let centerLon = region.center.longitude
                    
                    let latDelta = span.latitudeDelta * (tapY - 0.5) * -1
                    let lonDelta = span.longitudeDelta * (tapX - 0.5)
                    
                    tapLocation = CLLocationCoordinate2D(
                        latitude: centerLat + latDelta,
                        longitude: centerLon + lonDelta
                    )
                    
                    // Show custom UIAlertController with text field
                    let alertController = UIAlertController(
                        title: "Save Location",
                        message: "Enter a name for this location",
                        preferredStyle: .alert
                    )
                    
                    alertController.addTextField { textField in
                        textField.placeholder = "Location name"
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "MMM d, h:mm a"
                        textField.text = "Location on \(dateFormatter.string(from: Date()))"
                    }
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                        tapLocation = nil
                        isAddingPin = false
                    }
                    
                    let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
                        guard let coordinate = tapLocation else { return }
                        
                        if let name = alertController.textFields?.first?.text, !name.isEmpty {
                            // Save the location with the given name
                            let newLocation = SavedLocation(
                                title: name,
                                coordinate: coordinate,
                                timestamp: Date()
                            )
                            locationStore.addLocation(newLocation)
                            
                            // Update UI
                            coordinatesText = "Pin Saved: \(name)\n" + formatCoordinates(coordinate)
                            
                            // Reset state
                            tapLocation = nil
                            isAddingPin = false
                        }
                    }
                    
                    alertController.addAction(cancelAction)
                    alertController.addAction(saveAction)
                    
                    // Present the alert controller
                    UIApplication.shared.windows.first?.rootViewController?.present(alertController, animated: true)
                }
            }
            
            VStack {
                Button(action: centerOnUserLocation) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                        .padding(10)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                
              
                
            }
            .padding()
        }
    }
    
    // MARK: - Functions
    
    private func saveCustomPin() {
        guard let coordinate = tapLocation else { return }
        
        // Create dialog to name the location
        let alert = UIAlertController(title: "Save Location", message: "Enter a name for this location", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Location name"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, h:mm a"
            textField.text = "Location on \(dateFormatter.string(from: Date()))"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            tapLocation = nil
            isAddingPin = false
        })
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            if let name = alert.textFields?.first?.text, !name.isEmpty {
                // Save the location with the given name
                let newLocation = SavedLocation(
                    title: name,
                    coordinate: coordinate,
                    timestamp: Date()
                )
                locationStore.addLocation(newLocation)
                
                // Update UI
                coordinatesText = "Pin Saved: \(name)\n" + formatCoordinates(coordinate)
                
                // Reset state
                tapLocation = nil
                isAddingPin = false
            }
        })
        
        // Present the alert
        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
    }
    
    private func centerOnUserLocation() {
        if let location = locationManager.location {
            withAnimation {
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
            isTrackingUser = true
        }
    }
    
    private func markMyLocation() {
        guard let location = locationManager.location else { return }
        
        // Create dialog to name the location
        let alert = UIAlertController(title: "Save Location", message: "Enter a name for this location", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Location name"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, h:mm a"
            textField.text = "Location on \(dateFormatter.string(from: Date()))"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            if let name = alert.textFields?.first?.text, !name.isEmpty {
                // Save the location with the given name
                let newLocation = SavedLocation(
                    title: name,
                    coordinate: location.coordinate,
                    timestamp: Date()
                )
                locationStore.addLocation(newLocation)
                
                // Update UI
                coordinatesText = "Pin Saved: \(name)\n" + formatCoordinates(location.coordinate)
            }
        })
        
        // Present the alert
        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
    }
    
    private func updateLocationText(_ location: CLLocation) {
        coordinatesText = "Current Location:\n" + formatCoordinates(location.coordinate)
    }
    
    private func formatCoordinates(_ coordinate: CLLocationCoordinate2D) -> String {
        return "Latitude: \(String(format: "%.6f", coordinate.latitude))\nLongitude: \(String(format: "%.6f", coordinate.longitude))"
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(LocationStore())
    }
}
