//
//  FuelStarFlights.swift
//  PlayFeat
//  Created by Owen Limantoro on 19/11/26.
//
//  Plays a `FuelFlightPlan` over the planet board: after a day that earned
//  stars, each new star flies from its level card into the fuel gauge, one
//  at a time, and the gauge fills with a chime as each lands. With Reduce
//  Motion on, the stars don't fly; the gauge just fills, chime by chime.
//
//  The board marks its cards and gauge with `FuelFlightAnchors`.
//

import SwiftUI

struct FuelStarFlights: ViewModifier {
    let plan: FuelFlightPlan
    /// The progress the gauge shows; moved on as each star lands.
    @Binding var fuel: PlanetProgress

    @Environment(AudioManager.self) private var audio
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var flyingStar: FuelFlightPlan.Flight?
    @State private var hasLanded = false

    /// Lets the board settle in before the first star leaves.
    private static let firstTakeOffDelay: Duration = .seconds(0.7)
    private static let flightDuration = 0.8
    private static let gaugeFillDuration = 0.25
    /// Time for the gauge to fill before the next star leaves.
    private static let pauseAfterLanding: Duration = .seconds(0.3)
    /// Gives a new star one frame at its card before it's sent flying.
    private static let takeOffFrame: Duration = .milliseconds(30)

    func body(content: Content) -> some View {
        content
            .overlayPreferenceValue(FuelFlightAnchors.self) { anchors in
                GeometryReader { proxy in
                    if let flyingStar, let route = route(of: flyingStar, anchors: anchors, in: proxy) {
                        FlyingFuelStar(start: route.start, end: route.end, hasLanded: hasLanded)
                            .transition(.identity)
                    }
                }
                .allowsHitTesting(false)
            }
            .task(flyEveryStar)
    }

    // MARK: - Choreography

    private func flyEveryStar() async {
        guard !plan.flights.isEmpty else { return }
        do {
            try await Task.sleep(for: Self.firstTakeOffDelay)
            for flight in plan.flights {
                try await fly(flight)
            }
        } catch {
            // Leaving the board mid-flight: the saved progress is already
            // complete, so the next visit simply shows the full gauge.
            return
        }
    }

    private func fly(_ flight: FuelFlightPlan.Flight) async throws {
        if !reduceMotion {
            hasLanded = false
            flyingStar = flight
            try await Task.sleep(for: Self.takeOffFrame)
            withAnimation(.easeInOut(duration: Self.flightDuration)) { hasLanded = true }
            try await Task.sleep(for: .seconds(Self.flightDuration))
            flyingStar = nil
        }
        land(flight)
        try await Task.sleep(for: Self.pauseAfterLanding)
    }

    private func land(_ flight: FuelFlightPlan.Flight) {
        // Compress the entire fuel gurgle to the gauge-fill animation, with
        // pitch still randomized independently in -1...+2 semitones.
        audio.play(.gasCollected, duration: Self.gaugeFillDuration)
        withAnimation(.easeOut(duration: Self.gaugeFillDuration)) { fuel = flight.progressAfter }
    }

    // MARK: - Geometry

    private func route(
        of flight: FuelFlightPlan.Flight,
        anchors: FuelFlightAnchors.Value,
        in proxy: GeometryProxy
    ) -> (start: CGPoint, end: CGPoint)? {
        guard let card = anchors.cards[flight.levelIndex], let gauge = anchors.gauge else { return nil }
        return (
            start: offset(LevelCard.starCenter(flight.starIndex), by: proxy[card].origin),
            end: offset(FuelGauge.starCenter, by: proxy[gauge].origin)
        )
    }

    private func offset(_ point: CGPoint, by origin: CGPoint) -> CGPoint {
        CGPoint(x: origin.x + point.x, y: origin.y + point.y)
    }
}

extension View {
    /// Flies the stars in `plan` into the fuel gauge, moving `fuel` on as
    /// each one lands.
    func fuelStarFlights(_ plan: FuelFlightPlan, fuel: Binding<PlanetProgress>) -> some View {
        modifier(FuelStarFlights(plan: plan, fuel: fuel))
    }
}
