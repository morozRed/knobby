#if DEBUG
import SwiftUI
import QuartzCore

/// Displays real-time FPS using CADisplayLink
/// Usage: Add FPSMonitorView() as an overlay
struct FPSMonitorView: View {
    @State private var fps: Double = 0
    @State private var monitor = FPSMonitor()

    var body: some View {
        Text("FPS: \(Int(fps))")
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundColor(fps < 50 ? .red : fps < 58 ? .yellow : .green)
            .padding(6)
            .background(.black.opacity(0.8))
            .cornerRadius(6)
            .onAppear { monitor.start { fps = $0 } }
            .onDisappear { monitor.stop() }
    }
}

final class FPSMonitor {
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount = 0
    private var onUpdate: ((Double) -> Void)?

    func start(onUpdate: @escaping (Double) -> Void) {
        self.onUpdate = onUpdate
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.add(to: .main, forMode: .common)
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func tick(_ link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }

        frameCount += 1
        let elapsed = link.timestamp - lastTimestamp

        if elapsed >= 1.0 {
            let fps = Double(frameCount) / elapsed
            onUpdate?(fps)
            frameCount = 0
            lastTimestamp = link.timestamp
        }
    }
}
#endif
