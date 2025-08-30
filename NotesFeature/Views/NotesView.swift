//
//  NotesView.swift
//  MannKiBaat
//

import SwiftUI
import SharedModels

@MainActor
public struct NotesView: View {
    @StateObject private var viewModel: NotesViewModel

    public init(viewModel: NotesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        List {
            ForEach(viewModel.displayedNotes) { note in
                NoteRowView(note: note)
            }
            .onDelete { indexSet in
                Task {
                    for index in indexSet {
                        await viewModel.removeNote(viewModel.displayedNotes[index])
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "Search notes"
        )
        .onChange(of: viewModel.searchText) { _ in
            Task { await viewModel.applyFilters() }
        }
        .onChange(of: viewModel.selectedTags) { _ in
            Task { await viewModel.applyFilters() }
        }
        .onChange(of: viewModel.sortAscending) { _ in
            Task { await viewModel.applyFilters() }
        }
        .task {
            await viewModel.applyFilters()
        }
    }
}
