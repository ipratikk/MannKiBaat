import SwiftUI
import SwiftData
import SharedModels

@MainActor
public struct NotesView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject var viewModel: NotesViewModel
    @Query(sort: \NoteModel.createdAt, order: .reverse) private var notes: [NoteModel]
    
    @State private var path: [NoteModel] = []
    
    public init(viewModel: NotesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                GradientBackgroundView()
                
                if notes.isEmpty {
                    emptyState
                } else {
                    notesList
                }
                
                plusButtonOverlay
            }
            .navigationDestination(for: NoteModel.self) { note in
                NoteEditorView(note: note, viewModel: viewModel)
            }
            .navigationTitle("Mann Ki Baatein")
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("What's on your mind today, Manasa?")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Notes List
    private var notesList: some View {
        List {
            let sections = viewModel.groupedNotes(viewModel.filteredNotes(from: notes))
            
            ForEach(sections, id: \.title) { section in
                Section(header: Text(section.title).font(.headline)) {
                    ForEach(section.notes) { note in
                        NavigationLink(value: note) {
                            NoteRowView(note: note)
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                    .onDelete { indexSet in
                        Task {
                            for i in indexSet {
                                guard section.notes.indices.contains(i) else { continue }
                                await viewModel.removeNote(section.notes[i], in: modelContext)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .listSectionSpacing(.compact)
        .searchable(text: $viewModel.searchText,
                    placement: .navigationBarDrawer(displayMode: .always))
        .refreshable {
            await viewModel.refresh(modelContext)
        }
        .animation(.easeInOut, value: viewModel.searchText)
    }
    
    // MARK: - Plus Button
    private var plusButtonOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    withAnimation {
                        let newNote = NoteModel()
                        modelContext.insert(newNote)
                        try? modelContext.save()
                        path.append(newNote)
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.buttonBackground)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                        .scaleEffect(1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: notes.count)
                }
                .padding()
            }
        }
    }
}
