//
//  TurnedEllipse.swift
//  PlayFeat
//  Created by Owen Limantoro on 21/11/26.
//
//  An oval turned about its centre, for hit areas that follow a drawn round
//  shape (a customer's order bubble) instead of the box around it.
//

import CoreGraphics
import Foundation

nonisolated struct TurnedEllipse: Equatable {
    let center: CGPoint
    /// Half its width and half its height, before it is turned.
    let radii: CGSize
    /// Clockwise on a y-down screen, the same way SwiftUI's `rotationEffect` turns.
    let degrees: Double

    /// Whether `point` is inside the oval or on its edge.
    func contains(_ point: CGPoint) -> Bool {
        guard radii.width > 0, radii.height > 0 else { return false }
        let local = unturned(point)
        let x = local.x / radii.width
        let y = local.y / radii.height
        return x * x + y * y <= 1
    }

    /// `point` relative to the centre, turned back so the oval is level.
    private func unturned(_ point: CGPoint) -> CGPoint {
        let angle = -degrees * .pi / 180
        let dx = point.x - center.x
        let dy = point.y - center.y
        return CGPoint(x: dx * cos(angle) - dy * sin(angle), y: dx * sin(angle) + dy * cos(angle))
    }
}
