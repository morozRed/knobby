import SwiftUI
import UIKit

@MainActor
final class NeumorphicShadowCache {
    static let shared = NeumorphicShadowCache()
    private let cache = NSCache<NSString, UIImage>()

    func image(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func insert(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

private struct ShadowLayer {
    let color: Color
    let opacity: Double
    let radius: CGFloat
}

struct CachedNeumorphicShadows: View {
    let themeKey: Int
    var cornerRadius: CGFloat = 24
    var lightColor: Color
    var darkColor: Color
    var lightOpacity: Double
    var darkOpacity: Double
    var ambientOpacity: Double
    var lightRadius: CGFloat
    var darkRadius: CGFloat
    var ambientRadius: CGFloat
    var lightOffset: CGSize
    var darkOffset: CGSize

    @Environment(\.displayScale) private var displayScale

    @State private var size: CGSize = .zero
    @State private var lightImage: UIImage?
    @State private var darkImage: UIImage?
    @State private var cachedLightKey: String?
    @State private var cachedDarkKey: String?

    var body: some View {
        ZStack {
            if let lightImage {
                shadowImage(lightImage, offset: lightOffset)
            }

            if let darkImage {
                shadowImage(darkImage, offset: darkOffset)
            }
        }
        .allowsHitTesting(false)
        .background(sizeReader)
        .onAppear {
            updateCacheIfNeeded(force: false)
        }
        .onChange(of: size) { _, _ in
            updateCacheIfNeeded(force: false)
        }
        .onChange(of: themeKey) { _, _ in
            updateCacheIfNeeded(force: true)
        }
    }

    private var shadowPadding: CGFloat {
        let maxRadius = max(lightRadius, max(darkRadius, ambientRadius))
        return KnobbyDimensions.shadowMaxOffset * 4 + maxRadius + 4
    }

    private var imageSize: CGSize {
        CGSize(
            width: size.width + shadowPadding * 2,
            height: size.height + shadowPadding * 2
        )
    }

    private func shadowImage(_ image: UIImage, offset: CGSize) -> some View {
        Image(uiImage: image)
            .resizable()
            .interpolation(.high)
            .frame(width: imageSize.width, height: imageSize.height)
            .offset(x: offset.width, y: offset.height)
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

    @MainActor
    private func updateCacheIfNeeded(force: Bool) {
        guard size.width > 0, size.height > 0 else { return }

        let lightLayer = ShadowLayer(
            color: lightColor,
            opacity: lightOpacity,
            radius: lightRadius
        )
        let darkLayers = [
            ShadowLayer(
                color: darkColor,
                opacity: darkOpacity,
                radius: darkRadius
            ),
            ShadowLayer(
                color: darkColor,
                opacity: ambientOpacity,
                radius: ambientRadius
            )
        ]

        let lightKey = shadowKey(
            size: size,
            padding: shadowPadding,
            cornerRadius: cornerRadius,
            layers: [lightLayer]
        )
        let darkKey = shadowKey(
            size: size,
            padding: shadowPadding,
            cornerRadius: cornerRadius,
            layers: darkLayers
        )

        if !force,
           cachedLightKey == lightKey,
           cachedDarkKey == darkKey,
           lightImage != nil,
           darkImage != nil {
            return
        }

        if cachedLightKey != lightKey {
            lightImage = nil
        }
        if cachedDarkKey != darkKey {
            darkImage = nil
        }

        cachedLightKey = lightKey
        cachedDarkKey = darkKey

        if let cached = NeumorphicShadowCache.shared.image(for: lightKey) {
            lightImage = cached
        } else if let image = renderShadowImage(
            size: size,
            padding: shadowPadding,
            cornerRadius: cornerRadius,
            layers: [lightLayer]
        ) {
            NeumorphicShadowCache.shared.insert(image, for: lightKey)
            lightImage = image
        }

        if let cached = NeumorphicShadowCache.shared.image(for: darkKey) {
            darkImage = cached
        } else if let image = renderShadowImage(
            size: size,
            padding: shadowPadding,
            cornerRadius: cornerRadius,
            layers: darkLayers
        ) {
            NeumorphicShadowCache.shared.insert(image, for: darkKey)
            darkImage = image
        }
    }

    private func shadowKey(
        size: CGSize,
        padding: CGFloat,
        cornerRadius: CGFloat,
        layers: [ShadowLayer]
    ) -> String {
        let widthPx = max(1, Int(((size.width + padding * 2) * displayScale).rounded()))
        let heightPx = max(1, Int(((size.height + padding * 2) * displayScale).rounded()))
        let radiusPx = max(1, Int((cornerRadius * displayScale).rounded()))
        let layersKey = layers.map { layer in
            let colorKey = colorIdentifier(for: layer.color)
            let radiusKey = Int((layer.radius * displayScale).rounded())
            let opacityKey = Int((layer.opacity * 1000).rounded())
            return "\(colorKey)-r\(radiusKey)-o\(opacityKey)"
        }.joined(separator: "|")
        return "\(widthPx)x\(heightPx)|r\(radiusPx)|\(layersKey)"
    }

    private func colorIdentifier(for color: Color) -> String {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            let r = Int((red * 1000).rounded())
            let g = Int((green * 1000).rounded())
            let b = Int((blue * 1000).rounded())
            let a = Int((alpha * 1000).rounded())
            return "\(r),\(g),\(b),\(a)"
        }

        return String(describing: uiColor)
    }

    private func renderShadowImage(
        size: CGSize,
        padding: CGFloat,
        cornerRadius: CGFloat,
        layers: [ShadowLayer]
    ) -> UIImage? {
        let imageSize = CGSize(
            width: size.width + padding * 2,
            height: size.height + padding * 2
        )

        let shadowView = ShadowImageSource(
            rectSize: size,
            imageSize: imageSize,
            cornerRadius: cornerRadius,
            layers: layers
        )

        let renderer = ImageRenderer(content: shadowView)
        renderer.scale = displayScale
        renderer.proposedSize = ProposedViewSize(imageSize)
        return renderer.uiImage
    }
}

private struct ShadowImageSource: View {
    let rectSize: CGSize
    let imageSize: CGSize
    let cornerRadius: CGFloat
    let layers: [ShadowLayer]

    var body: some View {
        ZStack {
            ForEach(layers.indices, id: \.self) { index in
                let layer = layers[index]
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.black)
                    .frame(width: rectSize.width, height: rectSize.height)
                    .shadow(
                        color: layer.color.opacity(layer.opacity),
                        radius: layer.radius,
                        x: 0,
                        y: 0
                    )
            }

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.black)
                .frame(width: rectSize.width, height: rectSize.height)
                .blendMode(.destinationOut)
        }
        .frame(width: imageSize.width, height: imageSize.height)
        .compositingGroup()
    }
}
