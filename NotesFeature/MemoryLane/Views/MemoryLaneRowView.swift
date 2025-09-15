import SwiftUI
import SharedModels

public struct MemoryLaneRowView: View {
    let lane: MemoryLane
    @ObservedObject var viewModel: MemoryViewModel
    let onEdit: (MemoryLane) -> Void
    let onDelete: (MemoryLane) -> Void
    
    public init(
        lane: MemoryLane,
        viewModel: MemoryViewModel,
        onEdit: @escaping (MemoryLane) -> Void,
        onDelete: @escaping (MemoryLane) -> Void
    ) {
        self.lane = lane
        self.viewModel = viewModel
        self.onEdit = onEdit
        self.onDelete = onDelete
    }
    
    private var itemCount: Int { viewModel.itemCount(for: lane) }
    private var lastDate: Date { viewModel.lastUpdatedDate(for: lane) ?? lane.createdAt }
    
    public var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(lane.title.isEmpty ? "Untitled Lane" : lane.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(lastDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if itemCount > 0 {
                ZStack {
                    Circle()
                        .stroke(lineWidth: 2)
                        .frame(width: 36, height: 36)
                        .foregroundColor(.secondary.opacity(0.6))
                    
                    Text("\(itemCount)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
        .contextMenu {
            Button {
                onEdit(lane)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                onDelete(lane)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
