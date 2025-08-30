//
//  NoteRowView.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import SwiftUI
import SharedModels

struct NoteRowView: View {
    let note: NoteModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title).bold()
            Text(note.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
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
