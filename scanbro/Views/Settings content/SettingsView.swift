import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss)
    private var dismiss
    
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
