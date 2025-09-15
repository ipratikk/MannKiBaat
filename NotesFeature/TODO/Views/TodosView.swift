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
    
    // MARK: - Group Todos by Section
    private var sectionedTodos: [String: [TodoObject]] {
        var groups: [String: [TodoObject]] = [:]
        let calendar = Calendar.current
        let today = Date()
        
        for todo in viewModel.filteredTodos(from: todos) {
            let created = todo.createdAt
            let key: String
            if calendar.isDateInToday(created) {
                key = "Today"
            } else if calendar.isDateInYesterday(created) {
                key = "Yesterday"
            } else if let daysAgo = created.daysAgo(), daysAgo <= 30 {
                key = "Last 30 Days"
            } else if calendar.isDate(created, equalTo: today, toGranularity: .year) {
                key = created.monthYearString() // e.g. "September 2025"
            } else {
                key = created.yearString() // e.g. "2024"
            }
            
            groups[key, default: []].append(todo)
        }
        
        return groups
    }
    
    public var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                GradientBackgroundView()
                todosList
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
            ForEach(sectionedTodos.keys.sorted(by: sectionSort), id: \.self) { section in
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
        .animation(.easeInOut, value: viewModel.searchText)
    }
    
    // MARK: - Section
    @ViewBuilder
    private func todosSection(for section: String) -> some View {
        let todosInSection = sectionedTodos[section] ?? []
        
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
                        if let newTodo = todos.first { // sorted by createdAt desc
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
