import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss)
    private var dismiss
    
    @AppStorage("firstPaletteColor") 
    var firstPaletteColor: String = "AppBlueColor"
    @AppStorage("secondPaletteColor") 
    var secondPaletteColor: String = "AppPinkColor"
    
    var body: some View {
        NavigationStack {
            Form {
                LabeledContent {
                    Button(NSLocalizedString("settings_button_open", comment: ""), action: {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    })
                } label: {
                    Text(NSLocalizedString("settings_title_check", comment: ""))
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
                    Text(NSLocalizedString("settings_title_color", comment: ""))
                }
            }
            .navigationTitle(NSLocalizedString("settings_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("settings_button_cancel", comment: ""), action: { dismiss() })
                }
            }
        }
    }
}
