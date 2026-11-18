//
//  PlanetBackdrop.swift
//  PlayFeat
//  Created by Owen Limantoro on 18/11/26.
//
//  A planet's landscape, drawn as separate full-frame layers so one set of
//  art fits every screen shape: the sky fills, the ground keeps to the
//  bottom edge, and props keep to their corner. Seen whole through the
//  kitchen window and across the planet's own screens.
//

import CoreGraphics
import Foundation

nonisolated struct PlanetBackdrop {
    /// Every layer is painted on the same frame, this size, so stacked
    /// unscaled they line up into the full picture.
    static let layerSize = CGSize(width: 1366, height: 1024)

    struct Layer {
        let imageName: String
        let fit: Fit
        var drift: Drift?
    }

    /// How a layer is scaled and placed when the screen isn't the layer's shape.
    enum Fit: Equatable {
        /// Fills the screen, cut evenly on the long sides. For the sky or water.
        case cover
        /// Fills the screen and keeps its bottom edge, so the ground always
        /// runs to both sides and the bottom; only sky above it is lost.
        case groundBand
        /// Fits whole inside the screen and slides toward `anchor` (each axis
        /// 0…1, top-left origin), so a prop hugs its corner and is never cut.
        case pinned(anchor: CGPoint)

        static let bottomLeading = Fit.pinned(anchor: CGPoint(x: 0, y: 1))
        static let bottomTrailing = Fit.pinned(anchor: CGPoint(x: 1, y: 1))
        static let topTrailing = Fit.pinned(anchor: CGPoint(x: 1, y: 0))

        /// Where a layer lands in `screen`, top-left origin.
        func frame(in screen: CGSize) -> CGRect {
            let layer = PlanetBackdrop.layerSize
            let widthScale = screen.width / layer.width
            let heightScale = screen.height / layer.height

            switch self {
            case .cover:
                return Self.frame(scale: max(widthScale, heightScale), anchor: CGPoint(x: 0.5, y: 0.5), in: screen)
            case .groundBand:
                return Self.frame(scale: max(widthScale, heightScale), anchor: CGPoint(x: 0.5, y: 1), in: screen)
            case .pinned(let anchor):
                return Self.frame(scale: min(widthScale, heightScale), anchor: anchor, in: screen)
            }
        }

        /// The layer at `scale`, with the leftover space split by `anchor`
        /// (negative leftover is the part cropped off).
        private static func frame(scale: CGFloat, anchor: CGPoint, in screen: CGSize) -> CGRect {
            let size = CGSize(width: PlanetBackdrop.layerSize.width * scale,
                              height: PlanetBackdrop.layerSize.height * scale)
            let origin = CGPoint(x: (screen.width - size.width) * anchor.x,
                                 y: (screen.height - size.height) * anchor.y)
            return CGRect(origin: origin, size: size)
        }
    }

    /// A slow, endless back-and-forth that makes a still layer feel alive.
    enum Drift: Equatable {
        /// Up and down by `height` layer points.
        case bob(height: CGFloat, period: TimeInterval)
        /// Tilts by `degrees` around `pivot` (each axis 0…1 of the layer,
        /// top-left origin): where the prop is rooted.
        case sway(degrees: Double, pivot: CGPoint, period: TimeInterval)

        var period: TimeInterval {
            switch self {
            case .bob(_, let period), .sway(_, _, let period): period
            }
        }
    }

    /// Back to front.
    let layers: [Layer]
    /// The planet as it appears on the galaxy map.
    let galaxyImageName: String
}
