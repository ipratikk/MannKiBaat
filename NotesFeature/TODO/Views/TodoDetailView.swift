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
    
    // MARK: - Edit & Selection
    @State private var editMode: EditMode = .inactive
    @State private var selection = Set<UUID>()
    
    // MARK: - Sort Mode
    private enum SortMode: String, CaseIterable {
        case manual = "Manual"
        case byDate = "Date"
        case byCompleted = "Completed"
    }
    @State private var sortMode: SortMode = .manual
    
    @FocusState private var isNewItemFocused: Bool
    
    public init(todo: TodoObject, viewModel: TodosViewModel) {
        self._todo = Bindable(todo)
        self.viewModel = viewModel
    }
    
    // MARK: - Flags
    private var hasCompletedItems: Bool {
        (todo.items ?? []).contains { $0.isCompleted }
    }
    
    // MARK: - Sections
    private var pinnedItems: [TodoItem] {
        filtered(todo.items?.filter { $0.isPinned } ?? [])
    }
    private var normalItems: [TodoItem] {
        filtered(todo.items?.filter { !$0.isPinned } ?? [])
    }
    
    private func filtered(_ arr: [TodoItem]) -> [TodoItem] {
        let items = arr.filter { hideCompletedItems ? !$0.isCompleted : true }
        switch sortMode {
        case .manual:
            return items.sorted { $0.orderIndex < $1.orderIndex }
        case .byDate:
            return items.sorted { $0.createdAt > $1.createdAt }
        case .byCompleted:
            return items.sorted { !$0.isCompleted && $1.isCompleted }
        }
    }
    
    // MARK: - Body
    public var body: some View {
        ZStack {
            GradientBackgroundView()
            
            VStack(spacing: 0) {
                titleField
                controlRow
                itemsList
            }
            .globalDoneToolbar()
            .navigationTitle(todo.title.isEmpty ? "New Todo" : todo.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .onAppear { if todo.title.isEmpty { isTitleFocused = true } }
            .onDisappear { viewModel.saveOrFixTitle(for: todo, in: modelContext) }
        }
        .environment(\.editMode, $editMode)
    }
    
    // MARK: - Title
    private var titleField: some View {
        TextField("Todo Title", text: $todo.title)
            .font(.largeTitle.bold())
            .padding()
            .focused($isTitleFocused)
            .textFieldStyle(.plain)
    }
    
    // MARK: - Control Row
    private var controlRow: some View {
        HStack {
            Spacer()
            
            Menu {
                ForEach(SortMode.allCases, id: \.self) { mode in
                    Button(mode.rawValue) { sortMode = mode }
                }
            } label: {
                CircleIconButton(systemName: "arrow.up.arrow.down")
            }
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    editMode = (editMode == .active ? .inactive : .active)
                }
            } label: {
                CircleIconButton(systemName: editMode == .active ? "checkmark" : "pencil")
            }
            .padding(.leading, 8)
            .padding(.trailing, 12)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Items List
    private var itemsList: some View {
        List(selection: $selection) {
            if !pinnedItems.isEmpty {
                Section(header: Text("Pinned")) {
                    ForEach(pinnedItems, id: \.id) { item in
                        todoItemRow(for: item).id(item.id)
                    }
                    .onDelete { indexSet in deleteItems(indexSet, from: pinnedItems) }
                    .onMove { indices, newOffset in reorderItems(in: pinnedItems, indices: indices, newOffset: newOffset) }
                }
            }
            
            Section {
                ForEach(normalItems, id: \.id) { item in
                    todoItemRow(for: item).id(item.id)
                }
                .onDelete { indexSet in deleteItems(indexSet, from: normalItems) }
                .onMove { indices, newOffset in reorderItems(in: normalItems, indices: indices, newOffset: newOffset) }
                
                addItemRow
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Todo Item Row
    @ViewBuilder
    private func todoItemRow(for item: TodoItem) -> some View {
        if let binding = binding(for: item) {
            HStack(spacing: 12) {
                // Checkmark
                Image(systemName: binding.isCompleted.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(binding.isCompleted.wrappedValue ? .green : .secondary)
                    .font(.title3)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            viewModel.toggleItemCompletion(item, in: modelContext)
                        }
                    }
                
                // Editable multiline TextField
                TextField("Task", text: binding.title, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 6)
                    .id(editMode)
                    .contentTransition(.interpolate)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: editMode)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: binding.title.wrappedValue.count)
                
                Spacer()
                
                if binding.isPinned.wrappedValue {
                    Image(systemName: "pin.fill")
                        .foregroundColor(.yellow)
                        .rotationEffect(.degrees(45))
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: binding.isPinned.wrappedValue)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.toggleItemCompletion(item, in: modelContext)
                }
            }
            .swipeActions(edge: .leading) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewModel.togglePin(for: item, in: modelContext)
                    }
                } label: {
                    Label(binding.isPinned.wrappedValue ? "Unpin" : "Pin",
                          systemImage: binding.isPinned.wrappedValue ? "pin.slash" : "pin")
                }
                .tint(.yellow)
            }
        } else {
            HStack {
                Text(item.title)
                Spacer()
            }
            .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Binding Helper
    private func binding(for item: TodoItem) -> (title: Binding<String>, isCompleted: Binding<Bool>, isPinned: Binding<Bool>)? {
        guard let index = todo.items?.firstIndex(where: { $0.id == item.id }) else { return nil }
        guard let items = todo.items else { return nil }
        return (
            title: Binding(
                get: { items[index].title },
                set: { newValue in
                    items[index].title = newValue
                    try? modelContext.save()
                }
            ),
            isCompleted: Binding(
                get: { items[index].isCompleted },
                set: { newValue in
                    items[index].isCompleted = newValue
                    items[index].updatedAt = Date()
                    try? modelContext.save()
                }
            ),
            isPinned: Binding(
                get: { items[index].isPinned },
                set: { newValue in
                    items[index].isPinned = newValue
                    try? modelContext.save()
                }
            )
        )
    }
    
    // MARK: - Add Item Row
    // MARK: - Add New Item Row
    private var addItemRow: some View {
        HStack {
            TextField("New Item", text: $newItemTitle)
                .textFieldStyle(.plain)
                .focused($isNewItemFocused) // 👈 bind focus
                .onSubmit { addNewItem() }  // return adds
                .submitLabel(.done)         // shows "Done" on keyboard
            
            Button {
                addNewItem()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Add New Item Logic
    private func addNewItem() {
        let trimmed = newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            viewModel.addItem(to: todo, title: trimmed, in: modelContext)
            newItemTitle = ""
        }
        // 👇 Keep focus after adding
        DispatchQueue.main.async {
            isNewItemFocused = true
        }
    }
    
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if editMode == .active && !selection.isEmpty {
                Button("Delete") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        let ids = selection
                        selection.removeAll()
                        let itemsToDelete = ids.compactMap { id in
                            (todo.items ?? []).first(where: { $0.id == id })
                        }
                        for it in itemsToDelete {
                            viewModel.deleteItem(it, in: modelContext)
                        }
                    }
                }
            }
            
            if hasCompletedItems {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        hideCompletedItems.toggle()
                    }
                } label: {
                    Image(systemName: hideCompletedItems ? "eye" : "eye.slash")
                }
            }
            
            Button(role: .destructive) {
                dismiss()
                DispatchQueue.main.async {
                    viewModel.removeTodo(todo, in: modelContext)
                }
            } label: {
                Image(systemName: "trash")
            }
        }
    }
    
    // MARK: - Helpers
    private func deleteItems(_ indices: IndexSet, from array: [TodoItem]) {
        let itemsToDelete: [TodoItem] = indices.compactMap { idx in
            guard array.indices.contains(idx) else { return nil }
            return array[idx]
        }
        guard !itemsToDelete.isEmpty else { return }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            for item in itemsToDelete {
                viewModel.deleteItem(item, in: modelContext)
            }
        }
    }
    
    private func reorderItems(in array: [TodoItem], indices: IndexSet, newOffset: Int) {
        guard sortMode == .manual else { return }
        viewModel.reorderItems(
            pinnedItems: pinnedItems,
            normalItems: normalItems,
            movedArray: array,
            indices: indices,
            newOffset: newOffset,
            in: modelContext
        )
    }
}
