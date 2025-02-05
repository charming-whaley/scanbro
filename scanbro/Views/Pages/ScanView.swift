import SwiftUI
import SwiftData
import PDFKit

struct ScanView: View {
    let document: Document
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("firstPaletteColor") var firstPaletteColor: String = "AppBlueColor"
    
    @State private var fileURL: URL?
    @State private var showFileMover: Bool = false
    @State private var isLoading: Bool = false
    @State private var askForRename: Bool = false
    @State private var documentName: String = "New name"
    
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
                    .frame(height: 250)
                    .clipShape(CustomRoundedCorners(radius: 30, corners: [.topLeft, .topRight]))
                    .overlay(alignment: .topLeading) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(document.title)
                                .font(.largeTitle)
                                .fontWeight(.black)
                                .lineLimit(2)
                                .truncationMode(.tail)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 5) {
                                Text(document.createdAt.formatted(date: .numeric, time: .omitted))
                                
                                Text("Pages: \(document.pages?.count ?? 0)")
                            }
                            .font(.callout)
                            .foregroundStyle(Color.secondary)
                        }
                        .padding(25)
                    }
            }
            .ignoresSafeArea()
            .alert("Rename document", isPresented: $askForRename) {
                TextField("Type here..", text: $documentName)
                
                Button("Rename", role: .cancel) {
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.2))
                        document.title = documentName
                        try? modelContext.save()
                    }
                }
                
                Button("Cancel", role: .destructive) {
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
        }
    }
    
    @ViewBuilder
    private func ScanDetailsHeaderView() -> some View {
        Menu {
            Button {
                saveDocumentOnDevice()
            } label: {
                Label("Save", systemImage: "arrow.down.circle.fill")
            }
            
            Button {
                askForRename.toggle()
            } label: {
                Label("Rename", systemImage: "rectangle.and.pencil.and.ellipsis")
            }
            
            Button {
                // FaceID logic here...
            } label: {
                Label("Lock with FaceID", systemImage: "faceid")
            }
            
            Button(role: .destructive) {
                deleteScan()
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title2)
                .foregroundStyle(Color(firstPaletteColor))
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

#Preview {
    ScanView(
        document: Document(
            title: "Abracadabra"
        )
    )
}
