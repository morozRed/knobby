#if DEBUG
import SwiftUI

extension View {
    /// Logs when this view's body is re-evaluated
    /// Usage: SomeView().trackRenders("SomeView")
    func trackRenders(_ label: String) -> some View {
        RenderTracker(label: label, content: self)
    }
}

private struct RenderTracker<Content: View>: View {
    let label: String
    let content: Content

    var body: some View {
        let _ = Self._printChanges()  // iOS 15+ - prints what state changed
        let _ = print("[\(timestamp)] \(label) body evaluated")
        content
    }

    private var timestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
}
#endif
