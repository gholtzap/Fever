//
//  MapView.swift
//  Fever
//
//  Created by Claude on 1/7/26.
//

import SwiftUI
import MapKit
import SwiftData

struct MapView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var visits: [LocationVisit]
    @State private var locationManager = LocationManager()
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var showHeatmap = true
    @State private var followUser = true
    @State private var currentSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)

    var body: some View {
        ZStack {
            Map(position: $position) {
                if let location = locationManager.currentLocation {
                    Annotation("You", coordinate: location.coordinate) {
                        Circle()
                            .fill(.blue)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                            )
                    }
                }

                if showHeatmap {
                    ForEach(heatmapData, id: \.coordinate.latitude) { data in
                        // Watercolor-style layered gradient effect
                        // Outer diffusion layers
                        MapCircle(center: data.coordinate, radius: data.radius * 2.0)
                            .foregroundStyle(data.color.opacity(0.02))
                        MapCircle(center: data.coordinate, radius: data.radius * 1.7)
                            .foregroundStyle(data.color.opacity(0.04))
                        MapCircle(center: data.coordinate, radius: data.radius * 1.4)
                            .foregroundStyle(data.color.opacity(0.06))
                        MapCircle(center: data.coordinate, radius: data.radius * 1.2)
                            .foregroundStyle(data.color.opacity(0.08))

                        // Core layers
                        MapCircle(center: data.coordinate, radius: data.radius)
                            .foregroundStyle(data.color.opacity(0.12))
                        MapCircle(center: data.coordinate, radius: data.radius * 0.8)
                            .foregroundStyle(data.color.opacity(0.15))
                        MapCircle(center: data.coordinate, radius: data.radius * 0.6)
                            .foregroundStyle(data.color.opacity(0.18))
                        MapCircle(center: data.coordinate, radius: data.radius * 0.4)
                            .foregroundStyle(data.color.opacity(0.22))
                        MapCircle(center: data.coordinate, radius: data.radius * 0.2)
                            .foregroundStyle(data.color.opacity(0.25))
                    }
                }
            }
            .mapStyle(.standard)
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapPitchToggle()
                MapScaleView()
            }
            .onMapCameraChange { context in
                // User manually moved the map, stop auto-following
                followUser = false
            }

            VStack {
                HStack {
                    // Left side - Zoom controls
                    VStack(spacing: 0) {
                        Button(action: zoomIn) {
                            Image(systemName: "plus")
                                .font(.title3.bold())
                                .foregroundStyle(.primary)
                                .frame(width: 44, height: 44)
                                .background(.ultraThinMaterial)
                        }
                        Divider()
                        Button(action: zoomOut) {
                            Image(systemName: "minus")
                                .font(.title3.bold())
                                .foregroundStyle(.primary)
                                .frame(width: 44, height: 44)
                                .background(.ultraThinMaterial)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 2)
                    .padding(.leading)

                    Spacer()

                    // Right side - Controls
                    VStack(alignment: .trailing, spacing: 12) {
                        // Recenter button
                        Button(action: recenterMap) {
                            Image(systemName: followUser ? "location.fill" : "location")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 50)
                                .background(followUser ? Color.blue : Color(white: 0.5).opacity(0.5))
                                .clipShape(Circle())
                        }

                        // Toggle heatmap
                        Button(action: { showHeatmap.toggle() }) {
                            Image(systemName: showHeatmap ? "flame.fill" : "flame")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 50)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }

                        // Toggle tracking
                        Button(action: {
                            if locationManager.isTracking {
                                locationManager.stopTracking()
                            } else {
                                locationManager.startTracking()
                            }
                        }) {
                            Image(systemName: locationManager.isTracking ? "pause.fill" : "play.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 50)
                                .background(locationManager.isTracking ? .red : .green)
                                .clipShape(Circle())
                        }

                        // Stats card
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(visits.count)")
                                .font(.title.bold())
                            Text("locations")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.trailing)
                }
                .padding(.top)
                Spacer()
            }
        }
        .onAppear {
            locationManager.configure(with: modelContext)
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestPermission()
            }
        }
        .onChange(of: locationManager.currentLocation) { oldValue, newValue in
            if followUser, let location = newValue {
                // Only auto-center if following user
                withAnimation(.easeInOut(duration: 0.5)) {
                    position = .region(MKCoordinateRegion(
                        center: location.coordinate,
                        span: currentSpan
                    ))
                }
            }
        }
    }

    // MARK: - Map Controls

    private func zoomIn() {
        if let location = locationManager.currentLocation {
            withAnimation {
                // Zoom in by halving the span
                currentSpan = MKCoordinateSpan(
                    latitudeDelta: max(currentSpan.latitudeDelta * 0.5, 0.0001),
                    longitudeDelta: max(currentSpan.longitudeDelta * 0.5, 0.0001)
                )
                position = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: currentSpan
                ))
            }
        }
    }

    private func zoomOut() {
        if let location = locationManager.currentLocation {
            withAnimation {
                // Zoom out by doubling the span, max out at world view (180 degrees)
                currentSpan = MKCoordinateSpan(
                    latitudeDelta: min(currentSpan.latitudeDelta * 2.0, 180.0),
                    longitudeDelta: min(currentSpan.longitudeDelta * 2.0, 180.0)
                )
                position = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: currentSpan
                ))
            }
        }
    }

    private func recenterMap() {
        followUser = true
        if let location = locationManager.currentLocation {
            withAnimation(.easeInOut(duration: 0.5)) {
                position = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: currentSpan
                ))
            }
        }
    }

    // MARK: - Heatmap Calculation

    private var heatmapData: [HeatmapPoint] {
        guard !visits.isEmpty else { return [] }

        // Group by grid cell
        var cellData: [String: (count: Int, totalTime: Double, lat: Double, lng: Double)] = [:]

        for visit in visits {
            let cell = visit.gridCell
            if let existing = cellData[cell] {
                cellData[cell] = (
                    count: existing.count + 1,
                    totalTime: existing.totalTime + visit.duration,
                    lat: existing.lat,
                    lng: existing.lng
                )
            } else {
                cellData[cell] = (
                    count: 1,
                    totalTime: visit.duration,
                    lat: visit.latitude,
                    lng: visit.longitude
                )
            }
        }

        // Calculate heat scores
        let maxCount = cellData.values.map { $0.count }.max() ?? 1
        let maxTime = cellData.values.map { $0.totalTime }.max() ?? 1

        return cellData.map { cell, data in
            let normalizedCount = Double(data.count) / Double(maxCount)
            let normalizedTime = data.totalTime / maxTime
            let heatScore = (normalizedCount * 0.5) + (normalizedTime * 0.5)

            // Vary radius based on intensity for organic feel
            let baseRadius = 250.0  // Larger base for better blending
            let radiusVariation = 100.0 * heatScore  // Hotter spots = much larger
            let radius = baseRadius + radiusVariation

            return HeatmapPoint(
                coordinate: CLLocationCoordinate2D(latitude: data.lat, longitude: data.lng),
                intensity: heatScore,
                radius: radius,
                color: heatColor(for: heatScore)
            )
        }
    }

    private func heatColor(for intensity: Double) -> Color {
        // Vibrant watercolor-style heatmap: Purple -> Blue -> Cyan -> Green -> Yellow -> Orange -> Red
        if intensity < 0.2 {
            // Purple to Blue
            let t = intensity / 0.2
            return Color(red: 0.5 - (0.3 * t), green: 0.2 * t, blue: 0.8 + (0.2 * t))
        } else if intensity < 0.4 {
            // Blue to Cyan
            let t = (intensity - 0.2) / 0.2
            return Color(red: 0.2 * t, green: 0.2 + (0.5 * t), blue: 1.0)
        } else if intensity < 0.6 {
            // Cyan to Green/Yellow
            let t = (intensity - 0.4) / 0.2
            return Color(red: 0.2 + (0.5 * t), green: 0.7 + (0.3 * t), blue: 1.0 - (0.5 * t))
        } else if intensity < 0.8 {
            // Yellow to Orange
            let t = (intensity - 0.6) / 0.2
            return Color(red: 0.7 + (0.3 * t), green: 1.0 - (0.3 * t), blue: 0.5 - (0.5 * t))
        } else {
            // Orange to Red
            let t = (intensity - 0.8) / 0.2
            return Color(red: 1.0, green: 0.7 - (0.7 * t), blue: 0)
        }
    }
}

struct HeatmapPoint {
    let coordinate: CLLocationCoordinate2D
    let intensity: Double
    let radius: Double
    let color: Color
}

#Preview {
    MapView()
        .modelContainer(for: LocationVisit.self, inMemory: true)
}
