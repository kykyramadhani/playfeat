//
//  Stations.swift
//  PlayFeat
//  Created by Owen Limantoro on 12/11/26.
//
//  The kitchen's stations as the scene sees them: where each one takes a
//  dropped item, putting items down and lifting them off, the cooking tools
//  (grill, pot) cooking what sits on them, the plates and glasses turning
//  their ingredients into a dish, and the counter growing a plate or glass
//  mid-marathon. The rules themselves are in `CookingTool` and
//  `AssemblyStation`.
//

import SpriteKit

extension KitchenScene {

    // MARK: - Dropping onto a station

    /// The station that takes `node` where it is now, if any: the one the
    /// green glow lights.
    func station(taking node: KitchenBubbleNode) -> KitchenBubbleNode.Placement? {
        station(under: node).flatMap { accepts(node.ingredient, on: $0) ? $0 : nil }
    }

    /// The station `node` is over, whether or not it would take it. A drop
    /// counts when the item's centre is within half a bubble of the station,
    /// since the stations are drawn smaller than the bubbles carried to them.
    /// Over a cooking tool, it is the free slot nearest the item, else the
    /// nearest slot (whose item the new one would swap out).
    func station(under node: KitchenBubbleNode) -> KitchenBubbleNode.Placement? {
        if let tool = cookers.keys.sorted().first(where: {
            dropArea(of: area(of: $0)).contains(node.position)
        }) {
            return .cooker(tool, slot: cookingSlot(on: tool, nearest: node.position))
        }
        let vessels = plates.indices.map { KitchenBubbleNode.Placement.plate($0) }
            + glasses.indices.map { KitchenBubbleNode.Placement.glass($0) }
        return vessels
            .filter { dropArea(of: artRect(of: $0)).contains(node.position) }
            .min { centre(of: $0).distance(to: node.position) < centre(of: $1).distance(to: node.position) }
    }

    /// Every station on the counter: the cooking tools' slots, then the
    /// plates and glasses.
    var stations: [KitchenBubbleNode.Placement] {
        cookingSlots + plates.indices.map { .plate($0) } + glasses.indices.map { .glass($0) }
    }

    /// Every slot of every cooking tool, tool by tool.
    var cookingSlots: [KitchenBubbleNode.Placement] {
        cookers.sorted { $0.key < $1.key }.flatMap { tool, cooker in
            cooker.slots.indices.map { KitchenBubbleNode.Placement.cooker(tool, slot: $0) }
        }
    }

    /// Where `station` is drawn, in art points. Every slot of a cooking tool
    /// is the whole tool.
    func artRect(of station: KitchenBubbleNode.Placement) -> CGRect {
        switch station {
        case .cooker(let tool, _): area(of: tool)
        case .plate(let index): plateSpots[index]
        case .glass(let index): glassSpots[index]
        }
    }

    /// Where `tool` stands on the day's counter.
    private func area(of tool: CookingTool.Kind) -> CGRect {
        counter?.area(of: tool) ?? .null
    }

    /// Where the plates and glasses stand, in art points, in the order they came out.
    var plateSpots: [CGRect] { counter?.mainStationSpots(count: plates.count) ?? [] }
    var glassSpots: [CGRect] { counter?.dessertStationSpots(count: glasses.count) ?? [] }

    /// The picture `station` is drawn with on the day's counter.
    func stationImage(of station: KitchenBubbleNode.Placement) -> String {
        switch station {
        case .cooker(let kind, _): KitchenArt.image(of: kind)
        case .plate: counter?.mainStationImage ?? ""
        case .glass: counter?.dessertStationImage ?? ""
        }
    }

    func accepts(_ item: String, on station: KitchenBubbleNode.Placement) -> Bool {
        switch station {
        case .cooker(let tool, _): cookers[tool]?.accepts(item) ?? false
        case .plate, .glass: assembly(at: station)?.accepts(item) ?? false
        }
    }

    private func dropArea(of artRect: CGRect) -> CGRect {
        let slack = bubbleRadius * 0.5
        return layout.sceneRect(artRect).insetBy(dx: -slack, dy: -slack)
    }

    private func cookingSlot(on tool: CookingTool.Kind, nearest point: CGPoint) -> Int {
        guard let cooker = cookers[tool] else { return 0 }
        func distance(_ slot: Int) -> CGFloat { centre(of: .cooker(tool, slot: slot)).distance(to: point) }
        let byDistance = cooker.slots.indices.sorted { distance($0) < distance($1) }
        return byDistance.first { !cooker.isTaken($0) } ?? byDistance.first ?? 0
    }

    /// Puts `node` down on `station`. Call only with a station that accepts
    /// it; anything it then refuses falls instead. An item put on a taken
    /// cooking slot knocks the one there off, to fall.
    func put(_ node: KitchenBubbleNode, on station: KitchenBubbleNode.Placement) {
        let now = day?.elapsed ?? 0
        if case .cooker(let tool, let slot) = station, var cooker = cookers[tool] {
            knockOff(from: station)
            let cookedBefore = cooker.cookedBefore(node.ingredient, remembered: node.cookedSeconds)
            cooker.place(node.ingredient, onSlot: slot, at: now, cookedBefore: cookedBefore)
            cookers[tool] = cooker
        } else {
            do {
                try changeAssembly(at: station) { try $0.add(node.ingredient) }
            } catch {
                drop(node)
                return
            }
        }

        setDown(node, at: station, position: centre(of: station))
        // Later items sit on top: the topping over the bread.
        let stackHeight = assembly(at: station)?.contents.count ?? 1
        node.zPosition = 2 + CGFloat(stackHeight) * 0.1
        combineIfComplete(station)
    }

