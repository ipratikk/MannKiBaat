//
//  TodoDetailView.swift
//  MannKiBaat
//

import SwiftUI
import SharedModels
import SwiftData

public struct TodoDetailView: View {
    @Bindable var todo: TodoObject
    @Environment(\.modelContext) private var modelContext
    @State private var newItemTitle: String = ""
    @FocusState private var isTitleFocused: Bool
    @ObservedObject var viewModel: TodosViewModel
    
    public init(todo: TodoObject, viewModel: TodosViewModel) {
        self._todo = Bindable(todo)
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack {
            // Editable Todo Title
            TextField("Todo Title", text: $todo.title)
                .font(.largeTitle.bold())
                .padding()
                .focused($isTitleFocused)
            
            List {
                // Ensure items array exists
                let itemsBinding = Binding(
                    get: { todo.items ?? [] },
                    set: { todo.items = $0 }
                )
                
                ForEach(itemsBinding, id: \.id) { $item in
                    HStack {
                        Button {
                            Task {
                                await viewModel.toggleItemCompletion(item, in: modelContext)
                            }
                        } label: {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(item.isCompleted ? .green : .secondary)
                        }
                        
                        TextField("Item", text: $item.title)
                    }
                }
                .onDelete { indexSet in
                    guard var items = todo.items else { return }
                    for i in indexSet.sorted(by: >) {
                        modelContext.delete(items[i])
                        items.remove(at: i)
                    }
                    todo.items = items
                    try? modelContext.save()
                    viewModel.refresh(todo)
                }
                
                // Add New Item Row
                HStack {
                    TextField("New Item", text: $newItemTitle)
                        .focused($isTitleFocused)
                    Button {
                        let trimmedTitle = newItemTitle.trimmingCharacters(in: .whitespaces)
                        guard !trimmedTitle.isEmpty else { return }
                        Task {
                            await viewModel.addItem(to: todo, title: trimmedTitle, in: modelContext)
                            newItemTitle = ""
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                            .font(.title2)
                    }
                }
            }
        }
        .navigationTitle(todo.title.isEmpty ? "New Todo" : todo.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if todo.title.isEmpty {
                isTitleFocused = true
            }
        }
    }
}
