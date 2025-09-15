//
//  MemoryLaneView.swift
//  MannKiBaat
//

import SwiftUI
import SwiftData
import SharedModels

@MainActor
public struct MemoryLaneView: View {
    @Bindable var lane: MemoryLane
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: MemoryViewModel
    
    @State private var pageSize: Int = 20
    @State private var editingItem: MemoryItem?
    
    public init(lane: MemoryLane, viewModel: MemoryViewModel) {
        self._lane = Bindable(lane)
        self.viewModel = viewModel
    }
    
    // MARK: - Grouped items
    private var groupedItems: [(marker: String, items: [MemoryItem])] {
        let allItems = (lane.items ?? []).sorted { $0.createdAt > $1.createdAt }
        let grouped = Dictionary(grouping: allItems) { item in
            let cal = Calendar.current
            if cal.isDateInToday(item.createdAt) { return "Today" }
            if cal.isDateInYesterday(item.createdAt) { return "Yesterday" }
            return item.createdAt.dayMonthYearString()
        }
        return grouped.map { (marker: $0.key, items: $0.value) }
            .sorted { ($0.items.first?.createdAt ?? .distantPast) > ($1.items.first?.createdAt ?? .distantPast) }
    }
    
    public var body: some View {
        ZStack {
            GradientBackgroundView()
            
            ScrollView {
                ZStack(alignment: .top) {
                    // Continuous central timeline
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 2)
                            .frame(maxHeight: .infinity)
                            .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    }
                    
                    LazyVStack(spacing: 32, pinnedViews: [.sectionHeaders]) {
                        ForEach(groupedItems, id: \.marker) { section in
                            Section {
                                ForEach(Array(section.items.prefix(pageSize).enumerated()), id: \.element.id) { (index, item) in
                                    TimelineRow(item: item, index: index)
                                        .onTapGesture { editingItem = item }
                                        .onAppear {
                                            if index == section.items.count - 1 &&
                                                pageSize < (lane.items?.count ?? 0) {
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
            .refreshable { await viewModel.refresh(modelContext) }
            .navigationTitle(lane.title.isEmpty ? "Lane" : lane.title)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        let new = viewModel.addItem(to: lane, title: "", in: modelContext)
                        editingItem = new
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $editingItem) { item in
                MemoryItemEditView(item: item, lane: lane, viewModel: viewModel)
            }
        }
    }
}

// MARK: - Timeline Row
fileprivate struct TimelineRow: View {
    let item: MemoryItem
    let index: Int
    
    var body: some View {
        HStack(spacing: 0) {
            if index.isMultiple(of: 2) {
                MemoryCard(item: item)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                Spacer().frame(maxWidth: .infinity)
            }
            
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .shadow(radius: 1)
                    .overlay(
                        Circle()
                            .stroke(Color.secondary.opacity(0.6), lineWidth: 2)
                    )
            }
            .frame(width: 44)
            .padding(.horizontal, 8)
            
            if index.isMultiple(of: 2) {
                Spacer().frame(maxWidth: .infinity)
            } else {
                MemoryCard(item: item)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

// MARK: - Memory Card
fileprivate struct MemoryCard: View {
    let item: MemoryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let data = item.imageData, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .clipped()
            }
            
            if !item.title.isEmpty {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)
            }
            
            if !item.details.isEmpty {
                Text(item.details)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            Text(item.createdAt, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.systemBackground).opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 2)
        .frame(maxWidth: 280, alignment: .leading)
    }
}

// MARK: - Marker Header
fileprivate struct MarkerHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Spacer()
            Text(title)
                .font(.footnote.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemBackground).opacity(0.9))
                .clipShape(Capsule())
                .shadow(radius: 1)
            Spacer()
        }
        .padding(.bottom, 8)
    }
}
