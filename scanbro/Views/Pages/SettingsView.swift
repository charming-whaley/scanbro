import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("firstPaletteColor") var firstPaletteColor: String = "AppBlueColor"
    @AppStorage("secondPaletteColor") var secondPaletteColor: String = "AppPinkColor"
    
    var body: some View {
        NavigationStack {
            Form {
                LabeledContent {
                    Button("Open Settings", action: {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    })
                } label: {
                    Text("Check permissions")
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
