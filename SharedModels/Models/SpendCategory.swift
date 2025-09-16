//
//  SpendCategory.swift
//  SharedModels
//

import SwiftData
import Foundation

@Model
public class SpendCategory {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var icon: String   // SF Symbol (e.g., "fork.knife")
    
    public init(name: String, icon: String) {
        self.id = UUID()
        self.name = name
        self.icon = icon
    }
}
