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
        ZStack {
            // Gradient background
            GradientBackgroundView()
            
            // Placeholder text if no notes
            if viewModel.filteredNotes(from: notes).isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "book")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.secondary.opacity(0.7))
                    
                    Text("Your safe space to reflect and write…")
                        .font(.title3)
                        .foregroundColor(.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding()
            }
            
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
            .scrollContentBackground(.hidden) // hides default list background
            .searchable(text: $viewModel.searchText)
            .refreshable {
                await viewModel.refresh(modelContext)
            }
        }
    }
}
