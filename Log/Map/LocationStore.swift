//
//  LocationStore.swift
//  MapLocation
//
//  Created by Raffaele Turcio on 20/05/25.
//

// SavedLocation.swift
// LocationStore.swift
import Foundation
import SwiftUI
import CoreLocation

class LocationStore: ObservableObject {
    @Published var savedLocations: [SavedLocation] = []
    
    private let saveKey = "SavedLocations"
    
    init() {
        loadLocations()
    }
    
    func addLocation(_ location: SavedLocation) {
        savedLocations.append(location)
        saveLocations()
    }
    
    func removeLocation(at offsets: IndexSet) {
        savedLocations.remove(atOffsets: offsets)
        saveLocations()
    }
    
    func removeLocation(withID id: UUID) {
        if let index = savedLocations.firstIndex(where: { $0.id == id }) {
            savedLocations.remove(at: index)
            saveLocations()
        }
    }
    
    // MARK: - Persistence
    
    func saveLocations() {
        do {
            let data = try JSONEncoder().encode(savedLocations)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("Failed to save locations: \(error.localizedDescription)")
        }
    }
    
    func loadLocations() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else {
            // No saved data yet
            return
        }
        
        do {
            savedLocations = try JSONDecoder().decode([SavedLocation].self, from: data)
        } catch {
            print("Failed to load locations: \(error.localizedDescription)")
        }
    }
    
    // Export locations to a file
    func exportLocations() -> URL? {
        do {
            // Create a temporary file URL
            let tempDirectoryURL = FileManager.default.temporaryDirectory
            let fileURL = tempDirectoryURL.appendingPathComponent("MyLocations.json")
            
            // Encode and write to file
            let data = try JSONEncoder().encode(savedLocations)
            try data.write(to: fileURL)
            
            return fileURL
        } catch {
            print("Failed to export locations: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Import locations from a file
    func importLocations(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let importedLocations = try JSONDecoder().decode([SavedLocation].self, from: data)
            
            // Add imported locations to current list
            savedLocations.append(contentsOf: importedLocations)
            saveLocations()
        } catch {
            print("Failed to import locations: \(error.localizedDescription)")
        }
    }
}
