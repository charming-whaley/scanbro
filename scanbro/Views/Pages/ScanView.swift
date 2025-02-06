import SwiftUI
import SwiftData
import PDFKit
import LocalAuthentication

struct ScanView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    
    @AppStorage("firstPaletteColor") var firstPaletteColor: String = "AppBlueColor"
    
    @State private var fileURL: URL?
    @State private var showFileMover: Bool = false
    @State private var isLoading: Bool = false
    @State private var askForRename: Bool = false
    @State private var documentName: String = NSLocalizedString("rename_document", comment: "")
    
    @State private var isFaceIDAvailable: Bool?
    @State private var isUnlocked: Bool = false
    
    let document: Document
    
    var body: some View {
        if let pages = document.pages?.sorted(by: { $0.pageIndex < $1.pageIndex }) {
            VStack(spacing: 10) {
                TabView {
                    ForEach(pages) { page in
                        if let image = UIImage(data: page.content) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                    }
                }
                .tabViewStyle(.page)
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
            .toolbarVisibility(.hidden, for: .navigationBar)
            .overlay(alignment: .topTrailing) {
                ScanDetailsHeaderView()
                    .padding(.top, 60)
                    .padding(.trailing, 20)
            }
            .safeAreaInset(edge: .bottom) {
                Rectangle()
                    .fill(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .clipShape(CustomRoundedCorners(radius: 30, corners: [.topLeft, .topRight]))
                    .overlay(alignment: .topLeading) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(document.title)
                                .font(.largeTitle)
                                .fontWeight(.black)
                                .lineLimit(2)
                                .truncationMode(.tail)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 5) {
                                Text(document.createdAt.formatted(date: .numeric, time: .omitted))
                                
                                Text(NSLocalizedString("pages_counter_text", comment: "") + ": \(document.pages?.count ?? 0)")
                            }
                            .font(.callout)
                            .foregroundStyle(Color.secondary)
                        }
                        .padding(25)
                    }
            }
            .ignoresSafeArea()
            .alert(NSLocalizedString("rename_alert_title", comment: ""), isPresented: $askForRename) {
                TextField(NSLocalizedString("rename_alert_textfield", comment: ""), text: $documentName)
                
                Button(NSLocalizedString("rename_alert_button", comment: ""), role: .cancel) {
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.2))
                        document.title = documentName
                        try? modelContext.save()
                    }
                }
                
                Button(NSLocalizedString("rename_alert_button_cancel", comment: ""), role: .destructive) {
                    askForRename = false
                }
            }
            .addLoadingScreen($isLoading)
            .fileMover(isPresented: $showFileMover, file: fileURL) { result in
                if case .failure(_) = result {
                    guard let fileURL else { return }
                    try? FileManager.default.removeItem(at: fileURL)
                    self.fileURL = nil
                }
            }
            .overlay {
                LockView()
            }
            .onAppear {
                guard document.documentLocked else {
                    isUnlocked = true
                    return
                }
                
                let context = LAContext()
                isFaceIDAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
            }
            .onChange(of: scenePhase) { oldValue, newValue in
                if newValue != .active && document.documentLocked {
                    isUnlocked = false
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    @ViewBuilder
    private func ScanDetailsHeaderView() -> some View {
        Menu {
            Button {
                saveDocumentOnDevice()
            } label: {
                Label(NSLocalizedString("scan_page_menu_save", comment: ""), systemImage: "arrow.down.circle.fill")
            }
            
            Button {
                askForRename.toggle()
            } label: {
                Label(NSLocalizedString("scan_page_menu_rename", comment: ""), systemImage: "rectangle.and.pencil.and.ellipsis")
            }
            
            Button {
                document.documentLocked.toggle()
                isUnlocked = !document.documentLocked
            } label: {
                Label(document.documentLocked ? NSLocalizedString("scan_page_menu_unlock", comment: "") : NSLocalizedString("scan_page_menu_lock", comment: ""), systemImage: "faceid")
            }
            
            Button(role: .destructive) {
                deleteScan()
            } label: {
                Label(NSLocalizedString("scan_page_menu_delete", comment: ""), systemImage: "trash.fill")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title2)
                .foregroundStyle(Color(firstPaletteColor))
        }
    }
    
    @ViewBuilder
    private func LockView() -> some View {
        if document.documentLocked {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                
                VStack(spacing: 6) {
                    if let isFaceIDAvailable, !isFaceIDAvailable {
                        Text(NSLocalizedString("faceid_control_error", comment: ""))
                            .multilineTextAlignment(.center)
                            .frame(width: 200)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.largeTitle)
                        
                        Text(NSLocalizedString("faceid_control_button", comment: ""))
                            .font(.callout)
                    }
                }
                .padding(15)
                .background(.bar, in: .rect(cornerRadius: 15))
                .contentShape(.rect)
                .onTapGesture(perform: authenticateUser)
            }
            .opacity(isUnlocked ? 0 : 1)
            .animation(.snappy(duration: 0.25, extraBounce: 0), value: isUnlocked)
        }
    }
}

fileprivate extension ScanView {
    struct CustomRoundedCorners: Shape {
        var radius: CGFloat
        var corners: UIRectCorner
        
        func path(in rect: CGRect) -> Path {
            let path = UIBezierPath(
                roundedRect: rect,
                byRoundingCorners: corners,
                cornerRadii: CGSize(width: radius, height: radius)
            )
            return Path(path.cgPath)
        }
    }
    
    private func authenticateUser() {
        let context = LAContext()
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: NSLocalizedString("faceid_control_title", comment: "")) { status, _ in
                DispatchQueue.main.async {
                    self.isUnlocked = status
                }
            }
        } else {
            isFaceIDAvailable = false
            isUnlocked = false
        }
    }
    
    private func saveDocumentOnDevice() {
        guard let pages = document.pages?.sorted(by: { $0.pageIndex < $1.pageIndex }) else { return }
        isLoading = true
        
        Task.detached(priority: .high) { [document] in
            let pdfDocument = PDFDocument()
            for index in pages.indices {
                if let image = UIImage(data: pages[index].content), let pdfPage = PDFPage(image: image) {
                    pdfDocument.insert(pdfPage, at: index)
                }
            }
            
            var url = FileManager.default.temporaryDirectory
            let fileName = "\(document.title).pdf"
            url.append(path: fileName)
            
            if pdfDocument.write(to: url) {
                await MainActor.run { [url] in
                    fileURL = url
                    showFileMover = true
                    isLoading = false
                }
            }
        }
    }
    
    private func deleteScan() {
        dismiss()
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.2))
            modelContext.delete(document)
            try? modelContext.save()
        }
    }
}
