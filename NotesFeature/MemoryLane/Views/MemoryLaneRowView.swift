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
                
                Text(viewModel.formattedDateString(for: lane))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if itemCount > 0 {
                Text("\(itemCount)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.buttonBackground.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
        }
        .padding(.vertical, 6)
        .contextMenu {
            Button { onEdit(lane) } label: { Label("Edit", systemImage: "pencil") }
            Button(role: .destructive) { onDelete(lane) } label: { Label("Delete", systemImage: "trash") }
        }
    }
}
