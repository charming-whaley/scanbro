import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("firstPaletteColor") var firstPaletteColor: String = "AppBlueColor"
    @AppStorage("secondPaletteColor") var secondPaletteColor: String = "AppPinkColor"
    @AppStorage("setDarkMode") var setDarkMode: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                LabeledContent {
                    Toggle("", isOn: $setDarkMode)
                } label: {
                    Text("Dark mode")
                }
                
                LabeledContent {
                    HStack(spacing: 8) {
                        ForEach(paletteColors) { color in
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(color.firstPaletteColor), Color(color.secondPaletteColor)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 30, height: 30)
                                .onTapGesture {
                                    firstPaletteColor = color.firstPaletteColor
                                    secondPaletteColor = color.secondPaletteColor
                                }
                        }
                    }
                } label: {
                    Text("Color scheme")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: { dismiss() })
                }
            }
        }
    }
}
