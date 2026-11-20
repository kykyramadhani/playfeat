//
//  CounterLayout.swift
//  PlayFeat
//  Created by Owen Limantoro on 20/11/26.
//
//  Where one planet's counter puts its cooking tools and its two kinds of
//  station (the plate and glass, or the noodle bowl and cookie plate), in
//  the art points of KitchenLayout, and how those stations are drawn. A
//  planet can lay its counter out differently on the early levels that
//  have fewer tools out (`PlanetKitchen.counter(on:)`).
//

import CoreGraphics

nonisolated struct CounterLayout: Equatable {
    /// Where each cooking tool stands.
    private let toolAreas: [CookingTool.Kind: CGRect]
    /// Main-station spots, in the order the stations come out: the one the
    /// day starts with, then one bought in the shop or earned in a marathon.
    private let mainSpots: [CGRect]
    /// Dessert-station spots, in the order the stations come out.
    private let dessertSpots: [CGRect]
    /// The picture of an empty main station and of an empty dessert station.
    let mainStationImage: String
    let dessertStationImage: String

    init(
        toolAreas: [CookingTool.Kind: CGRect],
        mainSpots: [CGRect],
        dessertSpots: [CGRect],
        stationImages: (main: String, dessert: String)
    ) {
        self.toolAreas = toolAreas
        self.mainSpots = mainSpots
        self.dessertSpots = dessertSpots
        mainStationImage = stationImages.main
        dessertStationImage = stationImages.dessert
    }

    // MARK: - Cooking tools

    /// The cooking tools laid out on this counter.
    var tools: Set<CookingTool.Kind> { Set(toolAreas.keys) }

    /// Where `tool` stands; `.null`, which nothing lands on, when this
    /// counter has no spot for it.
    func area(of tool: CookingTool.Kind) -> CGRect {
        toolAreas[tool] ?? .null
    }

    /// Where each of `count` items cooks on `tool`, left to right: around
    /// the grill's hot ring, or in the middle of the pot.
    func cookingSpots(on tool: CookingTool.Kind, count: Int) -> [CGPoint] {
        let area = area(of: tool)
        switch tool {
        case .grill: return Self.grillSlots(count, aroundRing: Self.grillRing(in: area))
        case .pot: return [area.center]
        }
    }

    /// The middle of the grill's hot ring, where food cooks. The grill is
    /// drawn in perspective, so it sits up and left of the box's centre.
    static func grillRing(in grill: CGRect) -> CGPoint {
        CGPoint(x: grill.minX + grillRingOffset.width, y: grill.minY + grillRingOffset.height)
    }

    /// Where each of `count` items cooks, spread left to right around `ring`.
    static func grillSlots(_ count: Int, aroundRing ring: CGPoint) -> [CGPoint] {
        guard count > 1 else { return [ring] }
        let start = ring.x - grillSlotGap * CGFloat(count - 1) / 2
        return (0..<count).map { CGPoint(x: start + grillSlotGap * CGFloat($0), y: ring.y) }
    }

    /// The hot ring's centre measured from the grill art's top-left corner.
    private static let grillRingOffset = CGSize(width: 168, height: 58)
    /// How far apart two items sit when the grill holds two.
    private static let grillSlotGap: CGFloat = 110

    // MARK: - Stations

    var maxMainStations: Int { mainSpots.count }
    var maxDessertStations: Int { dessertSpots.count }

    /// Where `count` main stations stand, in the order they came out; never
    /// more than the counter has spots for.
    func mainStationSpots(count: Int) -> [CGRect] {
        Array(mainSpots.prefix(count.clamped(to: 0...maxMainStations)))
    }

    /// Where `count` dessert stations stand, in the order they came out;
    /// never more than the counter has spots for.
    func dessertStationSpots(count: Int) -> [CGRect] {
        Array(dessertSpots.prefix(count.clamped(to: 0...maxDessertStations)))
    }
}

// MARK: - Station sizes

nonisolated extension CounterLayout {
    /// Planet 2's noodle bowl and its pot on the stove, as big as the team's
    /// counter frames draw them on every level. Pictures of the bowl or pot
    /// with food in it are sized to match (`KitchenArt.wholeStationScale`).
    static let noodleBowlSize = CGSize(width: 166, height: 108)
    static let potSize = CGSize(width: 316, height: 270)
}
