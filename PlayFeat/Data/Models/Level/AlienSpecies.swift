//
//  AlienSpecies.swift
//  PlayFeat
//  Created by Owen Limantoro on 18/11/26.
//
//  The kinds of alien that come to the counter. Each is drawn in three
//  moods that follow the customer's patience zone: phase 1 while it's
//  green, 2 in the yellow and 3 in the red, as the level design's
//  patience zones table sets out.
//

nonisolated enum AlienSpecies: String, CaseIterable {
    /// The green alien, Planet 1's regular customer.
    case regular = "Regular"
    /// The red one-eyed alien, the angry customer on every planet.
    case square = "Square"
    /// Planet 2's regular customer.
    case triangle = "Triangle"

    /// This alien's picture for a customer whose patience is in `zone`.
    func imageName(in zone: KitchenRules.PatienceZone) -> String {
        "Alien\(rawValue)\(Self.phase(of: zone))"
    }

    /// The mood phase drawn for each patience zone, 1 to 3.
    private static func phase(of zone: KitchenRules.PatienceZone) -> Int {
        switch zone {
        case .green: 1
        case .yellow: 2
        case .red: 3
        }
    }
}
