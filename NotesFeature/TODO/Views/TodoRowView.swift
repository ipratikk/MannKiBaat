import SwiftUI
import SharedModels

public struct TodoRowView: View {
    let todo: TodoObject
    @ObservedObject var viewModel: TodosViewModel
    
    public init(todo: TodoObject, viewModel: TodosViewModel) {
        self.todo = todo
        self.viewModel = viewModel
    }
    
    // MARK: - Computed Properties
    private var completedCount: Int {
        todo.items?.filter { $0.isCompleted }.count ?? 0
    }
    private var totalCount: Int {
        todo.items?.count ?? 0
    }
    private var isFullyCompleted: Bool {
        totalCount > 0 && completedCount == totalCount
    }
    private var completionPercentage: Int {
        totalCount > 0 ? Int((Double(completedCount) / Double(totalCount)) * 100) : 0
    }
    private var progressFraction: CGFloat {
        guard totalCount > 0 else { return 0 }
        return CGFloat(Double(completedCount) / Double(totalCount))
    }
    
    // MARK: - Body
    public var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // Left column: title + preview + date
            VStack(alignment: .leading, spacing: 2) {
                Text(todo.title)
                    .font(.body)
                    .bold()
                    .lineLimit(1)
                    .foregroundColor(isFullyCompleted ? .secondary : .primary)
                    .strikethrough(isFullyCompleted, color: .secondary)
                
                if !viewModel.formattedItemsPreview(for: todo).isEmpty {
                    Text(viewModel.formattedItemsPreview(for: todo))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
                
                Text(viewModel.formattedDateString(for: todo))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Trailing badge
            if totalCount > 0 {
                ZStack {
                    Circle()
                        .stroke(lineWidth: 2)
                        .opacity(0.2)
                        .foregroundColor(.secondary)
                    
                    Circle()
                        .trim(from: 0.0, to: progressFraction)
                        .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.25), value: completedCount)
                    
                    Text("\(completionPercentage)%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(width: 34, height: 34)
                .accessibilityLabel("\(completedCount) of \(totalCount) completed")
            }
        }
        .padding(.vertical, 4) // compact vertical padding
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)) // compact insets
        .animation(.easeInOut(duration: 0.25), value: animationTrigger)
    }
    
    // Trigger updates when title, count, or completed count changes
    private var animationTrigger: String {
        let completed = todo.items?.filter { $0.isCompleted }.count ?? 0
        return "\(todo.title)-\(todo.items?.count ?? 0)-\(completed)"
    }
}
