import SwiftUI
import SwiftData
import SharedModels

@MainActor
public struct TodosView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject var viewModel: TodosViewModel
    
    @Query(sort: [SortDescriptor(\TodoObject.createdAt, order: .reverse)]) private var todos: [TodoObject]
    @State private var path: [TodoObject] = []
    
    public init(viewModel: TodosViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    private var groupedTodos: [String: [TodoObject]] {
        viewModel.groupedTodos(todos)
    }
    
    public var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                GradientBackgroundView()
                
                if todos.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No todos yet — add something to do!")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    todosList
                }
                
                plusButtonOverlay
            }
            .navigationDestination(for: TodoObject.self) { todo in
                TodoDetailView(todo: todo, viewModel: viewModel)
            }
            .navigationTitle("TODO")
        }
    }
    
    // MARK: - List
    private var todosList: some View {
        List {
            ForEach(groupedTodos.keys.sorted(by: DateSectionGrouper.sectionSort), id: \.self) { section in
                Section(header: Text(section).font(.headline)) {
                    todosSection(for: section)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .listSectionSpacing(.compact)
        .searchable(text: $viewModel.searchText,
                    placement: .navigationBarDrawer(displayMode: .always))
        .refreshable {                           // 👈 Added pull-to-refresh
            await viewModel.refresh(modelContext)
        }
        .animation(.easeInOut, value: viewModel.searchText)
    }
    
    // MARK: - Section
    @ViewBuilder
    private func todosSection(for section: String) -> some View {
        let todosInSection = groupedTodos[section] ?? []
        
        ForEach(todosInSection) { todo in
            NavigationLink(value: todo) {
                TodoRowView(todo: todo, viewModel: viewModel)
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        }
        .onDelete { indexSet in
            withAnimation {
                for i in indexSet {
                    guard todosInSection.indices.contains(i) else { continue }
                    viewModel.removeTodo(todosInSection[i], in: modelContext)
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
                        viewModel.addTodo(title: "", in: modelContext)
                        if let newTodo = todos.first {
                            path.append(newTodo)
                        }
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
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: todos.count)
                }
                .padding()
            }
        }
    }
}
