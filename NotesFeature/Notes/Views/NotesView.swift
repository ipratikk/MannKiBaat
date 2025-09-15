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
    
    // MARK: - Notes List
    private var notesList: some View {
        List {
            ForEach(sectionedNotes.keys.sorted(by: sectionSort), id: \.self) { section in
                Section(header: Text(section).font(.headline)) {
                    notesSection(for: section)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .listSectionSpacing(.compact) // 👈 compact like TodosView
        .searchable(text: $viewModel.searchText,
                    placement: .navigationBarDrawer(displayMode: .always))
        .refreshable {
            await viewModel.refresh(modelContext)
        }
        .animation(.easeInOut, value: viewModel.searchText) // 👈 match TodosView
    }
    
    // MARK: - Section
    @ViewBuilder
    private func notesSection(for section: String) -> some View {
        let notesInSection = sectionedNotes[section] ?? []
        
        ForEach(notesInSection) { note in
            NavigationLink(value: note) {
                NoteRowView(note: note)
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)) // 👈 compact row
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
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: notes.count) // 👈 animate like Todos
                }
                .padding()
            }
        }
    }
    
    // MARK: - Group notes by section
    private var sectionedNotes: [String: [NoteModel]] {
        var groups: [String: [NoteModel]] = [:]
        let calendar = Calendar.current
        let today = Date()
        
        for note in viewModel.filteredNotes(from: notes) {
            let created = note.createdAt
            let key: String
            if calendar.isDateInToday(created) {
                key = "Today"
            } else if calendar.isDateInYesterday(created) {
                key = "Yesterday"
            } else if let daysAgo = created.daysAgo(), daysAgo <= 30 {
                key = "Last 30 Days"
            } else if calendar.isDate(created, equalTo: today, toGranularity: .year) {
                key = created.monthYearString()
            } else {
                key = created.yearString()
            }
            
            groups[key, default: []].append(note)
        }
        
        return groups
    }
    
    // MARK: - Section sorting
    private func sectionSort(_ a: String, _ b: String) -> Bool {
        let order: [String] = ["Today", "Yesterday", "Last 30 Days"]
        if order.contains(a) && order.contains(b) {
            return order.firstIndex(of: a)! < order.firstIndex(of: b)!
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        if let dateA = formatter.date(from: a), let dateB = formatter.date(from: b) {
            return dateA > dateB
        }
        
        if let yearA = Int(a), let yearB = Int(b) {
            return yearA > yearB
        }
        
        return a > b
    }
}
