import SwiftUI
import SwiftData
import SharedModels

@MainActor
public struct MemoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject var viewModel: MemoryViewModel
    
    @Query(sort: [SortDescriptor(\MemoryLane.createdAt, order: .reverse)]) private var lanes: [MemoryLane]
    
    @State private var path: [LaneWrapper] = []
    
    public init(viewModel: MemoryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                GradientBackgroundView()
                
                if lanes.isEmpty {
                    emptyState
                } else {
                    lanesList
                }
                
                plusButtonOverlay
            }
            .navigationDestination(for: LaneWrapper.self) { wrapper in
                MemoryLaneView(lane: wrapper.lane, viewModel: viewModel, isNew: wrapper.isNew)
            }
            .navigationTitle("Memory Lane")
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No memory lanes yet — start capturing moments.")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    // MARK: - List
    private var lanesList: some View {
        List {
            ForEach(sectionedLanes.keys.sorted(by: DateSectionGrouper.sectionSort), id: \.self) { section in
                Section(header: Text(section).font(.headline)) {
                    lanesSection(for: section)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .listSectionSpacing(.compact)
        .searchable(text: $viewModel.searchText,
                    placement: .navigationBarDrawer(displayMode: .always))
        .refreshable {
            await viewModel.refresh(modelContext)
        }
        .animation(.easeInOut, value: viewModel.searchText)
    }
    
    // MARK: - Section
    @ViewBuilder
    private func lanesSection(for section: String) -> some View {
        let lanesInSection = sectionedLanes[section] ?? []
        
        ForEach(lanesInSection) { lane in
            NavigationLink(value: LaneWrapper(lane: lane, isNew: false)) {
                MemoryLaneRowView(
                    lane: lane,
                    viewModel: viewModel,
                    onEdit: { selectedLane in
                        path.append(LaneWrapper(lane: selectedLane, isNew: false))
                    },
                    onDelete: { selectedLane in
                        withAnimation {
                            viewModel.removeLane(selectedLane, in: modelContext)
                        }
                    }
                )
            }
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        }
        .onDelete { indexSet in
            for idx in indexSet {
                guard lanesInSection.indices.contains(idx) else { continue }
                withAnimation {
                    viewModel.removeLane(lanesInSection[idx], in: modelContext)
                }
            }
        }
    }
    
    // MARK: - Plus Button
    private var plusButtonOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    withAnimation {
                        let lane = viewModel.addLane(title: "", in: modelContext)
                        path.append(LaneWrapper(lane: lane, isNew: true))
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.buttonBackground)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                        .scaleEffect(1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: lanes.count)
                }
                .padding()
            }
        }
    }
    
    // MARK: - Grouped Sections (using DateSectionGrouper)
    private var sectionedLanes: [String: [MemoryLane]] {
        var groups: [String: [MemoryLane]] = [:]
        for lane in viewModel.filteredLanes(from: lanes) {
            let key = DateSectionGrouper.sectionTitle(for: lane.createdAt)
            groups[key, default: []].append(lane)
        }
        return groups
    }
}

// MARK: - LaneWrapper for navigation
struct LaneWrapper: Hashable {
    let lane: MemoryLane
    let isNew: Bool
}
