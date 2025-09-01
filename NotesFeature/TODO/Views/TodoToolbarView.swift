//
//  KeyboardToolbarView.swift
//

import SwiftUI

public struct TodoToolbarView: View {
    @Binding var dueDate: Date?
    @Binding var showTagsField: Bool
    @Binding var showCustomDueDateSheet: Bool
    @Binding var tags: String
    
    public init(
        dueDate: Binding<Date?>,
        showTagsField: Binding<Bool>,
        showCustomDueDateSheet: Binding<Bool>,
        tags: Binding<String>
    ) {
        self._dueDate = dueDate
        self._showTagsField = showTagsField
        self._showCustomDueDateSheet = showCustomDueDateSheet
        self._tags = tags
    }
    
    public var body: some View {
        HStack {
            Menu {
                Button("Today") { dueDate = Calendar.current.startOfDay(for: Date()) }
                Button("Tomorrow") {
                    dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                }
                Button("Custom…") { showCustomDueDateSheet = true }
            } label: {
                Image(systemName: "calendar")
            }
            
            Button {
                withAnimation { showTagsField.toggle() }
            } label: {
                Image(systemName: "tag")
            }
        }
    }
}
