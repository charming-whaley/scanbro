import SwiftUI

public struct Slide: Identifiable, Hashable {
    public var id: String = UUID().uuidString
    var image: String
}

var slides: [Slide] = [
    .init(image: "img 1"),
    .init(image: "img 2"),
    .init(image: "img 3"),
    .init(image: "img 4")
]
