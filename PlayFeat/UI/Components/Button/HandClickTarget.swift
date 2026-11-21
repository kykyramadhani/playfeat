//
//  HandClickTarget.swift
//  PlayFeat
//  Created by Owen Limantoro on 20/11/26.
//
//  Lets a button be pressed by pinching over it. Every ClickButton offers
//  itself as a target, but only inside a view marked `acceptsHandClicks()`:
//  the end-of-day and Buffet screens, which a seated player may be too far
//  away to touch. HandPointerLayer collects the targets and presses them.
//

import SwiftUI

/// A button on screen and what pressing it does.
struct HandClickTarget {
    let bounds: Anchor<CGRect>
    let press: () -> Void
}

/// Every hand-pressable button in a view tree, in drawing order.
nonisolated struct HandClickTargets: PreferenceKey {
    static var defaultValue: [HandClickTarget] { [] }

    static func reduce(value: inout [HandClickTarget], nextValue: () -> [HandClickTarget]) {
        value += nextValue()
    }
}

extension EnvironmentValues {
    /// Whether buttons here can be pressed by pinching over them.
    @Entry var acceptsHandClicks = false
}

extension View {
    /// Lets the buttons in this view be pressed by pinching over them.
    func acceptsHandClicks() -> some View {
        environment(\.acceptsHandClicks, true)
    }

    /// Offers this view as a button that `press` presses, where the view
    /// accepts hand clicks and the button is enabled.
    func handClickTarget(press: @escaping () -> Void) -> some View {
        modifier(HandClickTargetModifier(press: press))
    }
}

private struct HandClickTargetModifier: ViewModifier {
    let press: () -> Void

    @Environment(\.acceptsHandClicks) private var acceptsHandClicks
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        content.anchorPreference(key: HandClickTargets.self, value: .bounds) { bounds in
            acceptsHandClicks && isEnabled ? [HandClickTarget(bounds: bounds, press: press)] : []
        }
    }
}
