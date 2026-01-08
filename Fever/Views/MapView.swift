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
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?

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
                MapCompass()
                MapScaleView()
            }
            .onMapCameraChange { context in
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
                        // Share button
                        Button(action: shareHeatmap) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 50)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }

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
                withAnimation(.easeInOut(duration: 0.5)) {
                    position = .region(MKCoordinateRegion(
                        center: location.coordinate,
                        span: currentSpan
                    ))
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image])
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

    private func shareHeatmap() {
        Task {
            if let image = await createMapSnapshot() {
                await MainActor.run {
                    shareImage = image
                    showShareSheet = true
                }
            }
        }
    }

    private func createMapSnapshot() async -> UIImage? {
        let snapshotRegion = await getSnapshotRegion()
        guard let region = snapshotRegion else { return nil }

        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = CGSize(width: 1080, height: 1920)
        options.scale = UIScreen.main.scale

        let snapshotter = MKMapSnapshotter(options: options)

        do {
            let snapshot = try await snapshotter.start()
            return drawHeatmapOnSnapshot(snapshot, region: region)
        } catch {
            print("Failed to create snapshot: \(error)")
            return nil
        }
    }

    @MainActor
    private func getMapRegion() -> MKCoordinateRegion? {
        if let location = locationManager.currentLocation {
            return MKCoordinateRegion(center: location.coordinate, span: currentSpan)
        }
        return nil
    }

    @MainActor
    private func getSnapshotRegion() -> MKCoordinateRegion? {
        guard !visits.isEmpty else {
            return getMapRegion()
        }

        var minLat = visits[0].latitude
        var maxLat = visits[0].latitude
        var minLon = visits[0].longitude
        var maxLon = visits[0].longitude

        for visit in visits {
            minLat = min(minLat, visit.latitude)
            maxLat = max(maxLat, visit.latitude)
            minLon = min(minLon, visit.longitude)
            maxLon = max(maxLon, visit.longitude)
        }

        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2

        let spanLat = (maxLat - minLat) * 1.3
        let spanLon = (maxLon - minLon) * 1.3

        let span = MKCoordinateSpan(
            latitudeDelta: max(spanLat, 0.01),
            longitudeDelta: max(spanLon, 0.01)
        )

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: span
        )
    }

    private func drawHeatmapOnSnapshot(_ snapshot: MKMapSnapshotter.Snapshot, region: MKCoordinateRegion) -> UIImage {
        let image = snapshot.image
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale

        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)

        return renderer.image { context in
            image.draw(at: .zero)

            if showHeatmap {
                let baseRadiusPoints = min(image.size.width, image.size.height) * 0.04

                for data in heatmapData {
                    let point = snapshot.point(for: data.coordinate)

                    let radiusInPoints = baseRadiusPoints * (1.0 + CGFloat(data.intensity) * 1.5)

                    let layers = [
                        (multiplier: 3.0, opacity: 0.03),
                        (multiplier: 2.5, opacity: 0.05),
                        (multiplier: 2.0, opacity: 0.08),
                        (multiplier: 1.7, opacity: 0.10),
                        (multiplier: 1.4, opacity: 0.12),
                        (multiplier: 1.2, opacity: 0.15),
                        (multiplier: 1.0, opacity: 0.18),
                        (multiplier: 0.8, opacity: 0.22),
                        (multiplier: 0.6, opacity: 0.28),
                        (multiplier: 0.4, opacity: 0.35),
                        (multiplier: 0.2, opacity: 0.42),
                    ]

                    for layer in layers {
                        let layerRadius = radiusInPoints * layer.multiplier
                        let rect = CGRect(
                            x: point.x - layerRadius,
                            y: point.y - layerRadius,
                            width: layerRadius * 2,
                            height: layerRadius * 2
                        )

                        let uiColor = UIColor(data.color.opacity(layer.opacity))
                        uiColor.setFill()

                        let path = UIBezierPath(ovalIn: rect)
                        path.fill()
                    }
                }
            }

            let overlayRect = CGRect(x: image.size.width - 700, y: image.size.height - 400, width: 640, height: 320)
            UIColor.systemBackground.withAlphaComponent(0.85).setFill()
            let roundedRect = UIBezierPath(roundedRect: overlayRect, cornerRadius: 24)
            roundedRect.fill()

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 48, weight: .bold),
                .foregroundColor: UIColor.label
            ]
            let title = "My Exploration Heatmap"
            let titleRect = CGRect(x: overlayRect.minX + 60, y: overlayRect.minY + 60, width: overlayRect.width - 120, height: 100)
            title.draw(in: titleRect, withAttributes: titleAttributes)

            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let subtitle = "\(visits.count) locations visited"
            let subtitleRect = CGRect(x: overlayRect.minX + 60, y: overlayRect.minY + 160, width: overlayRect.width - 120, height: 60)
            subtitle.draw(in: subtitleRect, withAttributes: subtitleAttributes)
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

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    MapView()
        .modelContainer(for: LocationVisit.self, inMemory: true)
}
