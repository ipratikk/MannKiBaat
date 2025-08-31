//
//  NoteRowView.swift
//  MannKiBaat
//

import SwiftUI
import Foundation
import SharedModels

struct NoteRowView: View {
    let note: NoteModel
    
    private var noteDateString: String {
        if note.createdAt.isToday() || note.createdAt.isYesterday() {
            return note.createdAt.timeString() // e.g., 3:45 PM
        } else if let daysAgo = note.createdAt.daysAgo(), daysAgo <= 30 {
            return note.createdAt.dayMonthYearString() // e.g., Aug 10, 2025
        } else if Calendar.current.isDate(note.createdAt, equalTo: Date(), toGranularity: .year) {
            return note.createdAt.monthYearString() // e.g., July 2025
        } else {
            return note.createdAt.yearString() // e.g., 2024
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title).bold()
            
                // Rich-text preview (decode NSAttributedString from Data)
            if let ns = try? NSKeyedUnarchiver.unarchivedObject(
                ofClass: NSAttributedString.self,
                from: note.richTextData
            ) {
                Text(AttributedString(ns))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            VStack {
                ForEach(Array(note.tags), id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
                Text(noteDateString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
