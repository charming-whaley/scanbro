import SwiftUI

struct LibraryRowView: View {
    let document: Document
    var animation: Namespace.ID
    
    init(
        _ document: Document,
        _ animation: Namespace.ID
    ) {
        self.document = document
        self.animation = animation
    }
    
    @State
    private var reducedImage: UIImage?
    
    var body: some View {
        HStack(spacing: 8) {
            if let firstScreen = document.pages?.sorted(by: { $0.pageIndex < $1.pageIndex }).first {
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
                                guard let image = UIImage(data: firstScreen.content) else { return }
                                let adjustedSize = image.size.adjustSize(to: .init(width: 150, height: 100))
                                let renderer = UIGraphicsImageRenderer(size: adjustedSize)
                                let result = renderer.image { context in
                                    image.draw(in: .init(origin: .zero, size: adjustedSize))
                                }
                                
                                await MainActor.run {
                                    reducedImage = result
                                }
                            }
                    }
                }
                .frame(width: 100, height: 80)
                .clipShape(.rect(cornerRadius: 8))
                .matchedTransitionSource(id: document.uniqutStringID, in: animation)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(document.createdAt.formatted(date: .numeric, time: .omitted))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.gray.opacity(0.6))
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            .frame(maxHeight: .infinity, alignment: .top)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .top)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        }
    }
}
