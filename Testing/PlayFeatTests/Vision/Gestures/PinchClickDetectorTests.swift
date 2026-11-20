//
//  PinchClickDetectorTests.swift
//  PlayFeatTests
//  Created by Owen Limantoro on 20/11/26.
//
//  Pressing buttons by pinching over them: only the start of a pinch over
//  a button presses it.
//

import CoreGraphics
import Testing
@testable import PlayFeat

struct PinchClickDetectorTests {

    private let buttons = [
        CGRect(x: 0, y: 0, width: 100, height: 50),
        CGRect(x: 200, y: 0, width: 100, height: 50),
    ]
    private let overFirst = CGPoint(x: 50, y: 25)
    private let overSecond = CGPoint(x: 250, y: 25)
    private let overNothing = CGPoint(x: 150, y: 300)

    private func hand(_ id: Int = 0, at location: CGPoint, pinching: Bool) -> PinchClickDetector.Pointer {
        PinchClickDetector.Pointer(handID: id, location: location, isPinching: pinching)
    }

    @Test func pinchingOverAButtonPressesIt() {
        var detector = PinchClickDetector()
        _ = detector.press(by: [hand(at: overSecond, pinching: false)], on: buttons)

        let pressed = detector.press(by: [hand(at: overSecond, pinching: true)], on: buttons)

        #expect(pressed == 1)
    }

    @Test func holdingThePinchPressesOnlyOnce() {
        var detector = PinchClickDetector()
        _ = detector.press(by: [hand(at: overFirst, pinching: false)], on: buttons)
        _ = detector.press(by: [hand(at: overFirst, pinching: true)], on: buttons)

        let held = detector.press(by: [hand(at: overFirst, pinching: true)], on: buttons)

        #expect(held == nil)
    }

    @Test func draggingAPinchOntoAButtonPressesNothing() {
        var detector = PinchClickDetector()
        _ = detector.press(by: [hand(at: overNothing, pinching: false)], on: buttons)
        _ = detector.press(by: [hand(at: overNothing, pinching: true)], on: buttons)

        let dragged = detector.press(by: [hand(at: overFirst, pinching: true)], on: buttons)

        #expect(dragged == nil)
    }

    /// A hand that comes into view already pinching hasn't pinched yet.
    @Test func aHandFirstSeenPinchingPressesNothing() {
        var detector = PinchClickDetector()

        let pressed = detector.press(by: [hand(at: overFirst, pinching: true)], on: buttons)

        #expect(pressed == nil)
    }

    @Test func pinchingAgainAfterLettingGoPressesAgain() {
        var detector = PinchClickDetector()
        _ = detector.press(by: [hand(at: overFirst, pinching: false)], on: buttons)
        _ = detector.press(by: [hand(at: overFirst, pinching: true)], on: buttons)
        _ = detector.press(by: [hand(at: overFirst, pinching: false)], on: buttons)

        let again = detector.press(by: [hand(at: overFirst, pinching: true)], on: buttons)

        #expect(again == 0)
    }

    /// A hand that left and came back must start a new pinch in view.
    @Test func aHandThatLeftForgetsItsPinch() {
        var detector = PinchClickDetector()
        _ = detector.press(by: [hand(at: overFirst, pinching: false)], on: buttons)
        _ = detector.press(by: [], on: buttons)

        let back = detector.press(by: [hand(at: overFirst, pinching: true)], on: buttons)

        #expect(back == nil)
    }

    @Test func whereButtonsOverlapTheOneOnTopIsPressed() {
        let stacked = [CGRect(x: 0, y: 0, width: 300, height: 300), CGRect(x: 0, y: 0, width: 100, height: 100)]

        #expect(PinchClickDetector.target(at: CGPoint(x: 50, y: 50), in: stacked) == 1)
        #expect(PinchClickDetector.target(at: CGPoint(x: 200, y: 200), in: stacked) == 0)
    }
}
