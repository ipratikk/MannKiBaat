import SwiftUI
import SharedModels

public struct MemoryDetailView: View {
    let item: MemoryItem
    
    @State private var selectedImageIndex: IdentifiableIndex? = nil
    @State private var currentImageIndex: Int = 0
    
    public init(item: MemoryItem) {
        self.item = item
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            
            // --- Image Carousel as header ---
            if !item.imageDatas.isEmpty {
                TabView(selection: $currentImageIndex) {
                    ForEach(Array(item.imageDatas.enumerated()), id: \.offset) { index, data in
                        if let ui = UIImage(data: data) {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .clipped()
                                .tag(index)
                                .onTapGesture {
                                    selectedImageIndex = IdentifiableIndex(id: index)
                                }
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
            }
            
            // --- Scrollable description ---
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !item.title.isEmpty {
                        Text(item.title)
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    if !item.details.isEmpty {
                        Text(item.details)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Text(item.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(24)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $selectedImageIndex, onDismiss: {
            if let index = selectedImageIndex?.id {
                currentImageIndex = index
            }
        }) { wrapper in
            ImageViewer(images: item.imageDatas,
                        startIndex: wrapper.id,
                        currentIndex: $currentImageIndex)
        }
    }
}

// Wrapper to make Int Identifiable
struct IdentifiableIndex: Identifiable {
    let id: Int
}
