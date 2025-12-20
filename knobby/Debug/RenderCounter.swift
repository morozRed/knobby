#if DEBUG
import SwiftUI

/// Visual overlay showing render count and FPS estimate
/// Usage: SomeView().showRenderCount()
struct RenderCounterModifier: ViewModifier {
    @State private var renderCount = 0
    @State private var fps: Double = 0
    @State private var lastRenderTime = Date()

    func body(content: Content) -> some View {
        let _ = updateStats()
        content.overlay(alignment: .topTrailing) {
            VStack(alignment: .trailing, spacing: 2) {
                Text("Renders: \(renderCount)")
                Text("FPS: \(String(format: "%.1f", fps))")
            }
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(.red)
            .padding(4)
            .background(.black.opacity(0.7))
            .cornerRadius(4)
            .padding(8)
        }
    }

    private func updateStats() {
        renderCount += 1
        let now = Date()
        let interval = now.timeIntervalSince(lastRenderTime)
        if interval > 0 {
            fps = 1.0 / interval
        }
        lastRenderTime = now
    }
}

extension View {
    func showRenderCount() -> some View {
        modifier(RenderCounterModifier())
    }
}
#endif
