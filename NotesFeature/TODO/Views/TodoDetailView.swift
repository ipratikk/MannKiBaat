import SwiftUI
import SharedModels
import SwiftData

@MainActor
public struct TodoDetailView: View {
    @Bindable var todo: TodoObject
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TodosViewModel
    
    // MARK: - Focus & State
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isNewItemFocused: Bool
    @State private var newItemTitle: String = ""
    @State private var hideCompletedItems: Bool = true
    @State private var editMode: EditMode = .inactive
    @State private var selection = Set<UUID>()
    
    // MARK: - Sort Mode
    private enum SortMode: String, CaseIterable {
        case `default` = "Default"
        case manual = "Manual"
        case date = "Date"
    }
    @State private var sortMode: SortMode = .default
    
    public init(todo: TodoObject, viewModel: TodosViewModel) {
        self._todo = Bindable(todo)
        self.viewModel = viewModel
    }
    
    // MARK: - Flags
    private var completedCount: Int {
        todo.items?.filter { $0.isCompleted }.count ?? 0
    }
    private var totalCount: Int {
        todo.items?.count ?? 0
    }
    private var hasCompletedItems: Bool {
        completedCount > 0
    }
    
    private var pinnedItems: [TodoItem] {
        filtered(todo.items?.filter { $0.isPinned } ?? [])
    }
    private var normalItems: [TodoItem] {
        filtered(todo.items?.filter { !$0.isPinned } ?? [])
    }
    
