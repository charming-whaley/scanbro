import SwiftUI
import SwiftData
import VisionKit

struct HomeView: View {
    @AppStorage("firstPaletteColor") var firstPaletteColor: String = "AppBlueColor"
    @AppStorage("secondPaletteColor") var secondPaletteColor: String = "AppPinkColor"
    @AppStorage("setDarkMode") var setDarkMode: Bool = false
    
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: [.init(\Document.createdAt, order: .reverse)], animation: .snappy(duration: 0.25, extraBounce: 0))
    var documents: [Document]
    
    /// Functionality properties
    @State private var showScanner: Bool = false
    @State private var showSettings: Bool = false
    
    /// Saving new scan properties
    @State private var scannedDocument: VNDocumentCameraScan?
    @State private var showErrorAlert: Bool = false
    @State private var askForDocumentName: Bool = false
    @State private var documentName: String = ""
    
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
                scannedDocument = scan
                askForDocumentName = true
                showScanner = false
            } finishedWithError: { error in
                showScanner = false
                showErrorAlert = true
            } cancelled: {
                scannedDocument = nil
                showScanner = false
            }
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Oops!"),
                message: Text("Something wrong with your camera happened! Please check all permissions or relaunch an app!"),
                dismissButton: .default(Text("Continue")) {
                    scannedDocument = nil
                    showErrorAlert = false
                }
            )
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
