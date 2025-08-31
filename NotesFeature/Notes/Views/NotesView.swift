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
    @StateObject var viewModel: NotesViewModel
    @Query(sort: \NoteModel.createdAt, order: .reverse) private var notes: [NoteModel]
    
    public init(viewModel: NotesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
                // Gradient background
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
                List {
                    ForEach(sectionedNotes.keys.sorted(by: sectionSort), id: \.self) { section in
                        Section(header: Text(section).font(.headline)) {
                            ForEach(sectionedNotes[section]!) { note in
                                NavigationLink(destination: NoteEditorView(note: note, viewModel: viewModel)) {
                                    NoteRowView(note: note)
                                }
                            }
                            .onDelete { indexSet in
                                Task {
                                    let filteredNotes = sectionedNotes[section]!
                                    for index in indexSet {
                                        guard filteredNotes.indices.contains(index) else { continue }
                                        await viewModel.removeNote(filteredNotes[index], in: modelContext)
                                    }
                                }
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
                key = created.monthYearString() // e.g., "August 2025"
            } else {
                key = created.yearString() // e.g., "2024"
            }
            
            if groups[key] != nil {
                groups[key]!.append(note)
            } else {
                groups[key] = [note]
            }
        }
        
        return groups
    }
    
        // MARK: - Section sorting
    private func sectionSort(_ a: String, _ b: String) -> Bool {
        let order: [String] = ["Today", "Yesterday", "Last 30 Days"]
        if order.contains(a) && order.contains(b) {
            return order.firstIndex(of: a)! < order.firstIndex(of: b)!
        }
            // Parse month-year for current year
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        if let dateA = formatter.date(from: a), let dateB = formatter.date(from: b) {
            return dateA > dateB
        }
            // Parse year
        if let yearA = Int(a), let yearB = Int(b) {
            return yearA > yearB
        }
        return a > b
    }
}
