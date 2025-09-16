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
    @State private var showEditor = false
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
        return grouped
            .map { (marker: $0.key, items: $0.value) }
            .sorted { ($0.items.first?.createdAt ?? .distantPast) > ($1.items.first?.createdAt ?? .distantPast) }
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            GradientBackgroundView()
            
            ScrollView {
                ZStack(alignment: .topLeading) {
                    // Continuous vertical line (rail)
                    Rectangle()
                        .fill(Color.secondary.opacity(0.25))
                        .frame(width: 2)
                        .padding(.leading, 20)
                        .frame(maxHeight: .infinity)
                    
                    LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
                        ForEach(groupedItems, id: \.marker) { section in
                            Section {
                                ForEach(Array(section.items.prefix(pageSize).enumerated()), id: \.element.id) { (_, item) in
                                    TimelineRow(item: item)
                                        .onTapGesture {
                                            editingItem = item
                                            showEditor = true
                                        }
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
            .refreshable { await viewModel.refresh(modelContext) }
            .navigationTitle(lane.title.isEmpty ? "Lane" : lane.title)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // 👇 Just open editor with a draft
                        editingItem = nil
                        showEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                MemoryItemEditView(
                    item: editingItem, // pass if editing existing
                    lane: lane,
                    viewModel: viewModel
                )
            }
        }
    }
}

// MARK: - Timeline Row
fileprivate struct TimelineRow: View {
    let item: MemoryItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle().stroke(Color.secondary.opacity(0.6), lineWidth: 2)
                    )
                    .shadow(radius: 1)
            }
            .frame(width: 12)
            
            MemoryCard(item: item)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

// MARK: - Memory Card
fileprivate struct MemoryCard: View {
    let item: MemoryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let data = item.imageData, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 180)
                    .clipped()
                    .cornerRadius(12)
            }
            
            if !item.title.isEmpty {
                Text(item.title)
                    .font(.headline)
            }
            
            if !item.details.isEmpty {
                Text(item.details)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Text(item.createdAt, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground).opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
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
