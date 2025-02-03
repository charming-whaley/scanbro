import SwiftUI

struct HomeEmptyListView: View {
    var body: some View {
        ContentUnavailableView(
            "No Documents",
            systemImage: "document.on.document.fill",
            description: Text("It seems like you have not added any document. Tap on Scan button at the top to add a new one")
        )
    }
}
