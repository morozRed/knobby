import SwiftUI
import UIKit

@MainActor
final class NeumorphicPanelCache {
    static let shared = NeumorphicPanelCache()
    private let cache = NSCache<NSString, UIImage>()

    func image(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func insert(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

struct CachedNeumorphicPanel: View {
    var themeManager: ThemeManager?
    var cornerRadius: CGFloat = 24

    @Environment(\.displayScale) private var displayScale

    @State private var size: CGSize = .zero
    @State private var cachedImage: UIImage?
    @State private var cachedKey: String?

    private var surfaceColor: Color {
        themeManager?.surface ?? KnobbyColors.surface
    }

    private var isDarkMode: Bool {
        themeManager?.isDarkMode ?? false
    }

    var body: some View {
        ZStack {
            if let cachedImage {
                Image(uiImage: cachedImage)
                    .resizable()
                    .interpolation(.high)
            } else {
                NeumorphicPanelBase(
                    surfaceColor: surfaceColor,
                    cornerRadius: cornerRadius
                )
            }
        }
        .background(sizeReader)
        .onAppear {
            updateCacheIfNeeded(force: false)
        }
        .onChange(of: size) { _, _ in
            updateCacheIfNeeded(force: false)
        }
        .onChange(of: isDarkMode) { _, _ in
            updateCacheIfNeeded(force: true)
        }
    }

    private var sizeReader: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    updateSize(proxy.size)
                }
                .onChange(of: proxy.size) { _, newSize in
                    updateSize(newSize)
                }
        }
    }

    private func updateSize(_ newSize: CGSize) {
        guard newSize != size else { return }
        size = newSize
    }

    private func cacheKey(for size: CGSize) -> String {
        let widthPx = max(1, Int((size.width * displayScale).rounded()))
        let heightPx = max(1, Int((size.height * displayScale).rounded()))
        let radiusPx = max(1, Int((cornerRadius * displayScale).rounded()))
        return "\(widthPx)x\(heightPx)|r\(radiusPx)|\(isDarkMode ? 1 : 0)"
    }

    @MainActor
    private func updateCacheIfNeeded(force: Bool) {
        guard size.width > 0, size.height > 0 else { return }

        let key = cacheKey(for: size)
        if !force, cachedKey == key, cachedImage != nil {
            return
        }

        if cachedKey != key {
            cachedImage = nil
        }
        cachedKey = key

        if let cached = NeumorphicPanelCache.shared.image(for: key) {
            cachedImage = cached
            return
        }

        let panel = NeumorphicPanelBase(
            surfaceColor: surfaceColor,
            cornerRadius: cornerRadius
        )
        .frame(width: size.width, height: size.height)

        let renderer = ImageRenderer(content: panel)
        renderer.scale = displayScale
        renderer.proposedSize = ProposedViewSize(size)

        if let image = renderer.uiImage {
            NeumorphicPanelCache.shared.insert(image, for: key)
            cachedImage = image
        }
    }
}

private struct NeumorphicPanelBase: View {
    let surfaceColor: Color
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(surfaceColor)
    }
}
