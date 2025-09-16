//
// CategoryListView.swift
// SpendsFeature
//

import SwiftUI
import SharedModels
import SwiftData

@MainActor
public struct CategoryListView: View {
    @Query(sort: \SpendCategory.name) private var categories: [SpendCategory]
    @Environment(\.modelContext) private var modelContext
    
    @State private var newCategoryName: String = ""
    @State private var newCategoryIcon: String = "tag"
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            List {
                Section("Existing Categories") {
                    ForEach(categories) { category in
                        HStack {
                            Image(systemName: category.icon)
                            Text(category.name)
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { i in
                            let category = categories[i]
                            CategoryService.deleteCategory(category, in: modelContext)
                        }
                    }
                }
                
                Section("Add New Category") {
                    TextField("Category Name", text: $newCategoryName)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                    
                    TextField("Icon (SF Symbol)", text: $newCategoryIcon)
                        .disableAutocorrection(true)
                    
                    Button {
                        addCategory()
                    } label: {
                        Label("Add Category", systemImage: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .disabled(newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("Categories")
        }
    }
    
    private func addCategory() {
        guard !newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        CategoryService.addCategory(
            name: newCategoryName.trimmingCharacters(in: .whitespaces),
            icon: newCategoryIcon.isEmpty ? "tag" : newCategoryIcon,
            in: modelContext
        )
        newCategoryName = ""
        newCategoryIcon = "tag"
    }
}
