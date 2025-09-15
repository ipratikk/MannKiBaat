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
    }
    
    // MARK: - Control Row
    private var controlRow: some View {
        HStack {
            // Sort Menu
            Spacer()
            Menu {
                ForEach(SortMode.allCases, id: \.self) { mode in
                    Button(mode.rawValue) { sortMode = mode }
                }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
            }
            .labelStyle(.iconOnly)
            
            // Edit Button
            EditButton()
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
                        todoItemRow(item).id(item.id)
                    }
                    .onDelete { indexSet in deleteItems(indexSet, from: pinnedItems) }
                    .onMove { indices, newOffset in reorderItems(in: pinnedItems, indices: indices, newOffset: newOffset) }
                }
            }
            
            Section {
                ForEach(normalItems, id: \.id) { item in
                    todoItemRow(item).id(item.id)
                }
                .onDelete { indexSet in deleteItems(indexSet, from: normalItems) }
                .onMove { indices, newOffset in reorderItems(in: normalItems, indices: indices, newOffset: newOffset) }
                
                addItemRow
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Single Item Row
    private func todoItemRow(_ item: TodoItem) -> some View {
        HStack {
            Button {
                withAnimation { viewModel.toggleItemCompletion(item, in: modelContext) }
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isCompleted ? .green : .secondary)
            }
            .padding(.trailing, 8)
            
            Text(item.title)
                .strikethrough(item.isCompleted, color: .gray)
                .foregroundColor(item.isCompleted ? .secondary : .primary)
            
            Spacer()
            
            if item.isPinned {
                Image(systemName: "pin.fill")
                    .foregroundColor(.yellow)
                    .rotationEffect(.degrees(45))
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                withAnimation {
                    item.isPinned.toggle()
                    try? modelContext.save()
                }
            } label: {
                Label(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash" : "pin")
            }
            .tint(.yellow)
        }
    }
    
    // MARK: - Add New Item Row
    private var addItemRow: some View {
        HStack {
            TextField("New Item", text: $newItemTitle)
            Button {
                let trimmed = newItemTitle.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                viewModel.addItem(to: todo, title: trimmed, in: modelContext)
                newItemTitle = ""
            } label: {
                Image(systemName: "plus.circle.fill").foregroundColor(.accentColor)
            }
        }
    }
    
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if editMode == .active && !selection.isEmpty {
                Button("Delete") {
                    withAnimation {
                        for id in selection {
                            if let item = (todo.items ?? []).first(where: { $0.id == id }) {
                                viewModel.deleteItem(item, in: modelContext)
                            }
                        }
                        selection.removeAll()
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
                viewModel.removeTodo(todo, in: modelContext)
                dismiss()
            } label: { Image(systemName: "trash") }
        }
    }
    
    // MARK: - Helpers
    private func deleteItems(_ indices: IndexSet, from array: [TodoItem]) {
        withAnimation {
            for index in indices {
                viewModel.deleteItem(array[index], in: modelContext)
            }
        }
    }
    
    private func reorderItems(in array: [TodoItem], indices: IndexSet, newOffset: Int) {
        guard sortMode == .manual else { return } // only allow manual reordering
        var updated = array
        updated.move(fromOffsets: indices, toOffset: newOffset)
        for (idx, item) in updated.enumerated() {
            item.orderIndex = idx
        }
        try? modelContext.save()
    }
    
    private func saveOrFixTitle() {
        if todo.title.trimmingCharacters(in: .whitespaces).isEmpty {
            todo.title = "New Todo"
        }
        try? modelContext.save()
    }
}
