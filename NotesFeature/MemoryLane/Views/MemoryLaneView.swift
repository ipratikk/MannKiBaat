import SwiftUI
import SwiftData
import SharedModels

@MainActor
public struct MemoryLaneView: View {
    @Bindable var lane: MemoryLane
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: MemoryViewModel
    
    @State private var pageSize: Int = 20
    @State private var showNewEditor = false
    @State private var editingItem: MemoryItem? = nil
    @State private var viewingItem: MemoryItem? = nil
    
    @FocusState private var isTitleFocused: Bool
    @State private var showDeleteLaneAlert = false
    
    private let isNew: Bool
    
    public init(lane: MemoryLane, viewModel: MemoryViewModel, isNew: Bool = false) {
        self._lane = Bindable(lane)
        self.viewModel = viewModel
        self.isNew = isNew
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
            
            VStack {
                // --- Editable Title ---
                TextField("Lane Title", text: $lane.title)
                    .font(.title2.bold())
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .focused($isTitleFocused)
                
                if (lane.items ?? []).isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No memories yet. Add your first!")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                } else {
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
                                                    checkForLaneDeletion()
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
            }
        }
        .refreshable { await viewModel.refresh(modelContext) }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showNewEditor = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            if isNew {
                // Focus title field immediately for new lanes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTitleFocused = true
                }
            }
        }
        .onDisappear {
            handleOnDisappear()
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
        // DELETE lane confirmation
        .alert("Delete Lane?", isPresented: $showDeleteLaneAlert) {
            Button("Delete", role: .destructive) {
                modelContext.delete(lane)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This lane has no items. Do you want to delete it?")
        }
    }
    
    // MARK: - Helpers
    private func handleOnDisappear() {
        let hasTitle = !lane.title.trimmingCharacters(in: .whitespaces).isEmpty
        let hasItems = !(lane.items?.isEmpty ?? true)
        
        if isNew {
            // New lane → if empty, remove it
            if !hasTitle && !hasItems {
                modelContext.delete(lane)
                try? modelContext.save()
            }
        } else {
            // Existing lane → if no items left, ask user
            if !hasItems {
                showDeleteLaneAlert = true
            }
        }
    }
    
    private func checkForLaneDeletion() {
        if (lane.items?.isEmpty ?? true) {
            showDeleteLaneAlert = true
        }
    }
}
