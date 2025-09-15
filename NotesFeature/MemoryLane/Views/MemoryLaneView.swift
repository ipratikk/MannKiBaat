//
//  MemoryLaneView.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 16/09/25.
//

import SwiftUI
import SwiftData
import SharedModels
import CoreLocation

@MainActor
public struct MemoryLaneView: View {
    @Bindable var lane: MemoryLane
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: MemoryViewModel
    
    // pagination (lazy load)
    @State private var pageSize: Int = 20
    
    // editing sheet
    @State private var editingItem: MemoryItem?
    
    public init(lane: MemoryLane, viewModel: MemoryViewModel) {
        self._lane = Bindable(lane)
        self.viewModel = viewModel
    }
    
    private var sortedItems: [MemoryItem] {
        (lane.items ?? []).sorted { $0.createdAt > $1.createdAt }
    }
    
    private var pagedItems: [MemoryItem] {
        Array(sortedItems.prefix(pageSize))
    }
    
    public var body: some View {
        ZStack {
            GradientBackgroundView()
            
            ScrollView {
                ZStack(alignment: .top) {
                    // central timeline line
                    GeometryReader { geo in
                        VStack {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    }
                    
                    LazyVStack(spacing: 22) {
                        ForEach(Array(pagedItems.enumerated()), id: \.element.id) { (index, item) in
                            timelineRow(for: item, at: index)
                                .id(item.id)
                                .onAppear {
                                    // load more when last visible
                                    if index == pagedItems.count - 1 {
                                        withAnimation { pageSize += 20 }
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal)
                }
            }
            .refreshable {
                await viewModel.refresh(modelContext)
            }
            .navigationTitle(lane.title.isEmpty ? "Lane" : lane.title)
            .toolbar { toolbarContent } // ✅ fixed
            .sheet(item: $editingItem) { item in
                MemoryItemEditView(item: item, lane: lane, viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                Task {
                    let new = await viewModel.addItem(
                        to: lane,
                        title: "",
                        in: modelContext
                    )
                    // start editing the newly created item
                    editingItem = new
                }
            } label: {
                Image(systemName: "plus")
            }
        }
    }
    
    // MARK: - Row
    @ViewBuilder
    private func timelineRow(for item: MemoryItem, at index: Int) -> some View {
        HStack(spacing: 0) {
            if index.isMultiple(of: 2) {
                rowContent(item: item)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                Spacer().frame(maxWidth: .infinity)
            }
            
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 2)
                    .frame(height: 12)
                
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                        .shadow(radius: 1)
                    Circle()
                        .stroke(Color.secondary.opacity(0.6), lineWidth: 2)
                        .frame(width: 20, height: 20)
                }
                .padding(.vertical, 4)
                
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 2)
                    .frame(height: 12)
            }
            .frame(width: 44)
            .padding(.horizontal, 8)
            
            if index.isMultiple(of: 2) {
                Spacer().frame(maxWidth: .infinity)
            } else {
                rowContent(item: item)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onTapGesture {
            editingItem = item
        }
    }
    
    // MARK: - Card for item (compact)
    @ViewBuilder
    private func rowContent(item: MemoryItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if let data = item.imageData, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .clipped()
            }
            
            VStack(alignment: .leading, spacing: 6) {
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
            .background(Color(.systemBackground).opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary.opacity(0.08), lineWidth: 1)
            )
        }
        .frame(maxWidth: 320, alignment: .leading)
    }
}
