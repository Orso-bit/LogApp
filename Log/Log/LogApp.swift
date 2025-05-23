//
//  LogApp.swift
//  Log
//
//  Created by Giovanni Jr Di Fenza on 21/05/25.
//

import SwiftUI

@main
struct LogApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(LocationStore())
        }
    }
}
