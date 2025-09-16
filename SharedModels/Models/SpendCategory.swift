//
//  SpendCategory.swift
//  SharedModels
//

import SwiftData
import Foundation

@Model
public class SpendCategory {
    public var id: UUID = UUID()
    public var name: String = ""
    public var icon: String = "tag"
    
    @Relationship(inverse: \Spend.category)
    public var spends: [Spend]?
    
    public init(name: String, icon: String) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.spends = []
    }
}
