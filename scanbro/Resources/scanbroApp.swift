import SwiftUI

@main
struct scanbroApp: App {
    @AppStorage("showIntroView")
    var showIntroView: Bool = true
    
    let appID = "6741531524"
    
    var body: some Scene {
        WindowGroup {
            if showIntroView {
                IntroductionView()
                    .preferredColorScheme(.dark)
            } else {
                HomeView()
                    .modelContainer(for: Document.self)
                    .preferredColorScheme(.light)
            }
        }
    }
}
