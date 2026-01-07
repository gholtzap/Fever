//
//  ContentView.swift
//  Fever
//
//  Created by Gavin Holtzapple on 1/7/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        MapView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: LocationVisit.self, inMemory: true)
}
