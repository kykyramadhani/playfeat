//
//  FuelFlightPlan.swift
//  PlayFeat
//  Created by Owen Limantoro on 19/11/26.
//
//  The order the planet board flies newly earned stars from their level
//  cards to the fuel gauge, one at a time, and how full the gauge is before
//  the first lands and after each one. Pure, so the board only animates it.
//

nonisolated struct FuelFlightPlan: Equatable {
    struct Flight: Equatable {
        let levelIndex: Int
        /// Which of the level card's stars flies: 0 is the first.
        let starIndex: Int
        /// The planet's progress once this star has landed in the gauge.
        let progressAfter: PlanetProgress
    }

    /// The planet's progress as the gauge shows it before any star lands.
    let progressBefore: PlanetProgress
    let flights: [Flight]

    /// The flights for `deliveries` on a planet whose levels are
    /// `levelIDs`, ending at its saved `progress`. Deliveries for another
    /// planet's levels are left out.
    init(progress: PlanetProgress, levelIDs: [String], deliveries: [StarDelivery]) {
        let landings = deliveries.compactMap { delivery in
            levelIDs.firstIndex(of: delivery.levelID).map { (index: $0, previousBest: delivery.previousBest) }
        }
        var bestStars = progress.bestStars
        for landing in landings {
            bestStars[landing.index] = min(bestStars[landing.index], landing.previousBest)
        }
        progressBefore = PlanetProgress(bestStars: bestStars)

        var flights: [Flight] = []
        for landing in landings {
            while bestStars[landing.index] < progress.bestStars[landing.index] {
                let starIndex = bestStars[landing.index]
                bestStars[landing.index] += 1
                flights.append(Flight(
                    levelIndex: landing.index,
                    starIndex: starIndex,
                    progressAfter: PlanetProgress(bestStars: bestStars)
                ))
            }
        }
        self.flights = flights
    }
}
