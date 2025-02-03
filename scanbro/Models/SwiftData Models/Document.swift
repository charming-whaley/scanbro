import SwiftUI
import SwiftData

@Model
final class Document {
    var title: String
    var createdAt: Date = Date.now
    @Relationship(deleteRule: .cascade, inverse: \Page.document)
    var pages: [Page]?
    var documentLocked: Bool = false
    
    var uniqutStringID: String {
        return UUID().uuidString
    }
    
    init(title: String, pages: [Page]? = nil) {
        self.title = title
        self.pages = pages
    }
}
