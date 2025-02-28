import SwiftUI
import SwiftData
import VisionKit
import StoreKit

public struct RootView: View {
    @AppStorage("launchCounter") var launchCounter: Int = 0
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    
    @Query(sort: [.init(\Document.createdAt, order: .reverse)], animation: .snappy(duration: 0.25, extraBounce: 0))
    var documents: [Document]
    
    @Namespace var animation
     
    @State private var showScanner: Bool = false
    @State private var scannedDocument: VNDocumentCameraScan?
    @State private var documentName: String = String(localized: "home_original_name")
    @State private var askForDocumentName: Bool = false
    @State private var showSettings: Bool = false
    @State private var showErrorAlert: Bool = false
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HeaderView(withSwitcher: $showSettings, andButtonOf: "AppBlueColor")
                    .padding([.horizontal, .top], 20)
                
                ActionsView($showScanner, .constant(false))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(.white)
                        .ignoresSafeArea()
                    
                    CollectionView()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Image("background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 8)
                    .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $showScanner) {
                ScannerView { scan in
                    scannedDocument = scan
                    askForDocumentName = true
                    showScanner = false
                } finishedWithError: { error in
                    showScanner = false
                    
                } cancelled: {
                    scannedDocument = nil
                    showScanner = false
                }
                .ignoresSafeArea()
            }
            .addCustomAlert(isPresented: $askForDocumentName) {
                VStack(alignment: .leading, spacing: 15) {
                    Text(String(localized: "home_alert_title"))
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(.black)
                    
                    CustomTextField(
                        withStyleOf: .init(
                            limit: 70,
                            tint: Color.secondary,
                            allowsAutoResize: true
                        ),
                        AndHint: String(localized: "home_alert_hint"),
                        Changing: $documentName
                    )
                    .autocorrectionDisabled()
                    .frame(maxHeight: 110, alignment: .top)
                    
                    HStack(spacing: 8) {
                        Button {
                            addDocument()
                            askForDocumentName.toggle()
                        } label: {
                            Text(String(localized: "home_alert_first_action"))
                                .foregroundStyle(.white)
                                .font(.headline.bold())
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color.blue, in: .rect(cornerRadius: 20))
                        }
                        
                        Button {
                            askForDocumentName.toggle()
                            scannedDocument = nil
                            documentName = String(localized: "home_original_name")
                        } label: {
                            Text(String(localized: "home_alert_second_action"))
                                .foregroundStyle(.white)
                                .font(.headline.bold())
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color.red, in: .rect(cornerRadius: 20))
                        }
                    }
                }
                .padding(15)
                .background(.white, in: .rect(cornerRadius: 30))
                .padding(.horizontal, 20)
            } background: {
                Rectangle()
                    .fill(.black.opacity(0.6))
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text(String(localized: "home_error_alert_title")),
                    message: Text(String(localized: "home_error_alert_description")),
                    dismissButton: .default(Text(String(localized: "home_error_alert_action"))) {
                        scannedDocument = nil
                        showErrorAlert = false
                    }
                )
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .presentationDetents([.height(200)])
            }
        }
    }
    
    @ViewBuilder
    private func CollectionView() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(String(localized: "home_collection_title"))
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(.black)
            
            if documents.isEmpty {
                EmptyCollectionView()
            } else {
                ScrollView {
                    ForEach(documents) { document in
                        NavigationLink {
                            ScanView(document: document)
                                .navigationTransition(.zoom(sourceID: document.uniqutStringID, in: animation))
                        } label: {
                            LibraryRowView(document, animation)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                Task { @MainActor in
                                    try? await Task.sleep(for: .seconds(0.2))
                                    modelContext.delete(document)
                                    try? modelContext.save()
                                }
                            } label: {
                                Label(String(localized: "home_collection_item_action"), systemImage: "trash.fill")
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .contentMargins(3)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(20)
    }
}

fileprivate extension RootView {
    @MainActor
    private func handleAppLaunch() {
        launchCounter += 1
        if launchCounter % 15 == 0 {
            requestReview()
        }
    }
    
    private func addDocument() {
        guard let scannedDocument else { return }
        
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
                
                self.documentName = String(localized: "home_original_name")
                self.scannedDocument = nil
            }
        }
    }
}

#Preview {
    RootView()
}
