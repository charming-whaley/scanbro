import Foundation

struct ColorPalette: Identifiable {
    var id = UUID().uuidString
    var firstPaletteColor, secondPaletteColor: String
}

let paletteColors: [ColorPalette] = [
    .init(firstPaletteColor: "AppBlueColor", secondPaletteColor: "AppPinkColor"),
    .init(firstPaletteColor: "AppOrangeColor", secondPaletteColor: "AppRedColor"),
    .init(firstPaletteColor: "AppGreenColor", secondPaletteColor: "AppPurpleColor")
]
