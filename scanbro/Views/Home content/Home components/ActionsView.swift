import SwiftUI

public struct ActionsView: View {
    @Binding var showDocumentsScanner: Bool
    @Binding var showScanner: Bool
    
    init(
        _ showDocumentsScanner: Binding<Bool>,
        _ showScanner: Binding<Bool>
    ) {
        self._showDocumentsScanner = showDocumentsScanner
        self._showScanner = showScanner
    }
    
    public var body: some View {
        HStack(spacing: 16) {
            ActionBoxView(called: "Create PDF", withIcon: "scanner.fill")
                .onTapGesture {
                    showDocumentsScanner.toggle()
                }
            
            ActionBoxView(called: "Make scan", withIcon: "qrcode.viewfinder")
                .onTapGesture {
                    showScanner.toggle()
                }
        }
        
    }
    
    @ViewBuilder
    private func ActionBoxView(
        called title: String,
        withIcon iconName: String
    ) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
            
            Spacer(minLength: 0)
            
            Circle()
                .fill(.black)
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 20, height: 20)
                        .foregroundStyle(.white)
                }
        }
        .padding([.top, .bottom], 18)
        .padding(.leading)
        .frame(height: 120)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: .rect(cornerRadius: 26))
    }
}
