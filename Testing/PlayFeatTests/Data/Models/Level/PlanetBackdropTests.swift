//
//  PlanetBackdropTests.swift
//  PlayFeatTests
//  Created by Owen Limantoro on 18/11/26.
//
//  Where each kind of landscape layer lands on screens of different shapes.
//

import CoreGraphics
import Testing
@testable import PlayFeat

struct PlanetBackdropTests {
    private let artShape = CGSize(width: 1366, height: 1024)
    private let macBook = CGSize(width: 1512, height: 945)

    @Test(arguments: [PlanetBackdrop.Fit.cover, .groundBand, .bottomLeading, .bottomTrailing, .topTrailing])
    func onAScreenTheArtsShapeEveryLayerFillsItExactly(fit: PlanetBackdrop.Fit) {
        #expect(fit.frame(in: artShape) == CGRect(origin: .zero, size: artShape))
    }

    @Test func theSkyCoversAWideScreenCutEvenlyTopAndBottom() {
        let frame = PlanetBackdrop.Fit.cover.frame(in: macBook)

        #expect(frame.width == macBook.width)
        #expect(frame.midY.isApproximately(macBook.height / 2))
    }

    @Test func theGroundReachesTheBottomAndBothSidesOfAWideScreen() {
        let frame = PlanetBackdrop.Fit.groundBand.frame(in: macBook)

        #expect(frame.minX == 0 && frame.maxX == macBook.width)
        #expect(frame.maxY.isApproximately(macBook.height))
    }

    @Test func aPinnedPropFitsWholeAndHugsItsCorner() {
        let frame = PlanetBackdrop.Fit.bottomTrailing.frame(in: macBook)

        #expect(frame.height == macBook.height)
        #expect(frame.maxX.isApproximately(macBook.width))
        #expect(frame.minY == 0)
    }

    @Test func onATallerScreenTheGroundStillKeepsTheBottom() {
        let squareish = CGSize(width: 1000, height: 1000)
        let frame = PlanetBackdrop.Fit.groundBand.frame(in: squareish)

        #expect(frame.height == squareish.height)
        #expect(frame.midX.isApproximately(squareish.width / 2))
    }
}

private extension CGFloat {
    func isApproximately(_ other: CGFloat) -> Bool { abs(self - other) < 0.001 }
}
