import SwiftUI

public struct IntroductionView: View {
    @AppStorage("showIntroView")
    var showIntroView: Bool = true
    
    @State
    private var activeSlide: Slide? = slides.first
    @State
    private var scrollPosition: ScrollPosition = .init()
    @State
    private var currentScrollOffset: CGFloat = .zero
    @State
    private var timer = Timer.publish(every: 0.01, on: .current, in: .default).autoconnect()
    @State
    private var initialAnimation: Bool = false
    @State
    private var titleProgress: CGFloat = .zero
    @State
    private var scrollPhase: ScrollPhase = .idle
    
    public var body: some View {
        ZStack {
            AmbientBackgroundView()
                .animation(.easeInOut(duration: 1), value: activeSlide)
            
            VStack(spacing: 40) {
                InfiniteScrollView {
                    ForEach(slides) { slide in
                        CarouselView(slide)
                    }
                }
                .scrollIndicators(.hidden)
                .scrollPosition($scrollPosition)
                .scrollClipDisabled()
                .containerRelativeFrame(.vertical) { value, _ in
                    value * 0.45
                }
                .onScrollPhaseChange { _, newPhase in
                    scrollPhase = newPhase
                }
                .onScrollGeometryChange(for: CGFloat.self) {
                    $0.contentOffset.x + $0.contentInsets.leading
                } action: { _, newValue in
                    currentScrollOffset = newValue
                    
                    if scrollPhase != .decelerating || scrollPhase != .animating {
                        activeSlide = slides[Int((currentScrollOffset / 220).rounded()) % slides.count]
                    }
                }
                .visualEffect { [initialAnimation] content, proxy in
                    content
                        .offset(y: !initialAnimation ? -(proxy.size.height + 200) : 0)
                }
                
                VStack(spacing: 4) {
                    Text("Welcome to")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.secondary)
                        .addBlurOpacityEffect(initialAnimation)
                    
                    Text("Scan Bro")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .padding(.bottom, 12)
                        .textRenderer(CustomTextRenderer(progress: titleProgress))
                    
                    Text("Scan any document")
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.secondary)
                        .addBlurOpacityEffect(initialAnimation)
                }
                
                Button {
                    showIntroView = false
                    timer.upstream.connect().cancel()
                } label: {
                    Text("Let's go!")
                        .fontWeight(.semibold)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 25)
                        .padding(.vertical, 12)
                        .background(.white, in: .capsule)
                }
                .addBlurOpacityEffect(initialAnimation)
            }
            .safeAreaPadding(15)
        }
        .onReceive(timer) { _ in
            currentScrollOffset += 0.35
            scrollPosition.scrollTo(x: currentScrollOffset)
        }
        .task {
            try? await Task.sleep(for: .seconds(0.35))
            
            withAnimation(.smooth(duration: 0.75, extraBounce: 0)) {
                self.initialAnimation = true
            }
            
            withAnimation(.smooth(duration: 2.5, extraBounce: 0).delay(0.3)) {
                self.titleProgress = 1
            }
        }
    }
    
    @ViewBuilder
    private func AmbientBackgroundView() -> some View {
        GeometryReader {
            let size = $0.size
            
            ZStack {
                ForEach(slides) { slide in
                    Image(slide.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                        .frame(width: size.width, height: size.height)
                        .opacity(activeSlide?.id == slide.id ? 1 : 0)
                }
                
                Rectangle()
                    .fill(.black.opacity(0.45))
                    .ignoresSafeArea()
            }
            .compositingGroup()
            .blur(radius: 90, opaque: true)
            .ignoresSafeArea()
        }
    }
    
    @ViewBuilder
    private func CarouselView(_ slide: Slide) -> some View {
        GeometryReader {
            let size = $0.size
            
            Image(slide.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipShape(.rect(cornerRadius: 20))
                .shadow(color: .black.opacity(0.4), radius: 10, x: 1, y: 0)
        }
        .frame(width: 220)
        .scrollTransition(.interactive.threshold(.centered), axis: .horizontal) { content, phase in
            content
                .offset(y: phase == .identity ? -10 : 0)
                .rotationEffect(.degrees(phase.value * 5), anchor: .bottom)
        }
    }
}
