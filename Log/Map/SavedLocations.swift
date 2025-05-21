//
//  SavedLocations.swift
//  MapLocation
//
//  Created by Raffaele Turcio on 20/05/25.
//

// SavedLocation.swift
// LocationStore.swift
// SavedLocation.swift
import Foundation
import CoreLocation

struct SavedLocation: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(id: UUID = UUID(), title: String, coordinate: CLLocationCoordinate2D, timestamp: Date) {
        self.id = id
        self.title = title
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.timestamp = timestamp
    }
    
    // Helper for formatting coordinates as a string
    func formattedCoordinates() -> String {
        return "Latitude: \(String(format: "%.6f", latitude)), Longitude: \(String(format: "%.6f", longitude))"
    }
    
    // Helper for formatting the timestamp
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    // For Equatable
    static func == (lhs: SavedLocation, rhs: SavedLocation) -> Bool {
        return lhs.id == rhs.id
    }
}

// Sample data for previews
