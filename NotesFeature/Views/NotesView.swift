//
//  NotesView.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import SwiftUI
import SharedModels

public struct NotesView: View {
    @StateObject private var viewModel: NotesViewModel

    public init(viewModel: NotesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack {
            // MARK: Search + Sort + Filter
            HStack {
                TextField("Search notes...", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: viewModel.searchText) { _ in
                        Task { await viewModel.applyFilters() }
                    }

                Button(action: {
                    viewModel.sortAscending.toggle()
                    Task { await viewModel.applyFilters() }
                }) {
                    Image(systemName: viewModel.sortAscending ? "arrow.up" : "arrow.down")
                }
            }
            .padding()

            // MARK: Filter by tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(Array(viewModel.notes.flatMap { $0.tags }.unique()), id: \.self) { tag in
                        Button(action: {
                            if viewModel.selectedTags.contains(tag) {
                                viewModel.selectedTags.remove(tag)
                            } else {
                                viewModel.selectedTags.insert(tag)
                            }
                            Task { await viewModel.applyFilters() }
                        }) {
                            Text(tag)
                                .padding(6)
                                .background(viewModel.selectedTags.contains(tag) ? Color.blue.opacity(0.7) : Color.gray.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(.horizontal)
            }

            // MARK: Notes List
            List {
                ForEach(viewModel.displayedNotes) { note in
                    VStack(alignment: .leading) {
                        Text(note.title).bold()
                        Text(note.content).font(.subheadline)
                        if !note.tags.isEmpty {
                            Text("Tags: \(note.tags.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text("Created: \(note.createdAt.formatted())")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.removeNote(at: index)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .task { await viewModel.fetchNotes() }
    }
}

// MARK: - Helper to get unique tags
fileprivate extension Array where Element: Hashable {
    func unique() -> [Element] {
        Array(Set(self))
    }
}
