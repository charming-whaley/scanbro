import SwiftUI

public struct CustomTextField: View {
    var config: Config
    var hint: String
    @Binding var text: String
    
    init(
        withStyleOf config: Config,
        AndHint hint: String,
        Changing text: Binding<String>
    ) {
        self.config = config
        self.hint = hint
        self._text = text
    }
    
    @FocusState private var keyboardAppeared: Bool
    private var progressColor: Color {
        progress < 0.6 ? .gray.opacity(0.3) : progress == 1 ? .red : .orange
    }
    private var progress: CGFloat {
        max(min(CGFloat(text.count) / CGFloat(config.limit), 1), 0)
    }
    
    public var body: some View {
        VStack(alignment: config.progressConfig.alignment, spacing: 12) {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: config.borderConfig.radius)
                    .fill(.clear)
                    .frame(height: config.allowsAutoResize ? 0 : nil)
                    .contentShape(.rect(cornerRadius: config.borderConfig.radius))
                    .onTapGesture {
                        keyboardAppeared = true
                    }
                
                TextField(hint, text: $text, axis: .vertical)
                    .focused($keyboardAppeared)
                    .onChange(of: text, initial: true) { _, _ in
                        guard !config.allowsExcessTyping else {
                            return
                        }
                        
                        text = String(text.prefix(config.limit))
                    }
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: config.borderConfig.radius)
                    .stroke(progressColor.gradient, lineWidth: config.borderConfig.width)
            }
            
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(.ultraThinMaterial, lineWidth: 3)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(progressColor.gradient, lineWidth: 3)
                        .rotationEffect(.init(degrees: -90))
                }
                .frame(width: 20, height: 20)
            }
        }
    }
    
    struct Config {
        var limit: Int
        var tint: Color = .blue
        var allowsAutoResize = false
        var allowsExcessTyping = false
        var progressConfig: ProgressConfig = .init()
        var borderConfig: BorderConfig = .init()
    }
    
    struct ProgressConfig {
        var showsRing = true
        var alignment: HorizontalAlignment = .trailing
    }
    
    struct BorderConfig {
        var show = false
        var radius: CGFloat = 12
        var width: CGFloat = 0.8
    }
}
