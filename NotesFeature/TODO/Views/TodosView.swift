import SwiftUI
import SharedModels
import SwiftData

@MainActor
public struct TodosView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: TodosViewModel
    
    @Query(sort: [SortDescriptor(\TodoObject.createdAt, order: .reverse)]) private var todos: [TodoObject]
    @State private var path: [TodoObject] = []
    
    public init(viewModel: TodosViewModel) {
        self.viewModel = viewModel
    }
    
    private var groupedTodos: [String: [TodoObject]] {
        viewModel.groupedTodos(todos)
    }
    
    public var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                GradientBackgroundView()
                List {
                    ForEach(groupedTodos.keys.sorted(by: sectionSort), id: \.self) { section in
                        Section(header: Text(section).font(.headline)) {
                            ForEach(groupedTodos[section] ?? []) { todo in
                                NavigationLink(value: todo) {
                                    TodoRowView(todo: todo)
                                }
                            }
                            .onDelete { indexSet in
                                Task {
                                    let todosInSection = groupedTodos[section] ?? []
                                    for i in indexSet {
                                        guard todosInSection.indices.contains(i) else { continue }
                                        modelContext.delete(todosInSection[i])
                                    }
                                    try? modelContext.save()
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .searchable(text: $viewModel.searchText,
                            placement: .navigationBarDrawer(displayMode: .always))
                
                // Floating + button
                plusButtonOverlay
            }
            .navigationDestination(for: TodoObject.self) { todo in
                TodoDetailView(todo: todo, viewModel: viewModel)
            }
            .navigationTitle("TODO")
        }
    }
    
    private var plusButtonOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    let newTodo = TodoObject(title: "")
                    modelContext.insert(newTodo)
                    try? modelContext.save()
                    path.append(newTodo)
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.buttonBackground)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding()
            }
        }
    }
    
    private func sectionSort(_ a: String, _ b: String) -> Bool {
        let order = ["Today", "Yesterday", "Older"]
        return (order.firstIndex(of: a) ?? 99) < (order.firstIndex(of: b) ?? 99)
    }
}
