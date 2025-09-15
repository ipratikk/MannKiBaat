import SwiftUI
import SwiftData
import SharedModels

@MainActor
public struct MemoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: MemoryViewModel
    
    @Query(sort: [SortDescriptor(\MemoryLane.createdAt, order: .reverse)]) private var lanes: [MemoryLane]
    @State private var path: [MemoryLane] = []
    
    public init(viewModel: MemoryViewModel) {
        self.viewModel = viewModel
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
            .navigationDestination(for: MemoryLane.self) { lane in
                MemoryLaneView(lane: lane, viewModel: viewModel)
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
            ForEach(lanes) { lane in
                NavigationLink(value: lane) {
                    MemoryLaneRowView(
                        lane: lane,
                        viewModel: viewModel,
                        onEdit: { selectedLane in
                            // Navigate into detail for editing
                            path.append(selectedLane)
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
                    guard lanes.indices.contains(idx) else { continue }
                    withAnimation {
                        viewModel.removeLane(lanes[idx], in: modelContext)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .refreshable {
            viewModel.refresh(modelContext)
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
                        let lane = viewModel.addLane(title: "New Lane", in: modelContext)
                        path.append(lane)
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
}
