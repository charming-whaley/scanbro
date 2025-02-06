import SwiftUI

@main
struct scanbroApp: App {
    let appID = "6741531524"
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .modelContainer(for: Document.self)
                .preferredColorScheme(.light)
        }
    }
}
