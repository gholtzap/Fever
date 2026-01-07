//
//  FeverApp.swift
//  Fever
//
//  Created by Gavin Holtzapple on 1/7/26.
//

import SwiftUI
import SwiftData

@main
struct FeverApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            LocationVisit.self,
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
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
