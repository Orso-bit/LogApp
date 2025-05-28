//
//  VeeTAApp.swift
//  VeeTA
//
//  Created by Vincenzo Salzano on 25/05/25.
//

import SwiftUI
import SwiftData

@main
struct VeeTAApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Tree.self,
            Cluster.self,
            Measurement.self,
            LengthMeasurement.self,
            TreeProiection.self,
            Clinometer.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(sharedModelContainer)
    }
}
