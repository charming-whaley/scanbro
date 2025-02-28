import SwiftUI

public struct HeaderView: View {
    @Binding
    var showSettings: Bool
    var paletteColor: String
    
    init(
        withSwitcher showSettings: Binding<Bool>,
        andButtonOf paletteColor: String
    ) {
        self._showSettings = showSettings
        self.paletteColor = paletteColor
    }
    
    public var body: some View {
        HStack {
            Text(String(localized: "home_header_title"))
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundStyle(.white)
            
            Spacer(minLength: 0)
            
            Button {
                showSettings.toggle()
            } label: {
                Image(systemName: "gear")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25, height: 25)
                    .padding(8)
                    .foregroundStyle(.white)
            }
        }
    }
}
