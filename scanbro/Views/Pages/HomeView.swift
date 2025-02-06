import SwiftUI
import SwiftData
import VisionKit
import StoreKit

struct HomeView: View {
    @AppStorage("launchCounter") var launchCounter: Int = 0
    @AppStorage("firstPaletteColor") var firstPaletteColor: String = "AppBlueColor"
    @AppStorage("secondPaletteColor") var secondPaletteColor: String = "AppPinkColor"
    
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
    @State private var documentName: String = NSLocalizedString("home_new_document_name", comment: "")
    
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
                                    .navigationTransition(.zoom(sourceID: document.uniqutStringID, in: animation))
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
                                    Label(NSLocalizedString("home_list_action_delete", comment: ""), systemImage: "trash.fill")
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
                    Text(NSLocalizedString("home_alert_title", comment: ""))
                        .font(.title.bold())
                    
                    TextField(NSLocalizedString("home_alert_textfield", comment: ""), text: $documentName)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 12)
                        .background {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(.gray.opacity(0.1))
                        }
                        .padding(.bottom, 5)
                    
                    HStack(spacing: 8) {
                        Button {
                            addDocument()
                            askForDocumentName.toggle()
                        } label: {
                            Text(NSLocalizedString("home_alert_button_continue", comment: ""))
                                .foregroundStyle(.white)
                                .font(.headline.bold())
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color(firstPaletteColor), in: .rect(cornerRadius: 15))
                        }
                        
                        Button {
                            askForDocumentName.toggle()
                            scannedDocument = nil
                            documentName = NSLocalizedString("home_new_document_name", comment: "")
                        } label: {
                            Text(NSLocalizedString("home_alert_button_delete", comment: ""))
                                .foregroundStyle(.white)
                                .font(.headline.bold())
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(.red, in: .rect(cornerRadius: 15))
                        }
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
                    title: Text(NSLocalizedString("home_error_alert_title", comment: "")),
                    message: Text(NSLocalizedString("home_error_alert_description", comment: "")),
                    dismissButton: .default(Text(NSLocalizedString("home_error_alert_button", comment: ""))) {
                        scannedDocument = nil
                        showErrorAlert = false
                    }
                )
            }
            .addLoadingScreen($isLoading)
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .presentationDetents([.height(250)])
            }
            .tint(Color(firstPaletteColor))
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
        if launchCounter % 15 == 0 {
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
                
                self.documentName = NSLocalizedString("home_new_document_name", comment: "")
                self.isLoading = false
                self.scannedDocument = nil
            }
        }
    }
}
