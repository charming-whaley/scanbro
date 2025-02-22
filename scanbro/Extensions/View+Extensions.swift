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
    
    func addBlurOpacityEffect(_ show: Bool) -> some View {
        self
            .blur(radius: show ? 0 : 2)
            .opacity(show ? 1 : 0)
            .scaleEffect(show ? 1 : 0.9)
    }
    
    @ViewBuilder
    public func addCustomAlert<Content, Background>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder background: () -> Background
    ) -> some View where Content: View, Background: View {
        self
            .modifier(
                AlertModifier(
                    isPresented: isPresented,
                    alertContent: content,
                    background: background
                )
            )
    }
}

fileprivate struct AlertModifier<AlertContent, Background>: ViewModifier where AlertContent: View, Background: View {
    @Binding var isPresented: Bool
    @ViewBuilder var alertContent: AlertContent
    @ViewBuilder var background: Background
    
    @State private var showFullScreenCover: Bool = false
    @State private var animated: Bool = false
    @State private var allowsInteractions: Bool = false
    
    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $showFullScreenCover) {
                ZStack {
                    if animated {
                        alertContent
                            .allowsHitTesting(allowsInteractions)
                    }
                }
                .presentationBackground {
                    background
                        .allowsHitTesting(allowsInteractions)
                        .opacity(animated ? 1 : 0)
                }
                .task {
                    try? await Task.sleep(for: .seconds(0.05))
                    withAnimation(.easeInOut(duration: 0.3)) {
                        animated.toggle()
                    }
                    
                    try? await Task.sleep(for: .seconds(0.3))
                    allowsInteractions.toggle()
                }
            }
            .onChange(of: isPresented) { _, newValue in
                var transaction = Transaction()
                transaction.disablesAnimations = true
                
                if newValue {
                    withTransaction(transaction) {
                        showFullScreenCover = true
                    }
                } else {
                    allowsInteractions = false
                    withAnimation(.easeInOut(duration: 0.3), completionCriteria: .removed) {
                        animated = false
                    } completion: {
                        withTransaction(transaction) {
                            showFullScreenCover = false
                        }
                    }
                }
            }
    }
}
