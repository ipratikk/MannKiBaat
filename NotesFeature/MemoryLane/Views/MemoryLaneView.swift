import SwiftUI
import SwiftData
import SharedModels

@MainActor
public struct MemoryLaneView: View {
    @Bindable var lane: MemoryLane
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: MemoryViewModel
    
    @State private var pageSize: Int = 20
    @State private var showNewEditor = false
    @State private var editingItem: MemoryItem? = nil
    @State private var viewingItem: MemoryItem? = nil   // ✅ For View option
    
    public init(lane: MemoryLane, viewModel: MemoryViewModel) {
        self._lane = Bindable(lane)
        self.viewModel = viewModel
    }
    
    private var groupedItems: [(marker: String, items: [MemoryItem])] {
        let allItems = (lane.items ?? []).sorted { $0.createdAt > $1.createdAt }
        let grouped = Dictionary(grouping: allItems) { item in
            let cal = Calendar.current
            if cal.isDateInToday(item.createdAt) { return "Today" }
            if cal.isDateInYesterday(item.createdAt) { return "Yesterday" }
            return item.createdAt.dayMonthYearString()
        }
        return grouped
            .map { (marker: $0.key, items: $0.value) }
            .sorted { ($0.items.first?.createdAt ?? .distantPast) > ($1.items.first?.createdAt ?? .distantPast) }
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            GradientBackgroundView()
            
            ScrollView {
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.25))
                        .frame(width: 2)
                        .padding(.leading, 20)
                        .frame(maxHeight: .infinity)
                    
                    LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
                        ForEach(groupedItems, id: \.marker) { section in
                            Section {
                                ForEach(Array(section.items.prefix(pageSize).enumerated()), id: \.element.id) { (_, item) in
                                    TimelineRow(
                                        item: item,
                                        onEdit: { editingItem = item },
                                        onView: { viewingItem = item },
                                        onDelete: {
                                            modelContext.delete(item)
                                            try? modelContext.save()
                                        }
                                    )
                                    .onAppear {
                                        if pageSize < (lane.items?.count ?? 0) {
                                            withAnimation(.spring()) { pageSize += 20 }
                                        }
                                    }
                                }
                            } header: {
                                MarkerHeader(title: section.marker)
                            }
                        }
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal)
                }
            }
        }
        .refreshable { await viewModel.refresh(modelContext) }
        .navigationTitle(lane.title.isEmpty ? "Lane" : lane.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showNewEditor = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        // EDIT
        .sheet(item: $editingItem) { item in
            MemoryItemEditView(item: item, lane: lane, viewModel: viewModel)
        }
        // VIEW
        .sheet(item: $viewingItem) { item in
            MemoryDetailView(item: item)
        }
        // NEW
        .sheet(isPresented: $showNewEditor) {
            MemoryItemEditView(item: nil, lane: lane, viewModel: viewModel)
        }
    }
}
