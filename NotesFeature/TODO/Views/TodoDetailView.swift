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
    
    public init(todo: TodoObject, viewModel: TodosViewModel) {
        self._todo = Bindable(todo)
        self.viewModel = viewModel
    }
    
    // MARK: - Flags
    private var hasCompletedItems: Bool {
        (todo.items ?? []).contains { $0.isCompleted }
    }
    
    // MARK: - Sections (filtered views)
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
            .onDisappear { saveOrFixTitle() }
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
            
            // Sort button as circular menu
            Menu {
                ForEach(SortMode.allCases, id: \.self) { mode in
                    Button(mode.rawValue) {
                        sortMode = mode
                    }
                }
            } label: {
                CircleIconButton(systemName: "arrow.up.arrow.down")
            }
            
            // Edit toggle as circular icon (keeps edit mode behavior)
            Button {
                withAnimation {
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
                        // we pass the item and build a binding to the actual location in todo.items
                        todoItemRow(boundTo: item)
                            .id(item.id)
                    }
                    .onDelete { indexSet in deleteItems(indexSet, from: pinnedItems) }
                    .onMove { indices, newOffset in reorderItems(in: pinnedItems, indices: indices, newOffset: newOffset) }
                }
            }
            
            Section {
                ForEach(normalItems, id: \.id) { item in
                    todoItemRow(boundTo: item)
                        .id(item.id)
                }
                .onDelete { indexSet in deleteItems(indexSet, from: normalItems) }
                .onMove { indices, newOffset in reorderItems(in: normalItems, indices: indices, newOffset: newOffset) }
                
                addItemRow
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Row that binds into todo.items so editing works
    @ViewBuilder
    private func todoItemRow(boundTo item: TodoItem) -> some View {
        // Find item index in the original todo.items array
        if let idx = todo.items?.firstIndex(where: { $0.id == item.id }) {
            // Create bindings to the model's properties
            let titleBinding = Binding<String>(
                get: { todo.items?[idx].title ?? "" },
                set: { newValue in
                    // Update the model directly, then save
                    todo.items?[idx].title = newValue
                    try? modelContext.save()
                }
            )
            
            // Build the row UI
            HStack(alignment: .top) {
                // Completion toggle
                Button {
                    withAnimation {
                        viewModel.toggleItemCompletion(item, in: modelContext)
                    }
                } label: {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(item.isCompleted ? .green : .secondary)
                }
                .padding(.trailing, 8)
                .buttonStyle(.plain)
                
                // Editable multiline TextField bound to the model
                TextField("Task", text: titleBinding, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 6)
                
                Spacer()
                
                if item.isPinned {
                    Image(systemName: "pin.fill")
                        .foregroundColor(.yellow)
                        .rotationEffect(.degrees(45))
                }
            }
            .padding(.vertical, 6)
            .swipeActions(edge: .leading) {
                Button {
                    withAnimation {
                        viewModel.togglePin(for: item, in: modelContext)
                    }
                } label: {
                    Label(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash" : "pin")
                }
                .tint(.yellow)
            }
        } else {
            // Fallback: the item isn't present in todo.items (defensive)
            HStack {
                Text(item.title)
                Spacer()
            }
            .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Add New Item Row
    private var addItemRow: some View {
        HStack {
            TextField("New Item", text: $newItemTitle, axis: .vertical)
                .lineLimit(1...)
                .textFieldStyle(.plain)
            
            Button {
                let trimmed = newItemTitle.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                viewModel.addItem(to: todo, title: trimmed, in: modelContext)
                newItemTitle = ""
            } label: {
                Image(systemName: "plus.circle.fill").foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if editMode == .active && !selection.isEmpty {
                Button("Delete") {
                    withAnimation {
                        // snapshot selection -> resolve items -> delete safely
                        let ids = selection
                        selection.removeAll()
                        let itemsToDelete = ids.compactMap { id in (todo.items ?? []).first(where: { $0.id == id }) }
                        for it in itemsToDelete { viewModel.deleteItem(it, in: modelContext) }
                    }
                }
            }
            
            if hasCompletedItems {
                Button {
                    withAnimation { hideCompletedItems.toggle() }
                } label: {
                    Image(systemName: hideCompletedItems ? "eye" : "eye.slash")
                }
            }
            
            Button(role: .destructive) {
                // dismiss first to avoid deleting a bound model while the view is presented
                dismiss()
                DispatchQueue.main.async {
                    viewModel.removeTodo(todo, in: modelContext)
                }
            } label: { Image(systemName: "trash") }
        }
    }
    
    // MARK: - Helpers
    private func deleteItems(_ indices: IndexSet, from array: [TodoItem]) {
        // Snapshot the items to delete to avoid mutating while computed arrays are used by List
        let itemsToDelete: [TodoItem] = indices.compactMap { idx in
            guard array.indices.contains(idx) else { return nil }
            return array[idx]
        }
        guard !itemsToDelete.isEmpty else { return }
        
        withAnimation {
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
    
    private func saveOrFixTitle() {
        if todo.title.trimmingCharacters(in: .whitespaces).isEmpty {
            todo.title = "New Todo"
        }
        try? modelContext.save()
    }
}
