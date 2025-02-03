import SwiftUI

struct LibraryRowView: View {
    let document: Document
    let animation: Namespace.ID
    
    @State private var reducedImage: UIImage?
    
    var body: some View {
        HStack(spacing: 8) {
            if let firstPage = document.pages?.sorted(by: { $0.pageIndex < $1.pageIndex }).first {
                GeometryReader {
                    let size = $0.size
                    
                    if let reducedImage {
                        Image(uiImage: reducedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                    } else {
                        Rectangle()
                            .foregroundStyle(.clear)
                            .task(priority: .high) {
                                guard let image = UIImage(data: firstPage.content) else { return }
                                let adjustedSize = image.size.adjustSize(to: .init(width: 150, height: 150))
                                let renderer = UIGraphicsImageRenderer(size: adjustedSize)
                                let resulingImage = renderer.image { context in
                                    image.draw(in: .init(origin: .zero, size: adjustedSize))
                                }
                                
                                await MainActor.run {
                                    reducedImage = resulingImage
                                }
                            }
                    }
                }
                .frame(width: 150, height: 100)
                .clipShape(.rect(cornerRadius: 15))
                .matchedTransitionSource(id: document.uniqutStringID, in: animation)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(.system(size: 20, weight: .bold))
                    .lineLimit(2)
                    .foregroundStyle(Color.primary)
                
                Text(document.createdAt.formatted(date: .numeric, time: .omitted))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary.opacity(0.9))
            }
            .frame(maxHeight: .infinity, alignment: .top)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .top)
        .background {
            RoundedRectangle(cornerRadius: 13)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
        }
    }
}
