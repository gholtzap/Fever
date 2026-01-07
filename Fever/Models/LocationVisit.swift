//
//  LocationVisit.swift
//  Fever
//
//  Created by Claude on 1/7/26.
//

import Foundation
import SwiftData

@Model
final class LocationVisit {
    var latitude: Double
    var longitude: Double
    var timestamp: Date
    var duration: TimeInterval

    // Grid cell for aggregation (approximately 100m x 100m)
    var gridCell: String {
        let latRounded = round(latitude * 1000) / 1000  // ~111m resolution
        let lngRounded = round(longitude * 1000) / 1000
        return "lat_\(latRounded)_lng_\(lngRounded)"
    }

    init(latitude: Double, longitude: Double, timestamp: Date, duration: TimeInterval = 0) {
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.duration = duration
    }
}
