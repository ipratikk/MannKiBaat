import SwiftUI
import SharedModels
import SwiftData

@MainActor
public struct TodosView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject var viewModel: TodosViewModel
    
    public init(viewModel: TodosViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        List {
            ForEach(viewModel.groupedTodos().keys.sorted(by: sectionSort), id: \.self) { section in
                Section(header: Text(section).font(.headline)) {
                    ForEach(viewModel.groupedTodos()[section] ?? []) { todo in
                        NavigationLink(destination: TodoDetailView(todo: todo, viewModel: viewModel)) {
                            TodoRowView(todo: todo)
                        }
                    }
                    .onDelete { indexSet in
                        Task {
                            let todosInSection = viewModel.groupedTodos()[section] ?? []
                            for i in indexSet {
                                guard todosInSection.indices.contains(i) else { continue }
                                await viewModel.removeTodo(todosInSection[i], in: modelContext)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
        .task { await viewModel.fetchTodos(in: modelContext) }
    }
    
    // MARK: - Section sorting: Today > Yesterday > Older
    private func sectionSort(_ a: String, _ b: String) -> Bool {
        let order = ["Today", "Yesterday", "Older"]
        return (order.firstIndex(of: a) ?? 99) < (order.firstIndex(of: b) ?? 99)
    }
}
