import SwiftUI

struct EmptyCollectionView: View {
    var body: some View {
        ContentUnavailableView(
            "No documents",
            systemImage: "document.on.document.fill",
            description: Text("It seems like you haven't added any documents. Tap on Scan button at the top to add a new one")
        )
    }
}
