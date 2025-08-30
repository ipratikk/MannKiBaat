//
//  NotesView.swift
//  MannKiBaat
//

import SwiftUI
import SwiftData
import SharedModels

@MainActor
public struct NotesView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: NotesViewModel
    
    @Query(sort: \NoteModel.createdAt, order: .reverse) private var notes: [NoteModel]
    
    public init(viewModel: NotesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        List {
            ForEach(viewModel.filteredNotes(from: notes)) { note in
                NavigationLink(destination: NoteEditorView(viewModel: viewModel, note: note)) {
                    NoteRowView(note: note)
                }
            }
            .onDelete { indexSet in
                Task {
                    for index in indexSet {
                        await viewModel.removeNote(viewModel.filteredNotes(from: notes)[index], in: modelContext)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.refreshNotes()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: NoteEditorView(viewModel: viewModel)) {
                    Image(systemName: "plus")
                        .font(.title2)
                }
            }
        }
    }
}