    /// Whatever sits on `station` pops off and falls from there.
    private func knockOff(from station: KitchenBubbleNode.Placement) {
        for old in bubbles where old.placement == station {
            unpark(old)
            old.position = centre(of: station)
            old.fallingSince = day?.elapsed ?? 0
        }
    }

    /// Over the item on a cooking tool, under anything carried.
    static let cookingGaugeZ: CGFloat = 3

    // MARK: - Lifting off

    /// Takes `node` off the station it sits on, as the hand picks it up.
    func liftOffStation(_ node: KitchenBubbleNode, at station: KitchenBubbleNode.Placement) {
        if case .cooker(let tool, let slot) = station {
            node.cookedSeconds = cookers[tool]?.cookedSeconds(onSlot: slot, at: day?.elapsed ?? 0)
            cookers[tool]?.clear(slot)
            node.setWarning(false)
        } else {
            // The node sits there, so it is in the contents; nothing to recover from.
            try? changeAssembly(at: station) { try $0.remove(node.ingredient) }
        }
    }

    // MARK: - Cooking tools

    /// Cooks, warns about and ruins what sits on the cooking tools as play
    /// time passes, with the cooking ring around each.
    func updateCookers(now: TimeInterval) {
        for food in bubbles {
            guard case .cooker(let tool, let slot) = food.placement, let cooker = cookers[tool],
                  let item = cooker.item(onSlot: slot, at: now),
                  let doneness = cooker.doneness(onSlot: slot, at: now) else { continue }
            food.become(item)
            food.setWarning(doneness.needsWarning)
        }
        updateCookingGauges(now: now)
    }

    /// A ring around every slot with something on it; none around an empty one.
    private func updateCookingGauges(now: TimeInterval) {
        for slot in cookingSlots {
            guard case .cooker(let tool, let index) = slot,
                  let gauge = cookers[tool]?.gauge(onSlot: index, at: now) else {
                cookingGauges[slot]?.removeFromParent()
                cookingGauges[slot] = nil
                continue
            }
            let ring = cookingGauges[slot] ?? {
                let ring = GrillGaugeNode(scale: layout.scale)
                ring.zPosition = Self.cookingGaugeZ
                addChild(ring)
                cookingGauges[slot] = ring
                return ring
            }()
            ring.position = centre(of: slot)
            ring.show(gauge)
        }
    }

    // MARK: - Plates and glasses coming out

    /// Sets out any plate or glass the day has gained since the last frame,
    /// as many as the counter has spots for.
    func syncTools() {
        guard let tools = day?.tools, let kitchen, let counter else { return }
        let newPlates = min(tools.plates, counter.maxMainStations) - plates.count
        if newPlates > 0 {
            plates += Array(repeating: kitchen.mainStation, count: newPlates)
        }
        let newGlasses = min(tools.glasses, counter.maxDessertStations) - glasses.count
        if newGlasses > 0 {
            glasses += Array(repeating: kitchen.dessertStation, count: newGlasses)
        }
    }

    // MARK: - Dishes

    /// Once a plate or glass holds a full recipe, its ingredients are
    /// replaced by the finished dish, which can be picked up as one item.
    private func combineIfComplete(_ station: KitchenBubbleNode.Placement) {
        guard let dish = assembly(at: station)?.completedDish else { return }
        changeAssembly(at: station) { $0.combine() }

        for ingredient in bubbles.filter({ $0.placement == station }) {
            remove(ingredient)
        }

        let dishNode = KitchenBubbleNode(ingredient: dish, radius: bubbleRadius, upgraded: upgradedIngredients)
        dishNode.position = centre(of: station)
        dishNode.placement = station
        dishNode.setScale(dishNode.placedScale)
        addChild(dishNode)
        bubbles.append(dishNode)
    }

    /// The rules of the plate or glass at `station`; nil for a cooking tool.
    func assembly(at station: KitchenBubbleNode.Placement) -> AssemblyStation? {
        switch station {
        case .cooker: nil
        case .plate(let index): plates[index]
        case .glass(let index): glasses[index]
        }
    }

    /// Applies `change` to the plate or glass at `station`; a cooking tool
    /// has no assembly, so nothing happens there.
    private func changeAssembly<Failure: Error>(
        at station: KitchenBubbleNode.Placement,
        _ change: (inout AssemblyStation) throws(Failure) -> Void
    ) throws(Failure) {
        switch station {
        case .cooker: return
        case .plate(let index): try change(&plates[index])
        case .glass(let index): try change(&glasses[index])
        }
    }

    func centre(of station: KitchenBubbleNode.Placement) -> CGPoint {
        switch station {
        case .cooker(let tool, let slot):
            // Cooking tools only exist once the day, and so its counter, is set.
            let slotCount = cookers[tool]?.slots.count ?? 1
            guard let spots = counter?.cookingSpots(on: tool, count: slotCount) else { return .zero }
            return layout.scenePoint(spots[min(slot, spots.count - 1)])
        case .plate, .glass:
            return layout.sceneRect(artRect(of: station)).center
        }
    }
}
