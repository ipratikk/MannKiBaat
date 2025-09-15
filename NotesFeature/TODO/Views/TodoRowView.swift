import SwiftUI
import SharedModels

public struct TodoRowView: View {
    let todo: TodoObject
    @ObservedObject var viewModel: TodosViewModel
    
    public init(todo: TodoObject, viewModel: TodosViewModel) {
        self.todo = todo
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(todo.title).bold().lineLimit(1)
                Spacer()
                Text(viewModel.completedText(for: todo))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
            if !viewModel.itemsPreview(for: todo).isEmpty {
                Text(viewModel.itemsPreview(for: todo))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
            Text(viewModel.formattedDateString(for: todo))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .animation(.easeInOut, value: todo.items?.count)
    }
}
