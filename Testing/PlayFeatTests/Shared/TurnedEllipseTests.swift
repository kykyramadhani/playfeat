//
//  TurnedEllipseTests.swift
//  PlayFeatTests
//  Created by Owen Limantoro on 21/11/26.
//

import CoreGraphics
import Testing
@testable import PlayFeat

struct TurnedEllipseTests {

    /// 200 wide and 100 tall, centred on the origin.
    private func oval(turnedBy degrees: Double) -> TurnedEllipse {
        TurnedEllipse(center: .zero, radii: CGSize(width: 100, height: 50), degrees: degrees)
    }

    @Test func aLevelOvalHoldsItsCentreAndTheEndsOfItsLongSide() {
        let level = oval(turnedBy: 0)

        #expect(level.contains(.zero))
        #expect(level.contains(CGPoint(x: 99, y: 0)))
        #expect(level.contains(CGPoint(x: -99, y: 0)))
    }

    /// The corners of the box around an oval are outside it.
    @Test func theCornersOfItsBoxAreOutside() {
        #expect(!oval(turnedBy: 0).contains(CGPoint(x: 90, y: 45)))
    }

    /// Turned a quarter clockwise, the long side stands upright.
    @Test func aQuarterTurnStandsTheLongSideUpright() {
        let upright = oval(turnedBy: 90)

        #expect(upright.contains(CGPoint(x: 0, y: 99)))
        #expect(!upright.contains(CGPoint(x: 99, y: 0)))
    }

    /// Clockwise on a y-down screen: the right end of the long side swings
    /// down, below the centre.
    @Test func itTurnsClockwiseOnAYDownScreen() {
        let tilted = oval(turnedBy: 30)

        #expect(tilted.contains(CGPoint(x: 70, y: 40)))
        #expect(!tilted.contains(CGPoint(x: 70, y: -40)))
    }

    @Test func anOvalWithNoSizeHoldsNothing() {
        let flat = TurnedEllipse(center: .zero, radii: .zero, degrees: 0)

        #expect(!flat.contains(.zero))
    }
}
