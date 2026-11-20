//
//  HandPointerLayer.swift
//  PlayFeat
//  Created by Owen Limantoro on 20/11/26.
//
//  The player's hands as pointers over the end-of-day and Buffet screens,
//  so someone seated too far from the iPad to touch it can still press a
//  button: point a hand at it (it lights up) and pinch. Drawn on top of
//  everything and ignores touches, so tapping still works as usual.
//

import SwiftUI

struct HandPointerLayer: View {
    /// The buttons that can be pressed, from `HandClickTargets`.
    let targets: [HandClickTarget]

    @Environment(HandPoseManager.self) private var handPoseManager
    @State private var detector = PinchClickDetector()

    /// The drawn hand's size, in design points: about as big as the
    /// kitchen's hand cursors.
    private static let pointerSize: CGFloat = 150
    /// How far the highlight sits outside a pointed-at button.
    private static let highlightInset: CGFloat = -8

    var body: some View {
        GeometryReader { proxy in
            let buttons = targets.map { proxy[$0.bounds] }
            let handsNow = pointers(in: proxy.size)
            ZStack(alignment: .topLeading) {
                ForEach(highlighted(buttons, by: handsNow), id: \.self) { index in
                    highlight(around: buttons[index])
                }
                ForEach(handPoseManager.hands) { hand in
                    HandPointer(
                        isPinching: hand.isClosedFist,
                        mirror: HandCursorNode.artMirror(for: hand.chirality),
                        size: Self.pointerSize * DesignCanvas.scale(for: proxy.size)
                    )
                    .position(handPoseManager.cursor(for: hand, in: proxy.size))
                }
            }
            .onChange(of: handPoseManager.hands) {
                pressButton(by: pointers(in: proxy.size), among: buttons)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func pointers(in size: CGSize) -> [PinchClickDetector.Pointer] {
        handPoseManager.hands.map { hand in
            PinchClickDetector.Pointer(
                handID: hand.id,
                location: handPoseManager.cursor(for: hand, in: size),
                isPinching: hand.isClosedFist
            )
        }
    }

    private func highlighted(_ buttons: [CGRect], by pointers: [PinchClickDetector.Pointer]) -> [Int] {
        Array(Set(pointers.compactMap { PinchClickDetector.target(at: $0.location, in: buttons) })).sorted()
    }

    private func highlight(around button: CGRect) -> some View {
        let frame = button.insetBy(dx: Self.highlightInset, dy: Self.highlightInset)
        return RoundedRectangle(cornerRadius: frame.height / 2)
            .stroke(Color.white, lineWidth: 6)
            .shadow(color: .black.opacity(0.35), radius: 4)
            .frame(width: frame.width, height: frame.height)
            .position(x: frame.midX, y: frame.midY)
    }

    private func pressButton(by pointers: [PinchClickDetector.Pointer], among buttons: [CGRect]) {
        guard let pressed = detector.press(by: pointers, on: buttons),
              targets.indices.contains(pressed) else { return }
        targets[pressed].press()
    }
}

/// The kitchen's cartoon hand, open or pinching, with its palm on the point
/// it is placed at.
private struct HandPointer: View {
    let isPinching: Bool
    /// 1 for the art as drawn, -1 mirrored (see `HandCursorNode`).
    let mirror: CGFloat
    let size: CGFloat

    /// The palm's centre in the art, from the top-left (`HandCursorNode`
    /// measures it from the bottom-left).
    private static let palm = UnitPoint(x: 0.49, y: 0.575)

    var body: some View {
        Image(isPinching ? HandCursorNode.pinchArt : HandCursorNode.openArt)
            .resizable()
            .scaledToFit()
            .scaleEffect(x: mirror, y: 1)
            .frame(width: size, height: size)
            .offset(x: (0.5 - Self.palm.x) * size * mirror, y: (0.5 - Self.palm.y) * size)
            .scaleEffect(isPinching ? 0.9 : 1)
            .animation(.easeOut(duration: 0.1), value: isPinching)
    }
}
