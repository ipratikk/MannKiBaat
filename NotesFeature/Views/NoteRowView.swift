//
//  NoteRowView.swift
//  MannKiBaat
//

import SwiftUI
import Foundation
import SharedModels

struct NoteRowView: View {
    let note: NoteModel

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
            } else {
                // Fallback if there is no rich text stored yet
                EmptyView()
            }

            HStack {
                ForEach(Array(note.tags), id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            Text(note.createdAt, style: .date)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}
