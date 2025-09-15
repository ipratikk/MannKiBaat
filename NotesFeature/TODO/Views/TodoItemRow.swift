import SwiftUI
import SharedModels
import SwiftData

public struct TodoItemRow: View {
    @Binding var item: TodoItem
    let isExpanded: Bool
    let toggleExpanded: () -> Void
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: TodosViewModel
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Button {
                    withAnimation {
                        viewModel.toggleItemCompletion(item, in: modelContext)
                    }
                } label: {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(item.isCompleted ? .green : .secondary)
                }
                
                TextField("Task", text: $item.title)
                    .textFieldStyle(.plain)
                
                Button {
                    withAnimation { toggleExpanded() }
                } label: {
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded, let due = item.dueDate {
                Text("Due: \(due.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 28)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
