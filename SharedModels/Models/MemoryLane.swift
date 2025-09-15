//
//  MemoryLane.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 16/09/25.
//

import SwiftData
import Foundation
import CoreLocation

@Model
public class MemoryLane: Identifiable {
    @Attribute public var id: UUID = UUID()
    @Attribute public var title: String = ""
    @Attribute public var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade) public var items: [MemoryItem]? = nil
    
    public init(id: UUID = UUID(), title: String = "", createdAt: Date = Date(), items: [MemoryItem]? = nil) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.items = items
    }
}

@Model
public class MemoryItem: Identifiable {
    @Attribute public var id: UUID = UUID()
    @Attribute public var title: String = ""
    @Attribute public var details: String = ""
    @Attribute public var createdAt: Date = Date()
    @Attribute public var imageData: Data? = nil
    @Attribute public var latitude: Double? = nil
    @Attribute public var longitude: Double? = nil
    @Relationship(inverse: \MemoryLane.items) public var parent: MemoryLane?
    
    public init(id: UUID = UUID(),
                title: String = "",
                details: String = "",
                createdAt: Date = Date(),
                imageData: Data? = nil,
                latitude: Double? = nil,
                longitude: Double? = nil,
                parent: MemoryLane? = nil) {
        self.id = id
        self.title = title
        self.details = details
        self.createdAt = createdAt
        self.imageData = imageData
        self.latitude = latitude
        self.longitude = longitude
        self.parent = parent
    }
    
    public var coordinate: (lat: Double, lon: Double)? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return (lat, lon)
    }
}
