import SwiftUI

struct HomeEmptyListView: View {
    var body: some View {
        ContentUnavailableView(
            NSLocalizedString("home_empty_list_title", comment: ""),
            systemImage: "document.on.document.fill",
            description: Text(NSLocalizedString("home_empty_list_description", comment: ""))
        )
    }
}
