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
    @State private var hideCompletedItems: Bool = false
    
    public init(todo: TodoObject, viewModel: TodosViewModel) {
        self._todo = Bindable(todo)
        self.viewModel = viewModel
    }
    
    // MARK: - Item Sections
    private var pinnedItems: [TodoItem] {
        (todo.items ?? [])
            .filter { $0.isPinned }
            .filter { hideCompletedItems ? !$0.isCompleted : true }
            .sorted { !$0.isCompleted && $1.isCompleted }
    }
    
    private var normalItems: [TodoItem] {
        (todo.items ?? [])
            .filter { !$0.isPinned }
            .filter { hideCompletedItems ? !$0.isCompleted : true }
            .sorted { !$0.isCompleted && $1.isCompleted }
    }
    
    public var body: some View {
        ZStack {
            GradientBackgroundView()
            
            VStack {
                titleField
                itemsList
            }
            .globalDoneToolbar()
            .navigationTitle(todo.title.isEmpty ? "New Todo" : todo.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .onAppear { if todo.title.isEmpty { isTitleFocused = true } }
            .onDisappear { saveOrFixTitle() }
        }
    }
    
    // MARK: - Title
    private var titleField: some View {
        TextField("Todo Title", text: $todo.title)
            .font(.largeTitle.bold())
            .padding()
            .focused($isTitleFocused)
    }
    
    // MARK: - Items List (2 sections)
    private var itemsList: some View {
        List {
            // Pinned Section
            if !pinnedItems.isEmpty {
                Section(header: Text("Pinned")) {
                    ForEach(pinnedItems, id: \.id) { item in
                        todoItemRow(item)
                            .id(item.id)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        item.isPinned.toggle()
                                        item.updatedAt = Date()
                                        try? modelContext.save()
                                    }
                                } label: {
                                    Label("Unpin", systemImage: "pin.slash")
                                }
                                .tint(.yellow)
                            }
                    }
                    .onDelete { indexSet in
                        withAnimation {
                            for index in indexSet {
                                viewModel.deleteItem(pinnedItems[index], in: modelContext)
                            }
                        }
                    }
                }
            }
            
            // Normal Section (no header)
            Section {
                ForEach(normalItems, id: \.id) { item in
                    todoItemRow(item)
                        .id(item.id)
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    item.isPinned.toggle()
                                    item.updatedAt = Date()
                                    try? modelContext.save()
                                }
                            } label: {
                                Label("Pin", systemImage: "pin")
                            }
                            .tint(.yellow)
                        }
                }
                .onDelete { indexSet in
                    withAnimation {
                        for index in indexSet {
                            viewModel.deleteItem(normalItems[index], in: modelContext)
                        }
                    }
                }
                
                addItemRow
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .transaction { t in t.disablesAnimations = false }
        .animation(.easeInOut(duration: 0.25), value: pinnedItems)
        .animation(.easeInOut(duration: 0.25), value: normalItems)
    }
    
    // MARK: - Single Item Row
    @ViewBuilder
    private func todoItemRow(_ item: TodoItem) -> some View {
        HStack(alignment: .top) {
            // Checkbox
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.toggleItemCompletion(item, in: modelContext)
                }
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(item.isCompleted ? .green : .secondary)
                    .scaleEffect(item.isCompleted ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.25), value: item.isCompleted)
            }
            .padding(.top, 8)
            
            // Title
            TextField("New Item", text: Binding(
                get: { item.title },
                set: { newValue in
                    item.title = newValue
                    try? modelContext.save()
                }
            ), axis: .vertical)
            .lineLimit(1...)
            .padding(4)
            
            Spacer()
            
            // Pin icon (trailing)
            if item.isPinned {
                Image(systemName: "pin.fill")
                    .foregroundColor(.yellow)
                    .rotationEffect(.degrees(45))
                    .padding(.top, 6)
                    .transition(.opacity.combined(with: .scale))
                    .animation(.easeInOut(duration: 0.25), value: item.isPinned)
            }
        }
    }
    
    // MARK: - Add New Item Row
    private var addItemRow: some View {
        HStack(alignment: .bottom) {
            TextField("New Item", text: $newItemTitle, axis: .vertical)
                .lineLimit(1...)
                .padding(4)
            
            Button {
                let trimmed = newItemTitle.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.addItem(to: todo, title: trimmed, in: modelContext)
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
    
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button(role: .destructive) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.removeTodo(todo, in: modelContext)
                    dismiss()
                }
            } label: { Image(systemName: "trash") }
            
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    hideCompletedItems.toggle()
                }
            } label: {
                Image(systemName: hideCompletedItems ? "eye" : "eye.slash")
            }
        }
    }
    
    // MARK: - Save/Fix Title
    private func saveOrFixTitle() {
        if todo.title.trimmingCharacters(in: .whitespaces).isEmpty {
            todo.title = "New Todo"
        }
        try? modelContext.save()
    }
}
