import SwiftUI

extension View {
    @ViewBuilder
    public func addHorizonalAlignment(_ alignment: Alignment) -> some View {
        self
            .frame(maxWidth: .infinity, alignment: alignment)
    }
    
    @ViewBuilder
    public func addVerticalAlignment(_ alignment: Alignment) -> some View {
        self
            .frame(maxHeight: .infinity, alignment: alignment)
    }
    
    @ViewBuilder
    public func addLoadingScreen(_ isLoading: Binding<Bool>) -> some View {
        self
            .overlay {
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .frame(width: 40, height: 40)
                        .background(.bar, in: .rect(cornerRadius: 10))
                }
                .opacity(isLoading.wrappedValue ? 1 : 0)
                .allowsHitTesting(isLoading.wrappedValue)
                .animation(snappy, value: isLoading.wrappedValue)
            }
    }
    
    private var snappy: Animation {
        .snappy(duration: 0.25, extraBounce: 0)
    }
}
