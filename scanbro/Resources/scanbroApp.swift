import SwiftUI

@main
struct scanbroApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .modelContainer(for: Document.self)
        }
    }
}
