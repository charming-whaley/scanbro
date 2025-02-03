import SwiftUI
import SwiftData

@Model
final class Page {
    var document: Document?
    var pageIndex: Int
    @Attribute(.externalStorage)
    var content: Data
    
    init(document: Document? = nil, pageIndex: Int, content: Data) {
        self.document = document
        self.pageIndex = pageIndex
        self.content = content
    }
}
