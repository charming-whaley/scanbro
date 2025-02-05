import SwiftUI
import SwiftData
import PDFKit

/// Changes that should be implemented in near future:
/// - add diglog view to the text that on tap shows the full name of the document
/// - implement a menu of three actions: Save document on device, delete document from context and lock it with FaceID
/// - some little changes that can possible be added to the view
struct ScanView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("firstPaletteColor") var firstPaletteColor: String = "AppBlueColor"
    
    @State private var fileURL: URL?
    @State private var showFileMover: Bool = false
    @State private var isLoading: Bool = false
    
    let document: Document
    
    var body: some View {
        if let pages = document.pages?.sorted(by: { $0.pageIndex < $1.pageIndex }) {
            VStack(spacing: 10) {
                ScanDetailsHeaderView()
                
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
                
                ScanDetailsFooterView()
            }
            .background(.black)
            .toolbarVisibility(.hidden, for: .navigationBar)
            .addLoadingScreen($isLoading)
            .fileMover(isPresented: $showFileMover, file: fileURL) { result in
                if case .failure(_) = result {
                    guard let fileURL else { return }
                    try? FileManager.default.removeItem(at: fileURL)
                    self.fileURL = nil
                }
            }
        }
    }
    
    @ViewBuilder
    private func ScanDetailsHeaderView() -> some View {
        HStack(spacing: 0) {
            Text(document.title)
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(width: 250, alignment: .leading)
            
            Spacer(minLength: 0)
            
            Button {
                // FaceID controller
            } label: {
                Image(systemName: document.documentLocked ? "lock.fill" : "lock.open.fill")
                    .font(.title3)
                    .foregroundStyle(Color(firstPaletteColor))
            }
        }
        .addHorizonalAlignment(.leading)
        .padding()
    }
    
    @ViewBuilder
    private func ScanDetailsFooterView() -> some View {
        HStack(spacing: 8) {
            Button {
                saveDocumentOnDevice()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                    Text("Save")
                }
                .foregroundStyle(.white)
                .font(.headline)
                .padding(.vertical, 10)
                .padding(.horizontal)
                .background {
                    Capsule()
                        .fill(Color(firstPaletteColor))
                }
            }
            
            Button {
                deleteScan()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                    Text("Delete")
                }
                .foregroundStyle(.white)
                .font(.headline)
                .padding(.vertical, 10)
                .padding(.horizontal)
                .background {
                    Capsule()
                        .fill(.red)
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding()
    }
}

fileprivate extension ScanView {
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
