import SwiftUI
import SharedModels

public struct TodoRowView: View {
    let todo: TodoObject
    @ObservedObject var viewModel: TodosViewModel
    
    public init(todo: TodoObject, viewModel: TodosViewModel) {
        self.todo = todo
        self.viewModel = viewModel
    }
    
    private var isFullyCompleted: Bool {
        (todo.items ?? []).allSatisfy { $0.isCompleted }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(todo.title)
                    .bold()
                    .lineLimit(1)
                    .foregroundColor(isFullyCompleted ? .secondary : .primary)
                    .strikethrough(isFullyCompleted, color: .gray)
                
                Spacer()
                
                Text(viewModel.formattedCompletedText(for: todo))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
            
            if !viewModel.formattedItemsPreview(for: todo).isEmpty {
                Text(viewModel.formattedItemsPreview(for: todo))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
            
            Text(viewModel.formattedDateString(for: todo))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
        .animation(.easeInOut(duration: 0.25), value: animationTrigger)
    }
    
    private var animationTrigger: String {
        let completedCount = todo.items?.filter { $0.isCompleted }.count ?? 0
        return "\(todo.title)-\(todo.items?.count ?? 0)-\(completedCount)"
    }
}
