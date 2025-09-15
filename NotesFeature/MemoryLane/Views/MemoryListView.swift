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
                } else {
                    List {
                        ForEach(lanes) { lane in
                            NavigationLink(value: lane) {
                                MemoryLaneRowView(lane: lane, viewModel: viewModel)
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                        .onDelete { indexSet in
                            Task {
                                for idx in indexSet {
                                    guard lanes.indices.contains(idx) else { continue }
                                    await viewModel.removeLane(lanes[idx], in: modelContext)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        await viewModel.refresh(modelContext)
                    }
                }
                
                // + overlay
                plusButtonOverlay
            }
            .navigationDestination(for: MemoryLane.self) { lane in
                MemoryLaneView(lane: lane, viewModel: viewModel)
            }
            .navigationTitle("Memory Lane")
        }
    }
    
    private var plusButtonOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    Task {
                        let lane = viewModel.addLane(title: "New Lane", in: modelContext)
                        // navigate into the new lane
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
                }
                .padding()
            }
        }
    }
}
