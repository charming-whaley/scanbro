import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss)
    private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                LabeledContent {
                    Button(String(localized: "settings_item_action_label"), action: {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    })
                } label: {
                    Text(String(localized: "settings_item_label"))
                }
            }
            .navigationTitle(String(localized: "settings_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "settings_toolbar_action"), action: { dismiss() })
                }
            }
        }
        .preferredColorScheme(.light)
    }
}
