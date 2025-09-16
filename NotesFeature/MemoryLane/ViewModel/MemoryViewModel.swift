import Combine
import SwiftUI
import SwiftData
import SharedModels

@MainActor
public class MemoryViewModel: ObservableObject {
    @Published public var searchText: String = ""
    
    public init() {}
    
    // MARK: - Filtering
    public func filteredLanes(from lanes: [MemoryLane]) -> [MemoryLane] {
        guard !searchText.isEmpty else { return lanes }
        let query = searchText.lowercased()
        return lanes.filter { lane in
            lane.title.lowercased().contains(query) ||
            (lane.items?.contains {
                $0.title.lowercased().contains(query) ||
                $0.details.lowercased().contains(query)
            } ?? false)
        }
    }
    
    // MARK: - CRUD (MemoryLane)
    @discardableResult
    public func addLane(title: String, in context: ModelContext) -> MemoryLane {
        let lane = MemoryLane(title: title)
        context.insert(lane)
        try? context.save()
        return lane
    }
    
    public func removeLane(_ lane: MemoryLane, in context: ModelContext) {
        context.delete(lane)
        try? context.save()
    }
    
    // MARK: - CRUD (MemoryItem)
    @discardableResult
    public func addItem(
        to lane: MemoryLane,
        title: String,
        details: String = "",
        date: Date = Date(),
        imageDatas: [Data] = [],
        coordinate: (lat: Double, lon: Double)? = nil,
        in context: ModelContext
    ) -> MemoryItem {
        let item = MemoryItem(
            title: title,
            details: details,
            createdAt: date,
            imageDatas: imageDatas,
            latitude: coordinate?.lat,
            longitude: coordinate?.lon,
            parent: lane
        )
        lane.items?.append(item)
        context.insert(item)
        try? context.save()
        return item
    }
    
    public func updateItem(_ item: MemoryItem, in context: ModelContext) {
        try? context.save()
    }
    
    public func removeItem(_ item: MemoryItem, in context: ModelContext) {
        context.delete(item)
        try? context.save()
    }
    
    // MARK: - Refresh
    public func refresh(_ context: ModelContext) async {
        try? context.save()
    }
}

extension MemoryViewModel {
    public func itemCount(for lane: MemoryLane) -> Int {
        lane.items?.count ?? 0
    }
    
    public func lastUpdatedDate(for lane: MemoryLane) -> Date? {
        guard let items = lane.items, !items.isEmpty else {
            return lane.createdAt
        }
        return items.map { $0.createdAt }.max()
    }
}
