import SwiftUI
import SharedModels

struct TimelineRow: View {
    let item: MemoryItem
    let onEdit: () -> Void
    let onView: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 16, height: 16)
                    .overlay(Circle().stroke(Color.secondary.opacity(0.6), lineWidth: 2))
                    .shadow(radius: 1)
            }
            .frame(width: 12)
            
            MemoryCard(item: item)
                .frame(maxWidth: .infinity, alignment: .leading)
            // 👇 Tap opens Detail
                .onTapGesture { onView() }
            // 👇 Long press still gives edit/delete
                .contextMenu {
                    Button { onView() } label: { Label("View", systemImage: "eye") }
                    Button { onEdit() } label: { Label("Edit", systemImage: "pencil") }
                    Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") }
                }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}
