import SwiftUI

struct HomeHeaderView: View {
    var firstPaletteColor: String
    var secondPaletteColor: String
    
    @Binding var showScanner: Bool
    @Binding var showSettings: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Text(NSLocalizedString("home_header_title", comment: ""))
                .font(.largeTitle)
                .fontWeight(.black)
            
            Spacer(minLength: 0)
            
            Button {
                showScanner.toggle()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "document.viewfinder.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundStyle(.white)
                    
                    Text(NSLocalizedString("home_header_button", comment: ""))
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(firstPaletteColor), in: .capsule)
            }
            
            Button {
                showSettings.toggle()
            } label: {
                Image(systemName: "gear")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .padding(8)
                    .foregroundStyle(.white)
                    .background(Color(secondPaletteColor), in: .circle)
            }
        }
    }
}
