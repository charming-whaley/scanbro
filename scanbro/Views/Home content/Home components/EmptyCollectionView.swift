import SwiftUI

struct EmptyCollectionView: View {
    var body: some View {
        ContentUnavailableView(
            String(localized: "home_empty_title"),
            systemImage: "document.on.document.fill",
            description: Text(String(localized: "home_empty_description"))
        )
        .foregroundStyle(.gray)
    }
}
