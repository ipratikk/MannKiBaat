//
//  CategoryService.swift
//  SharedModels
//

import Foundation
import SwiftData

public enum CategoryService {
    
    /// Fetches or creates the "Others" category
    public static func fetchOrCreateOthersCategory(in context: ModelContext) -> SpendCategory {
        let descriptor = FetchDescriptor<SpendCategory>(
            predicate: #Predicate { $0.name == "Others" }
        )
        
        if let existing = try? context.fetch(descriptor).first {
            return existing
        } else {
            let others = SpendCategory(name: "Others", icon: "ellipsis.circle")
            context.insert(others)
            try? context.save()
            return others
        }
    }
    
    /// Safely deletes a category, reassigning its spends to "Others"
    public static func deleteCategory(_ category: SpendCategory, in context: ModelContext) {
        let others = fetchOrCreateOthersCategory(in: context)
        
        if let spends = category.spends {
            for spend in spends {
                spend.category = others
            }
        }
        
        context.delete(category)
        try? context.save()
    }
}
