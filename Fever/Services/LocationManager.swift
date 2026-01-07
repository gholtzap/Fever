//
//  LocationManager.swift
//  Fever
//
//  Created by Claude on 1/7/26.
//

import Foundation
import CoreLocation
import SwiftData

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var modelContext: ModelContext?
    private var lastLocation: CLLocation?
    private var lastSaveTime: Date?

    var currentLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isTracking = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 50  // Update every 50 meters when in foreground
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = manager.authorizationStatus
    }

    func configure(with context: ModelContext) {
        self.modelContext = context
    }

    func requestPermission() {
        manager.requestAlwaysAuthorization()
    }

    func startTracking() {
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            requestPermission()
            return
        }

        isTracking = true
        manager.startUpdatingLocation()
        manager.startMonitoringSignificantLocationChanges()
    }

    func stopTracking() {
        isTracking = false
        manager.stopUpdatingLocation()
        manager.stopMonitoringSignificantLocationChanges()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            if isTracking {
                startTracking()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location

        saveLocationVisit(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }

    // MARK: - Data Persistence

    private func saveLocationVisit(_ location: CLLocation) {
        guard let context = modelContext else { return }

        let now = Date()
        var duration: TimeInterval = 0

        // Calculate duration since last save
        if let lastTime = lastSaveTime {
            duration = now.timeIntervalSince(lastTime)

            // Only count durations up to 30 minutes (ignore long gaps)
            if duration > 1800 {
                duration = 0
            }
        }

        // Only save if we moved significantly or it's been a while
        let shouldSave: Bool
        if let last = lastLocation {
            let distance = location.distance(from: last)
            let timeSinceLastSave = lastSaveTime.map { now.timeIntervalSince($0) } ?? .infinity
            shouldSave = distance > 100 || timeSinceLastSave > 300  // 100m or 5 minutes
        } else {
            shouldSave = true
        }

        if shouldSave {
            let visit = LocationVisit(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                timestamp: now,
                duration: duration
            )

            context.insert(visit)

            do {
                try context.save()
                lastLocation = location
                lastSaveTime = now
            } catch {
                print("Failed to save location visit: \(error)")
            }
        }
    }
}
