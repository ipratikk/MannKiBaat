//
//  NotesView.swift
//  MannKiBaat
//

//
//  NotesView.swift
//

import SwiftUI
import SwiftData
import SharedModels

@MainActor
public struct NotesView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject var viewModel: NotesViewModel
    @Query(sort: \NoteModel.createdAt, order: .reverse) private var notes: [NoteModel]

    public init(viewModel: NotesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        List {
            ForEach(viewModel.filteredNotes(from: notes)) { note in
                NavigationLink(destination: NoteEditorView(note: note, viewModel: viewModel)) {
                    NoteRowView(note: note)
                }
            }
            .onDelete { indexSet in
                Task {
                    let filtered = viewModel.filteredNotes(from: notes)
                    for index in indexSet {
                        guard filtered.indices.contains(index) else { continue }
                        await viewModel.removeNote(filtered[index], in: modelContext)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $viewModel.searchText)
        .refreshable {
            await viewModel.refresh(modelContext)
        }
    }
}
