//
//  TodoDetailView.swift
//

import SwiftUI
import SharedModels
import SwiftData

public struct TodoDetailView: View {
    @Bindable var todo: TodoObject
    @Environment(\.modelContext) private var modelContext
    
    @State private var newItemTitle: String = ""
    @FocusState private var isTitleFocused: Bool
    
    public init(todo: TodoObject) {
        self._todo = Bindable(todo)
    }
    
    // Sorted items: incomplete first, completed last (by completion date if available)
    private var sortedItems: [TodoItem] {
        let items = todo.items ?? []
        return items.sorted { lhs, rhs in
            switch (lhs.isCompleted, rhs.isCompleted) {
            case (false, true): return true
            case (true, false): return false
            case (_, _): return lhs.createdAt < rhs.createdAt
            }
        }
    }
    
    // Helper to create a binding for each TodoItem
    private func binding(for item: TodoItem) -> Binding<TodoItem>? {
        guard let index = todo.items?.firstIndex(where: { $0.id == item.id }) else { return nil }
        return Binding(
            get: { todo.items![index] },
            set: { updated in
                todo.items![index] = updated
                try? modelContext.save()
            }
        )
    }
    
    public var body: some View {
        VStack {
            // Editable title for Todo
            TextField("New Todo", text: $todo.title)
                .font(.largeTitle.bold())
                .padding(.horizontal)
                .padding(.top)
                .textFieldStyle(.plain)
                .focused($isTitleFocused)
                .onAppear {
                    if todo.title.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isTitleFocused = true
                        }
                    }
                }
            
            // List of TodoItems and new task input
            List {
                ForEach(sortedItems, id: \.id) { item in
                    if let itemBinding = binding(for: item) {
                        HStack {
                            Button {
                                withAnimation {
                                    itemBinding.wrappedValue.isCompleted.toggle()
                                    try? modelContext.save()
                                }
                            } label: {
                                Image(systemName: itemBinding.wrappedValue.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(itemBinding.wrappedValue.isCompleted ? .green : .secondary)
                            }
                            
                            ZStack(alignment: .leading) {
                                Text(itemBinding.wrappedValue.title)
                                    .font(.body)
                                    .padding(8)
                                    .opacity(0)
                                    .background(
                                        GeometryReader { geo in
                                            Color.clear.preference(key: ViewHeightKey.self, value: geo.size.height)
                                        }
                                    )
                                
                                TextEditor(text: Binding(
                                    get: { itemBinding.wrappedValue.title },
                                    set: { itemBinding.wrappedValue.title = $0; try? modelContext.save() }
                                ))
                                .frame(minHeight: 40)
                            }
                            .onPreferenceChange(ViewHeightKey.self) { height in
                                if height > 40 {
                                    // no explicit action needed here, frame is minHeight:40 so it expands
                                }
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    withAnimation {
                        for idx in indexSet {
                            if let item = todo.items?[idx] {
                                modelContext.delete(item)
                            }
                        }
                        try? modelContext.save()
                    }
                }
                .onMove { from, to in
                    withAnimation {
                        todo.items?.move(fromOffsets: from, toOffset: to)
                        try? modelContext.save()
                    }
                }
                
                // New task input at the bottom
                HStack {
                    TextField("New Task", text: $newItemTitle)
                        .textFieldStyle(.plain)
                    
                    Button(action: addNewItem) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                    .disabled(newItemTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Add new task
    private func addNewItem() {
        let trimmed = newItemTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        withAnimation {
            let newItem = TodoItem(title: trimmed)
            if todo.items == nil { todo.items = [] }
            todo.items?.append(newItem)
            try? modelContext.save()
            newItemTitle = ""
        }
    }
}

private struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
