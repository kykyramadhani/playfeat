//
//  LayeredPlanetBackdrop.swift
//  PlayFeat
//  Created by Owen Limantoro on 18/11/26.
//
//  Draws a planet's landscape layers to fill whatever space it's given, each
//  placed by its own fit rule, with a gentle drift on the layers that have
//  one. In a 1366×1024 box (the kitchen art) every layer lands unscaled.
//

import SwiftUI

struct LayeredPlanetBackdrop: View {
    let backdrop: PlanetBackdrop

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                ForEach(backdrop.layers, id: \.imageName) { layer in
                    LandscapeLayer(layer: layer, frame: layer.fit.frame(in: proxy.size))
                }
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

/// One layer at its place on screen, drifting if it has a drift and Reduce
/// Motion is off.
private struct LandscapeLayer: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let layer: PlanetBackdrop.Layer
    let frame: CGRect

    @State private var isDrifting = false

    var body: some View {
        Image(layer.imageName)
            .resizable()
            .frame(width: frame.width, height: frame.height)
            .modifier(DriftEffect(drift: layer.drift, scale: layerScale, isDrifting: isDrifting))
            .scaleEffect(x: layer.widthScale, y: 1, anchor: .leading)
            .offset(x: frame.minX, y: frame.minY)
            .onAppear(perform: startDrifting)
    }

    /// Screen points per layer point.
    private var layerScale: CGFloat { frame.width / PlanetBackdrop.layerSize.width }

    private func startDrifting() {
        guard let drift = layer.drift, !reduceMotion else { return }
        withAnimation(.easeInOut(duration: drift.period / 2).repeatForever(autoreverses: true)) {
            isDrifting = true
        }
    }
}

/// Moves a layer between its rest pose and the far end of its drift.
private struct DriftEffect: ViewModifier {
    let drift: PlanetBackdrop.Drift?
    let scale: CGFloat
    let isDrifting: Bool

    func body(content: Content) -> some View {
        switch drift {
        case .bob(let height, _):
            // Grown by the bob's reach so a full-screen layer never shows an edge.
            content
                .scaleEffect(1 + 2 * height / PlanetBackdrop.layerSize.height)
                .offset(y: isDrifting ? -height * scale : 0)
        case .sway(let degrees, let pivot, _):
            content
                .rotationEffect(.degrees(isDrifting ? degrees : 0), anchor: UnitPoint(x: pivot.x, y: pivot.y))
        case nil:
            content
        }
    }
}

#Preview("Kepler-186f") {
    LayeredPlanetBackdrop(backdrop: Planet.kepler186f.backdrop)
        .ignoresSafeArea()
}

#Preview("K2-332 b") {
    LayeredPlanetBackdrop(backdrop: Planet.k2332b.backdrop)
        .ignoresSafeArea()
}
