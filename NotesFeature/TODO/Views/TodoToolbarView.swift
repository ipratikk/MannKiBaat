//
//  KeyboardToolbarView.swift
//

import SwiftUI

public struct TodoToolbarView: View {
    @Binding var dueDate: Date?
    @Binding var showCustomDueDateSheet: Bool
    
    public init(
        dueDate: Binding<Date?>,
        showCustomDueDateSheet: Binding<Bool>
    ) {
        self._dueDate = dueDate
        self._showCustomDueDateSheet = showCustomDueDateSheet
    }
    
    public var body: some View {
        HStack {
            Menu {
                Button("None", systemImage: "calendar") {
                    dueDate = nil
                    showCustomDueDateSheet = false  // Explicitly close sheet
                }
                Button("Today", systemImage: "calendar") {
                    dueDate = Calendar.current.startOfDay(for: Date())
                    showCustomDueDateSheet = false  // Explicitly close sheet
                }
                Button("Tomorrow", systemImage: "calendar") {
                    dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                    showCustomDueDateSheet = false  // Explicitly close sheet
                }
                Button("Custom…", systemImage: "ellipsis.circle") {
                    showCustomDueDateSheet = true
                }
            } label: {
                Image(systemName: "calendar.badge.plus")
            }
            
            Spacer()
        }
        .tint(.secondary)
    }
}
