import SwiftUI
import SwiftData
import PDFKit
import LocalAuthentication

struct ScanView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var fileURL: URL?
    @State private var showFileMover: Bool = false
    @State private var isLoading: Bool = false
    @State private var askForRename: Bool = false
    @State private var documentName: String = String(localized: "scan_rename_name")
    
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
                                .foregroundStyle(.black)
                                .font(.largeTitle)
                                .fontWeight(.black)
                                .lineLimit(2)
                                .truncationMode(.tail)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 5) {
                                Text(document.createdAt.formatted(date: .numeric, time: .omitted))
                                
                                Text("\(String(localized: "scan_description_pages")): \(document.pages?.count ?? 0)")
                            }
                            .font(.callout)
                            .foregroundStyle(Color.gray.opacity(0.5))
                        }
                        .padding(25)
                    }
            }
            .ignoresSafeArea()
            .alert(String(localized: "scan_rename_alert_label"), isPresented: $askForRename) {
                TextField(String(localized: "scan_rename_alert_hint"), text: $documentName)
                
                Button(String(localized: "scan_rename_alert_action"), role: .cancel) {
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.2))
                        document.title = documentName
                        try? modelContext.save()
                    }
                }
                
                Button(String(localized: "scan_rename_alert_cancel_action"), role: .destructive) {
                    askForRename = false
                }
            }
            .addLoadingScreen($isLoading)
            .fileMover(isPresented: $showFileMover, file: fileURL) { result in
                if case .failure(_) = result {
                    guard let fileURL else {
                        return
                    }
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
            .onChange(of: scenePhase) { _, newValue in
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
                Label(String(localized: "scan_menu_save"), systemImage: "arrow.down.circle.fill")
            }
            
            Button {
                askForRename.toggle()
            } label: {
                Label(String(localized: "scan_menu_rename"), systemImage: "rectangle.and.pencil.and.ellipsis")
            }
            
            Button {
                document.documentLocked.toggle()
                isUnlocked = !document.documentLocked
            } label: {
                Label(document.documentLocked ? String(localized: "scan_menu_unlock") : String(localized: "scan_menu_lock"), systemImage: "faceid")
            }
            
            Button(role: .destructive) {
                deleteScan()
            } label: {
                Label(String(localized: "scan_menu_delete"), systemImage: "trash.fill")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 23, height: 23)
                .foregroundStyle(Color.blue)
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
                        Text(String(localized: "faceid_error"))
                            .multilineTextAlignment(.center)
                            .frame(width: 200)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.largeTitle)
                        
                        Text(String(localized: "faceid_button"))
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
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: String(localized: "faceid_title")) { status, _ in
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
