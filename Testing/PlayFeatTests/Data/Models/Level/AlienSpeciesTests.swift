//
//  AlienSpeciesTests.swift
//  PlayFeatTests
//  Created by Owen Limantoro on 18/11/26.
//
//  Which mood picture a customer shows as their patience runs out, and
//  which aliens each planet seats.
//

import Testing
@testable import PlayFeat

struct AlienSpeciesTests {

    /// Patience zones from the level design: over 50% green, 20–50% yellow,
    /// under 20% red; phases 1, 2 and 3.
    @Test(arguments: [(0.8, "AlienRegular1"), (0.5, "AlienRegular2"), (0.2, "AlienRegular2"), (0.1, "AlienRegular3")])
    func theMoodFollowsThePatienceLeft(patienceLeft: Double, imageName: String) {
        let zone = KitchenRules.PatienceZone(patienceLeft: patienceLeft)

        #expect(AlienSpecies.regular.imageName(in: zone) == imageName)
    }

    @Test func planetOneSeatsRegularAliensAndAnAngrySquare() {
        let kitchen = Planet.kepler186f.kitchen

        #expect(kitchen.alien(for: .regular) == .regular)
        #expect(kitchen.alien(for: .angry) == .square)
    }

    @Test func planetTwoSeatsTriangleAliensAndAnAngrySquare() {
        let kitchen = Planet.k2332b.kitchen

        #expect(kitchen.alien(for: .regular) == .triangle)
        #expect(kitchen.alien(for: .angry) == .square)
    }
}
