import SwiftUI
import SwiftData

struct HomeView: View {
    @AppStorage("firstPaletteColor") var firstPaletteColor: String = "AppBlueColor"
    @AppStorage("secondPaletteColor") var secondPaletteColor: String = "AppPinkColor"
    @AppStorage("setDarkMode") var setDarkMode: Bool = false
    
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: [.init(\Document.createdAt, order: .reverse)], animation: .snappy(duration: 0.25, extraBounce: 0))
    var documents: [Document]
    
    @State private var showScanner: Bool = false
    @State private var showSettings: Bool = false
    
    var body: some View {
        VStack(spacing: 15) {
            HomeHeaderView(
                firstPaletteColor: firstPaletteColor,
                secondPaletteColor: secondPaletteColor,
                showScanner: $showScanner,
                showSettings: $showSettings
            )
            
            if (documents.isEmpty) {
                HomeEmptyListView()
            } else {
                ScrollView(.vertical) {
                    ForEach(documents) { document in
                        
                    }
                }
                .scrollIndicators(.hidden)
                .contentMargins(15)
            }
        }
        .padding()
        .fullScreenCover(isPresented: $showScanner) {
            ScannerView { scan in
                
            } finishedWithError: { error in
                
            } cancelled: {
                
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .colorScheme(setDarkMode ? .dark : .light)
                .presentationDetents([.height(250)])
        }
        .tint(Color(firstPaletteColor))
        .preferredColorScheme(setDarkMode ? .dark : .light)
    }
}
