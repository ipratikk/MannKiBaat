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
            ForEach(sectionedNotes.keys.sorted(by: DateSectionGrouper.sectionSort), id: \.self) { section in
                Section(header: Text(section).font(.headline)) {
                    notesSection(for: section)
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
    
    // MARK: - Section
    @ViewBuilder
    private func notesSection(for section: String) -> some View {
        let notesInSection = sectionedNotes[section] ?? []
        
        ForEach(notesInSection) { note in
            NavigationLink(value: note) {
                NoteRowView(note: note)
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        }
        .onDelete { indexSet in
            Task {
                for i in indexSet {
                    guard notesInSection.indices.contains(i) else { continue }
                    await viewModel.removeNote(notesInSection[i], in: modelContext)
                }
            }
        }
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
    
    // MARK: - Group notes by section (using DateSectionGrouper)
    private var sectionedNotes: [String: [NoteModel]] {
        var groups: [String: [NoteModel]] = [:]
        for note in viewModel.filteredNotes(from: notes) {
            let key = DateSectionGrouper.sectionTitle(for: note.createdAt)
            groups[key, default: []].append(note)
        }
        return groups
    }
}
