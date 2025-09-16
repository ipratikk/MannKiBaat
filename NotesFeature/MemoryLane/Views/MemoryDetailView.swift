import SwiftUI
import SharedModels

public struct MemoryDetailView: View {
    let item: MemoryItem
    @Environment(\.dismiss) private var dismiss
    
    public init(item: MemoryItem) {
        self.item = item
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    
                    // --- Image Carousel ---
                    if !item.imageDatas.isEmpty {
                        TabView {
                            ForEach(Array(item.imageDatas.enumerated()), id: \.offset) { _, data in
                                if let ui = UIImage(data: data) {
                                    Image(uiImage: ui)
                                        .resizable()
                                        .scaledToFit()
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                        .frame(height: UIScreen.main.bounds.width) // 1:1 aspect ratio
                    }
                    
                    // --- Title & Details ---
                    VStack(alignment: .leading, spacing: 12) {
                        if !item.title.isEmpty {
                            Text(item.title)
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                        }
                        
                        if !item.details.isEmpty {
                            Text(item.details)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Text(item.createdAt, style: .date)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
