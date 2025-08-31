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
    @FocusState private var titleFocused: Bool
    
    // Non-optional binding for list
    private var itemsBinding: Binding<[TodoItem]> {
        Binding<[TodoItem]>(
            get: { todo.items ?? [] },
            set: { todo.items = $0 }
        )
    }
    
    public init(todo: TodoObject) {
        self._todo = Bindable(todo)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                TextField("New Todo", text: $todo.title)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.primary)
                    .focused($titleFocused)
                    .onSubmit {
                        if todo.title.trimmingCharacters(in: .whitespaces).isEmpty {
                            todo.title = "New Todo"
                        }
                        try? modelContext.save()
                    }
            }
            .padding(.horizontal)
            .padding(.top)
            
            List {
                ForEach(itemsBinding, id: \.id) { $item in
                    HStack {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            .onTapGesture {
                                item.isCompleted.toggle()
                                try? modelContext.save()
                            }
                        Text(item.title)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        if let item = todo.items?[index] {
                            modelContext.delete(item)
                        }
                    }
                    try? modelContext.save()
                }
            }
            
            HStack {
                TextField("New Task", text: $newItemTitle)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.secondary.opacity(0.5), lineWidth: 1)
                    )
                
                Button(action: {
                    let trimmed = newItemTitle.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    
                    let newItem = TodoItem(title: trimmed)
                    modelContext.insert(newItem)
                    if todo.items == nil { todo.items = [] }
                    todo.items?.append(newItem)
                    
                    try? modelContext.save()
                    newItemTitle = ""
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.buttonBackground)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)

        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if todo.title.isEmpty {
                titleFocused = true
            }
        }
    }
}
