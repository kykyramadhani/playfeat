//
//  FuelStarFlightsTests.swift
//  PlayFeatTests
//  Created by Owen Limantoro on 24/11/26.
//
//  The chime each landing star plays: a run of stars climbs in pitch.
//

import Testing
@testable import PlayFeat

struct FuelStarFlightsTests {

    @Test func theFirstStarChimesAtItsNormalPitch() {
        #expect(FuelStarFlights.chimeSemitones(forLanding: 0) == 0)
    }

    @Test func eachStarChimesHalfASemitoneAboveTheOneBefore() {
        let chimes = (0..<6).map { FuelStarFlights.chimeSemitones(forLanding: $0) }

        #expect(chimes == [0, 0.5, 1, 1.5, 2, 2.5])
    }

    @Test func theChimeStopsClimbingAtTwoAndAHalfSemitones() {
        #expect(FuelStarFlights.chimeSemitones(forLanding: 9) == 2.5)
    }
}
