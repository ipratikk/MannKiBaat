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
        VStack(spacing: 0) {
            // Search bar
            TextField("Search notes...", text: $viewModel.searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .padding(.top)

            // Notes list
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
        }
        .task {
            await viewModel.applyFilters()
        }
        // iOS 17 style onChange
        .onChange(of: viewModel.searchText) { _ in
            Task { await viewModel.applyFilters() }
        }
        .onChange(of: viewModel.selectedTags) { _ in
            Task { await viewModel.applyFilters() }
        }
        .onChange(of: viewModel.sortAscending) { _ in
            Task { await viewModel.applyFilters() }
        }
    }
}
