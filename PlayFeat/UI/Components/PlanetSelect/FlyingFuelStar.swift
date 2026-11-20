//
//  FlyingFuelStar.swift
//  PlayFeat
//  Created by Owen Limantoro on 19/11/26.
//
//  A star the player just earned, arcing from its level card into the
//  fuel gauge's star and shrinking to the gauge's size on the way.
//

import SwiftUI

struct FlyingFuelStar: View {
    let start: CGPoint
    let end: CGPoint
    /// Flips to true to send the star on its way; animate the change.
    let hasLanded: Bool

    /// How far above the higher end the arc's control point is pulled.
    private static let arcLift: CGFloat = 220

    var body: some View {
        Image("LevelStar")
            .resizable()
            .foregroundStyle(Color.starYellow)
            .frame(width: starSize, height: starSize)
            .rotationEffect(.degrees(hasLanded ? 360 : 0))
            .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
            .modifier(ArcPosition(progress: hasLanded ? 1 : 0, start: start, end: end))
            .accessibilityHidden(true)
    }

    private var starSize: CGFloat {
        hasLanded ? FuelGauge.starSize : LevelCard.starSize
    }

    /// The point `progress` (0 to 1) of the way along the arc from `start`
    /// to `end`: a curve bowing up over both ends.
    nonisolated static func point(at progress: CGFloat, from start: CGPoint, to end: CGPoint) -> CGPoint {
        let control = CGPoint(x: (start.x + end.x) / 2, y: min(start.y, end.y) - arcLift)
        let rest = 1 - progress
        return CGPoint(
            x: rest * rest * start.x + 2 * rest * progress * control.x + progress * progress * end.x,
            y: rest * rest * start.y + 2 * rest * progress * control.y + progress * progress * end.y
        )
    }
}

/// Animates the star along the arc rather than straight across, since
/// SwiftUI only interpolates a plain `.position` in a line.
private struct ArcPosition: ViewModifier, Animatable {
    var progress: CGFloat
    let start: CGPoint
    let end: CGPoint

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content.position(FlyingFuelStar.point(at: progress, from: start, to: end))
    }
}

#Preview {
    @Previewable @State var hasLanded = false

    FlyingFuelStar(start: CGPoint(x: 600, y: 300), end: CGPoint(x: 100, y: 400), hasLanded: hasLanded)
        .frame(width: 700, height: 500)
        .background(Color.purple300)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: false)) { hasLanded = true }
        }
}
