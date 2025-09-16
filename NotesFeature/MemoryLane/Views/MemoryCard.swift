import SwiftUI
import SharedModels

struct MemoryCard: View {
    let item: MemoryItem
    
    var body: some View {
        VStack(spacing: 0) {
            // --- Image Section ---
            if !item.imageDatas.isEmpty {
                TabView {
                    ForEach(Array(item.imageDatas.enumerated()), id: \.offset) { _, data in
                        if let ui = UIImage(data: data) {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFill()
                                .clipped()
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
            }
            
            // --- Title + Details Section ---
            VStack(alignment: .leading, spacing: 6) {
                if !item.title.isEmpty {
                    Text(item.title)
                        .font(.title3.bold())
                        .foregroundColor(.black)
                        .lineLimit(2)
                }
                
                if !item.details.isEmpty {
                    Text(item.details)
                        .font(.body)
                        .foregroundColor(.black.opacity(0.7))
                        .lineLimit(3)
                }
                
                Text(item.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.5))
                    .padding(.top, 4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 6)
    }
}
