import SwiftUI
import SharedModels
import SwiftData

@MainActor
public struct TodosView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: TodosViewModel
    
    @Query(sort: [SortDescriptor(\TodoObject.createdAt, order: .reverse)]) private var todos: [TodoObject]
    @State private var searchText: String = ""
    
    public init(viewModel: TodosViewModel) {
        self.viewModel = viewModel
    }
    
    private var filteredTodos: [TodoObject] {
        guard !searchText.isEmpty else { return todos }
        return todos.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var groupedTodos: [String: [TodoObject]] {
        Dictionary(grouping: filteredTodos) { todo in
            let date = todo.createdAt
            let calendar = Calendar.current
            if calendar.isDateInToday(date) { return "Today" }
            else if calendar.isDateInYesterday(date) { return "Yesterday" }
            else { return "Older" }
        }
    }
    
    public var body: some View {
        ZStack {
            GradientBackgroundView()
            List {
                ForEach(groupedTodos.keys.sorted(by: sectionSort), id: \.self) { section in
                    Section(header: Text(section).font(.headline)) {
                        ForEach(groupedTodos[section] ?? []) { todo in
                            NavigationLink(destination: TodoDetailView(todo: todo, viewModel: viewModel)) {
                                TodoRowView(todo: todo)
                            }
                        }
                        .onDelete { indexSet in
                            Task {
                                let todosInSection = groupedTodos[section] ?? []
                                for i in indexSet {
                                    guard todosInSection.indices.contains(i) else { continue }
                                    modelContext.delete(todosInSection[i])
                                    try? modelContext.save()
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        }
    }
    
    private func sectionSort(_ a: String, _ b: String) -> Bool {
        let order = ["Today", "Yesterday", "Older"]
        return (order.firstIndex(of: a) ?? 99) < (order.firstIndex(of: b) ?? 99)
    }
}
