import SwiftUI
import SharedModels
import SwiftData

// PreferenceKey to track TextEditor heights
struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 40
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

@MainActor
public struct TodoDetailView: View {
    @Bindable var todo: TodoObject
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: TodosViewModel
    
    @FocusState private var isTitleFocused: Bool
    @State private var newItemTitle: String = ""
    @State private var itemHeights: [UUID: CGFloat] = [:]
    @State private var isNewTodo: Bool = false
    
    public init(todo: TodoObject, viewModel: TodosViewModel) {
        self._todo = Bindable(todo)
        self.viewModel = viewModel
        self._isNewTodo = State(initialValue: todo.title.isEmpty)
    }
    
    private var itemsBinding: Binding<[TodoItem]> {
        Binding(
            get: { todo.items ?? [] },
            set: { todo.items = $0 }
        )
    }
    
    public var body: some View {
        ZStack {
            GradientBackgroundView()
            
            VStack {
                // MARK: - Todo Title
                TextField("Todo Title", text: $todo.title)
                    .font(.largeTitle.bold())
                    .padding()
                    .focused($isTitleFocused)
                
                // MARK: - Todo Items
                List {
                    ForEach(itemsBinding.wrappedValue.sorted { !$0.isCompleted && $1.isCompleted }, id: \.id) { item in
                        HStack(alignment: .top) {
                            // Checkmark
                            Button {
                                Task { await viewModel.toggleItemCompletion(item, in: modelContext) }
                            } label: {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(item.isCompleted ? .green : .secondary)
                                    .font(.title2)
                            }
                            .padding(.top, 8)
                            
                            // TextEditor with dynamic height
                            ZStack(alignment: .topLeading) {
                                Text(item.title.isEmpty ? "New Item" : item.title)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .padding(8)
                                    .opacity(0)
                                    .background(
                                        GeometryReader { geo in
                                            Color.clear
                                                .preference(key: ViewHeightKey.self, value: geo.size.height)
                                        }
                                    )
                                
                                TextEditor(text: Binding(
                                    get: { item.title },
                                    set: { newValue in
                                        item.title = newValue
                                        try? modelContext.save()
                                    }
                                ))
                                .frame(height: max(40, itemHeights[item.id] ?? 40))
                                .scrollDisabled(true)
                                .padding(4)
                                .background(Color.clear)
                            }
                            .onPreferenceChange(ViewHeightKey.self) { height in
                                itemHeights[item.id] = height
                            }
                        }
                    }
                    .onDelete { indexSet in
                        var items = todo.items ?? []
                        for i in indexSet.sorted(by: >) {
                            modelContext.delete(items[i])
                            items.remove(at: i)
                        }
                        todo.items = items
                        try? modelContext.save()
                    }
                    
                    // MARK: - Add New Item
                    HStack(alignment: .top) {
                        ZStack(alignment: .topLeading) {
                            Text(newItemTitle.isEmpty ? "New Item" : newItemTitle)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding(8)
                                .opacity(0)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear.preference(key: ViewHeightKey.self, value: geo.size.height)
                                    }
                                )
                            
                            TextEditor(text: $newItemTitle)
                                .frame(height: max(40, itemHeights[UUID()] ?? 40))
                                .scrollDisabled(true)
                                .padding(4)
                        }
                        
                        Button {
                            let trimmed = newItemTitle.trimmingCharacters(in: .whitespaces)
                            guard !trimmed.isEmpty else { return }
                            Task {
                                await viewModel.addItem(to: todo, title: trimmed, in: modelContext)
                                newItemTitle = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.accentColor)
                                .font(.title2)
                        }
                        .padding(.top, 8)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(todo.title.isEmpty ? "New Todo" : todo.title)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if isNewTodo { isTitleFocused = true }
            }
            .onDisappear {
                Task {
                    if todo.title.trimmingCharacters(in: .whitespaces).isEmpty {
                        todo.title = "New Todo"
                    }
                    if isNewTodo {
                        modelContext.insert(todo)
                        try? await modelContext.save()
                    }
                }
            }
        }
    }
}
