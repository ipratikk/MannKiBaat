import SwiftUI
import SharedModels
import SwiftData

@MainActor
public struct TodoDetailView: View {
    @Bindable var todo: TodoObject
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TodosViewModel
    
    @FocusState private var isTitleFocused: Bool
    @State private var newItemTitle: String = ""
    @State private var hideCompletedItems: Bool = true
    
    public init(todo: TodoObject, viewModel: TodosViewModel) {
        self._todo = Bindable(todo)
        self.viewModel = viewModel
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
                // Title
                TextField("Todo Title", text: $todo.title)
                    .font(.largeTitle.bold())
                    .padding()
                    .focused($isTitleFocused)
                
                // Items list
                List {
                    ForEach(
                        itemsBinding.wrappedValue
                            .filter { hideCompletedItems ? !$0.isCompleted : true }
                            .sorted { !$0.isCompleted && $1.isCompleted },
                        id: \.id
                    ) { item in
                        HStack(alignment: .top) {
                            Button {
                                Task { await viewModel.toggleItemCompletion(item, in: modelContext) }
                            } label: {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(item.isCompleted ? .green : .secondary)
                                    .font(.title2)
                            }
                            .padding(.top, 8)
                            
                            TextField("New Item", text: Binding(
                                get: { item.title },
                                set: { newValue in
                                    item.title = newValue
                                    try? modelContext.save()
                                }
                            ), axis: .vertical)
                            .lineLimit(1...)
                            .padding(4)
                        }
                    }
                    .onDelete { indexSet in
                        let items = itemsBinding.wrappedValue
                        for index in indexSet {
                            Task { await viewModel.deleteItem(items[index], in: modelContext) }
                        }
                    }
                    
                    // Add new item row
                    HStack(alignment: .bottom) {
                        TextField("New Item", text: $newItemTitle, axis: .vertical)
                            .lineLimit(1...)
                            .padding(4)
                        
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
            .globalDoneToolbar()
            .navigationTitle(todo.title.isEmpty ? "New Todo" : todo.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.removeTodo(todo, in: modelContext)
                            dismiss()
                        }
                    } label: { Image(systemName: "trash") }
                    
                    Button {
                        hideCompletedItems.toggle()
                    } label: {
                        Image(systemName: hideCompletedItems ? "eye.slash" : "eye")
                    }
                }
            }
            .onAppear { if todo.title.isEmpty { isTitleFocused = true } }
            .onDisappear {
                Task {
                    if todo.title.trimmingCharacters(in: .whitespaces).isEmpty {
                        todo.title = "New Todo"
                    }
                    try? await modelContext.save()
                }
            }
        }
    }
}
