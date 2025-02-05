import SwiftUI
import SwiftData
import VisionKit
import StoreKit

struct HomeView: View {
    @AppStorage("launchCounter") var launchCounter: Int = 0
    @AppStorage("firstPaletteColor") var firstPaletteColor: String = "AppBlueColor"
    @AppStorage("secondPaletteColor") var secondPaletteColor: String = "AppPinkColor"
    @AppStorage("setDarkMode") var setDarkMode: Bool = false
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    
    @Namespace var animation
    
    @Query(sort: [.init(\Document.createdAt, order: .reverse)], animation: .snappy(duration: 0.25, extraBounce: 0))
    var documents: [Document]
    
    @State private var showScanner: Bool = false
    @State private var showSettings: Bool = false
    
    @State private var scannedDocument: VNDocumentCameraScan?
    @State private var showErrorAlert: Bool = false
    @State private var askForDocumentName: Bool = false
    @State private var isLoading: Bool = false
    @State private var documentName: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                HomeHeaderView(
                    firstPaletteColor: firstPaletteColor,
                    secondPaletteColor: secondPaletteColor,
                    showScanner: $showScanner,
                    showSettings: $showSettings
                )
                .padding()
                
                if (documents.isEmpty) {
                    HomeEmptyListView()
                        .addVerticalAlignment(.center)
                } else {
                    ScrollView(.vertical) {
                        ForEach(documents) { document in
                            NavigationLink {
                                ScanView(document: document)
                            } label: {
                                LibraryRowView(document: document, animation: animation)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    Task { @MainActor in
                                        try? await Task.sleep(for: .seconds(0.2))
                                        modelContext.delete(document)
                                        try? modelContext.save()
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                }
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .contentMargins(15)
                }
            }
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
                .ignoresSafeArea()
            }
            .addCustomAlert(isPresented: $askForDocumentName) {
                VStack(alignment: .leading, spacing: 15) {
                    Text("New document")
                        .font(.title.bold())
                    
                    TextField("Type here...", text: $documentName)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 12)
                        .background {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(.gray.opacity(0.1))
                        }
                        .padding(.bottom, 5)
                    
                    Button {
                        addDocument()
                        askForDocumentName.toggle()
                    } label: {
                        Text("Continue")
                            .foregroundStyle(.white)
                            .font(.headline.bold())
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color(firstPaletteColor), in: .rect(cornerRadius: 15))
                    }
                    
                    Button {
                        askForDocumentName.toggle()
                        scannedDocument = nil
                        documentName = "New document"
                    } label: {
                        Text("Delete")
                            .foregroundStyle(.white)
                            .font(.headline.bold())
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(.red, in: .rect(cornerRadius: 15))
                    }
                }
                .padding(15)
                .background(.background, in: .rect(cornerRadius: 10))
                .padding(.horizontal, 30)
            } background: {
                Rectangle()
                    .fill(.primary.opacity(0.35))
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
            .addLoadingScreen($isLoading)
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .colorScheme(setDarkMode ? .dark : .light)
                    .presentationDetents([.height(250)])
            }
            .tint(Color(firstPaletteColor))
            .preferredColorScheme(setDarkMode ? .dark : .light)
            .onAppear {
                handleAppLaunch()
            }
        }
    }
}

fileprivate extension HomeView {
    @MainActor
    private func handleAppLaunch() {
        launchCounter += 1
        if launchCounter % 5 == 0 {
            requestReview()
        }
    }
    
    private func addDocument() {
        guard let scannedDocument else { return }
        isLoading = true
        
        Task.detached(priority: .high) { [documentName] in
            let document = Document(title: documentName)
            var pages = [Page]()
            
            for index in 0..<scannedDocument.pageCount {
                let scanImage = scannedDocument.imageOfPage(at: index)
                guard let image = scanImage.jpegData(compressionQuality: 0.65) else { return }
                pages.append(
                    Page(
                        document: document,
                        pageIndex: index,
                        content: image
                    )
                )
            }
            
            document.pages = pages
            await MainActor.run {
                modelContext.insert(document)
                try? modelContext.save()
                
                self.documentName = "New document"
                self.isLoading = false
                self.scannedDocument = nil
            }
        }
    }
}