    private func filtered(_ arr: [TodoItem]) -> [TodoItem] {
        let items = arr.filter { hideCompletedItems ? !$0.isCompleted : true }
        switch sortMode {
        case .default:
            return items.sorted {
                if $0.isCompleted != $1.isCompleted {
                    return !$0.isCompleted && $1.isCompleted
                }
                return $0.createdAt > $1.createdAt
            }
        case .manual:
            return items.sorted { $0.orderIndex < $1.orderIndex }
        case .date:
            return items.sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    // MARK: - Body
    public var body: some View {
        ZStack {
            GradientBackgroundView()
            VStack(spacing: 0) {
                titleField
                itemsList
            }
            .globalDoneToolbar()
            .toolbar { toolbarContent }
            .onAppear { if todo.title.isEmpty { isTitleFocused = true } }
            .onDisappear { viewModel.saveOrFixTitle(for: todo, in: modelContext) }
        }
        .environment(\.editMode, $editMode)
    }
    
    // MARK: - Title + Status Badge
    private var titleField: some View {
        HStack(alignment: .center, spacing: 12) {
            TextField("Todo Title", text: $todo.title)
                .font(.largeTitle.bold())
                .focused($isTitleFocused)
                .textFieldStyle(.plain)
            
            Spacer()
            
            if totalCount > 0 {
                Button {
                    withAnimation(.spring) {
                        hideCompletedItems.toggle()
                    }
                } label: {
                    ZStack {
                        // Background ring
                        Circle()
                            .stroke(lineWidth: 4)
                            .opacity(0.2)
                            .foregroundColor(hideCompletedItems ? .gray : .accentColor)
                        
                        // Progress ring
                        Circle()
                            .trim(from: 0.0, to: CGFloat(completedCount) / CGFloat(totalCount))
                            .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .foregroundColor(hideCompletedItems ? .gray : .accentColor)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut, value: completedCount)
                        
                        // Percentage text
                        Text("\(Int((Double(completedCount) / Double(totalCount)) * 100))%")
                            .font(.caption2.bold())
                            .foregroundColor(hideCompletedItems ? .gray : .accentColor)
                    }
                    .frame(width: 34, height: 34)
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(hideCompletedItems ? "Show completed tasks" : "Hide completed tasks")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Items List
    private var itemsList: some View {
        List(selection: $selection) {
            if !pinnedItems.isEmpty {
                Section(header: Text("Pinned")) {
                    ForEach(pinnedItems, id: \.id) { item in
                        todoItemRow(for: item).id(item.id)
                    }
                    .onDelete { deleteItems($0, from: pinnedItems) }
                    .onMove { reorderItems(in: pinnedItems, indices: $0, newOffset: $1) }
                }
            }
            
            Section {
                ForEach(normalItems, id: \.id) { item in
                    todoItemRow(for: item).id(item.id)
                }
                .onDelete { deleteItems($0, from: normalItems) }
                .onMove { reorderItems(in: normalItems, indices: $0, newOffset: $1) }
                addItemRow
            } header: {
                Spacer(minLength: 0)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Todo Row
    @ViewBuilder
    private func todoItemRow(for item: TodoItem) -> some View {
        if let binding = binding(for: item) {
            HStack(spacing: 12) {
                Image(systemName: binding.isCompleted.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(binding.isCompleted.wrappedValue ? .green : .secondary)
                    .font(.body)
                    .onTapGesture {
                        withAnimation(.spring) {
                            viewModel.toggleItemCompletion(item, in: modelContext)
                        }
                    }
                
                TextField("Task", text: binding.title, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.body)
                    .strikethrough(binding.isCompleted.wrappedValue, color: .secondary)
                    .foregroundColor(binding.isCompleted.wrappedValue ? .secondary : .primary)
                    .id(editMode)
                    .contentTransition(.interpolate)
                    .animation(.spring, value: editMode)
                
                Spacer()
                
                if binding.isPinned.wrappedValue {
                    Image(systemName: "pin.fill")
                        .foregroundColor(.yellow)
                        .rotationEffect(.degrees(45))
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring, value: binding.isPinned.wrappedValue)
                }
            }
            .padding(.vertical, 2)
            .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring) {
                    viewModel.toggleItemCompletion(item, in: modelContext)
                }
            }
            .swipeActions(edge: .leading) {
                Button {
                    withAnimation(.spring) {
                        viewModel.togglePin(for: item, in: modelContext)
                    }
                } label: {
                    Label(binding.isPinned.wrappedValue ? "Unpin" : "Pin",
                          systemImage: binding.isPinned.wrappedValue ? "pin.slash" : "pin")
                }
                .tint(.yellow)
            }
        }
    }
    
    // MARK: - Binding Helper
    private func binding(for item: TodoItem) -> (title: Binding<String>, isCompleted: Binding<Bool>, isPinned: Binding<Bool>)? {
        guard let index = todo.items?.firstIndex(where: { $0.id == item.id }),
              let items = todo.items else { return nil }
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
    private var addItemRow: some View {
        HStack(spacing: 8) {
            TextField("New Item", text: $newItemTitle)
                .textFieldStyle(.plain)
                .font(.body)
                .focused($isNewItemFocused)
                .onSubmit { addNewItem() }
                .submitLabel(.return)
            
            Button { addNewItem() } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accentColor)
                    .font(.body)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
        .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
    }
    
    private func addNewItem() {
        let trimmed = newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        withAnimation(.spring) {
            viewModel.addItem(to: todo, title: trimmed, in: modelContext)
            newItemTitle = ""
        }
        DispatchQueue.main.async { isNewItemFocused = true }
    }
    
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if editMode == .active {
                Button {
                    withAnimation(.spring) { editMode = .inactive }
                } label: { Image(systemName: "checkmark.circle.fill") }
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Menu {
                    Picker(selection: $sortMode) {
                        ForEach(SortMode.allCases, id: \.self) { mode in
                            Label(mode.rawValue, systemImage: sortIcon(for: mode))
                                .tag(mode)
                        }
                    } label: { EmptyView() }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
                
                Button {
                    withAnimation(.spring) { editMode = .active }
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                
                if hasCompletedItems {
                    Button {
                        withAnimation(.spring) { hideCompletedItems.toggle() }
                    } label: {
                        Label(hideCompletedItems ? "Show Completed" : "Hide Completed",
                              systemImage: hideCompletedItems ? "eye" : "eye.slash")
                    }
                }
                
                Button(role: .destructive) {
                    dismiss()
                    DispatchQueue.main.async {
                        viewModel.removeTodo(todo, in: modelContext)
                    }
                } label: {
                    Label("Delete Todo", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
    
    private func sortIcon(for mode: SortMode) -> String {
        switch mode {
        case .default: return "line.3.horizontal.decrease.circle"
        case .manual: return "arrow.up.arrow.down.circle"
        case .date: return "calendar"
        }
    }
    
    // MARK: - Helpers
    private func deleteItems(_ indices: IndexSet, from array: [TodoItem]) {
        let itemsToDelete: [TodoItem] = indices.compactMap { idx in
            guard array.indices.contains(idx) else { return nil }
            return array[idx]
        }
        withAnimation(.spring) {
            for item in itemsToDelete { viewModel.deleteItem(item, in: modelContext) }
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
