//
//  HandCursorNodeTests.swift
//  PlayFeatTests
//  Created by Owen Limantoro on 15/11/26.
//
//  The cartoon hand drawn over each tracked hand: which way round it is
//  drawn, and that its art is in the catalog.
//

import CoreGraphics
import SpriteKit
import Testing
import UIKit
import Vision
@testable import PlayFeat

@MainActor
struct HandCursorNodeTests {

    @Test(arguments: [VNChirality.left, .right])
    func chiralityControlsTheArtworkOnEitherHalfOfTheScreen(chirality: VNChirality) throws {
        let cursor = HandCursorNode(chirality: chirality, bubbleRadius: 80)

        for x: CGFloat in [300, 700] {
            cursor.position = CGPoint(x: x, y: 350)
            cursor.setChirality(chirality)
            let art = try #require(cursor.children.first as? SKSpriteNode)
            #expect(art.xScale == (chirality == .left ? -1 : 1))
        }
    }

    @Test(arguments: [VNChirality.left, .right])
    func unknownChiralityKeepsTheArtworkAndHeldFoodPosition(chirality: VNChirality) throws {
        let cursor = HandCursorNode(chirality: chirality, bubbleRadius: 80)
        cursor.position = CGPoint(x: 500, y: 350)
        let previousPinch = cursor.heldItemPosition

        cursor.setChirality(.unknown)

        let art = try #require(cursor.children.first as? SKSpriteNode)
        #expect(art.xScale == (chirality == .left ? -1 : 1))
        #expect(cursor.heldItemPosition == previousPinch)
    }

    @Test func aKnownReadingUpdatesBothTheArtworkAndHeldFoodPosition() throws {
        let cursor = HandCursorNode(chirality: .right, bubbleRadius: 80)
        let rightPinch = cursor.heldItemPosition

        cursor.setChirality(.left)

        let art = try #require(cursor.children.first as? SKSpriteNode)
        #expect(art.xScale == -1)
        #expect(cursor.heldItemPosition.x == -rightPinch.x)
        #expect(cursor.heldItemPosition.y == rightPinch.y)
    }

    @Test func anInitiallyUnknownCursorUsesDefaultArtUntilIdentified() throws {
        let cursor = HandCursorNode(chirality: .unknown, bubbleRadius: 80)
        let art = try #require(cursor.children.first as? SKSpriteNode)
        #expect(art.xScale == 1)

        cursor.setChirality(.left)

        #expect(art.xScale == -1)
    }

    /// A missing image would leave the player's hands invisible during play.
    @Test(arguments: [HandCursorNode.openArt, HandCursorNode.pinchArt])
    func theHandArtExists(name: String) {
        #expect(UIImage(named: name) != nil, "missing hand art '\(name)'")
    }
}

/// Held food sits in the drawn hand's pinch: up from the palm and toward
/// the thumb side, independent of where the hand is on screen.
struct HandCursorPinchOffsetTests {

    @Test func aRightHandHoldsFoodUpAndToTheLeftOfThePalm() {
        let offset = HandCursorNode.pinchOffset(chirality: .right, bubbleRadius: 80)

        #expect(offset.dx < 0)
        #expect(offset.dy > 0)
    }

    @Test func aLeftHandHoldsFoodAtTheMirroredSpot() {
        let right = HandCursorNode.pinchOffset(chirality: .right, bubbleRadius: 80)
        let left = HandCursorNode.pinchOffset(chirality: .left, bubbleRadius: 80)

        #expect(left.dx == -right.dx)
        #expect(left.dy == right.dy)
    }

    @Test func theOffsetGrowsWithTheHand() {
        let small = HandCursorNode.pinchOffset(chirality: .right, bubbleRadius: 40)
        let large = HandCursorNode.pinchOffset(chirality: .right, bubbleRadius: 80)

        #expect(large.dy == small.dy * 2)
    }
}
