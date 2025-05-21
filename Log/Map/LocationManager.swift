//
//  LocationManager.swift
//  MapLocation
//
//  Created by Raffaele Turcio on 20/05/25.
//

// LocationManager.swift
import Foundation
import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var locationAccuracy: CLLocationAccuracy = 0
    @Published var lastUpdateTime: Date?
    @Published var isUpdating = false
    
    // Callback for location updates
    var onLocationUpdate: ((CLLocation) -> Void)?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
        manager.distanceFilter = 5 // Update location when user moves 5 meters
    }
    
    func startUpdatingLocation() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        isUpdating = true
    }
    
    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
        isUpdating = false
    }
    
    func requestHighAccuracy() {
        // Temporarily request higher accuracy
        let originalAccuracy = manager.desiredAccuracy
        let originalDistanceFilter = manager.distanceFilter
        
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 1
        
        // After 10 seconds, return to normal settings
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.manager.desiredAccuracy = originalAccuracy
            self.manager.distanceFilter = originalDistanceFilter
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Only update if the location is recent and accurate enough
        let howRecent = location.timestamp.timeIntervalSinceNow
        guard abs(howRecent) < 10 && location.horizontalAccuracy < 100 else { return }
        
        self.location = location
        self.locationAccuracy = location.horizontalAccuracy
        self.lastUpdateTime = location.timestamp
        onLocationUpdate?(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Filter out temporary errors
        if let clError = error as? CLError, clError.code == .locationUnknown {
            return
        }
        print("Location manager error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            // Handle denied access
            print("Location access denied")
            
            // Show an alert to guide the user to settings
            showLocationPermissionAlert()
        case .notDetermined:
            // Request authorization
            manager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
    
    private func showLocationPermissionAlert() {
        let alert = UIAlertController(
            title: "Location Access Required",
            message: "This app needs access to your location to function properly. Please enable location permissions in Settings.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        // Get the key window to present the alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
}
