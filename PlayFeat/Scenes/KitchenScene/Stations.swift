//
//  Stations.swift
//  PlayFeat
//  Created by Owen Limantoro on 12/11/26.
//
//  The kitchen's stations as the scene sees them: where each one takes a
//  dropped item, putting items down and lifting them off, the grill cooking
//  what sits on it, the plates and glasses turning their ingredients into a
//  dish, and the counter growing a plate or glass mid-marathon. The rules
//  themselves are in `Grill` and `AssemblyStation`.
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
    /// Over the grill, it is the free slot nearest the item, else the
    /// nearest slot (whose flatbread the item would swap out).
    func station(under node: KitchenBubbleNode) -> KitchenBubbleNode.Placement? {
        if dropArea(of: KitchenLayout.grill).contains(node.position) {
            return .grill(grillSlot(nearest: node.position))
        }
        let vessels = plates.indices.map { KitchenBubbleNode.Placement.plate($0) }
            + glasses.indices.map { KitchenBubbleNode.Placement.glass($0) }
        return vessels
            .filter { dropArea(of: artRect(of: $0)).contains(node.position) }
            .min { centre(of: $0).distance(to: node.position) < centre(of: $1).distance(to: node.position) }
    }

    /// Every station on the counter: the grill's slots, then the plates and glasses.
    var stations: [KitchenBubbleNode.Placement] {
        grill.slots.indices.map { .grill($0) } + plates.indices.map { .plate($0) } + glasses.indices.map { .glass($0) }
    }

    /// Where `station` is drawn, in art points. Every grill slot is the whole grill.
    func artRect(of station: KitchenBubbleNode.Placement) -> CGRect {
        switch station {
        case .grill: KitchenLayout.grill
        case .plate(let index): plateSpots[index]
        case .glass(let index): glassSpots[index]
        }
    }

    func accepts(_ item: String, on station: KitchenBubbleNode.Placement) -> Bool {
        assembly(at: station)?.accepts(item) ?? grill.accepts(item)
    }

    private func dropArea(of artRect: CGRect) -> CGRect {
        let slack = bubbleRadius * 0.5
        return layout.sceneRect(artRect).insetBy(dx: -slack, dy: -slack)
    }

    private func grillSlot(nearest point: CGPoint) -> Int {
        let slots = grill.slots.indices
        let byDistance = slots.sorted { centre(of: .grill($0)).distance(to: point) < centre(of: .grill($1)).distance(to: point) }
        return byDistance.first { !grill.isTaken($0) } ?? byDistance.first ?? 0
    }

    /// Puts `node` down on `station`. Call only with a station that accepts
    /// it; anything it then refuses falls instead. A flatbread put on a
    /// taken grill slot knocks the one there off, to fall.
    func put(_ node: KitchenBubbleNode, on station: KitchenBubbleNode.Placement) {
        let now = day?.elapsed ?? 0
        if case .grill(let slot) = station {
            knockOff(from: station)
            grill.place(onSlot: slot, at: now, cookedBefore: grill.cookedBefore(node.ingredient, remembered: node.cookedSeconds))
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

    /// Over the flatbread on the grill, under anything carried.
    static let grillGaugeZ: CGFloat = 3

    // MARK: - Lifting off

    /// Takes `node` off the station it sits on, as the hand picks it up.
    func liftOffStation(_ node: KitchenBubbleNode, at station: KitchenBubbleNode.Placement) {
        if case .grill(let slot) = station {
            node.cookedSeconds = grill.cookedSeconds(onSlot: slot, at: day?.elapsed ?? 0)
            grill.clear(slot)
            node.setWarning(false)
        } else {
            // The node sits there, so it is in the contents; nothing to recover from.
            try? changeAssembly(at: station) { try $0.remove(node.ingredient) }
        }
    }

    // MARK: - Grill

    /// Bakes, warns about and burns the flatbreads on the grill as play
    /// time passes, with the cooking ring around each.
    func updateGrill(now: TimeInterval) {
        for flatbread in bubbles {
            guard case .grill(let slot) = flatbread.placement,
                  let doneness = grill.doneness(onSlot: slot, at: now) else { continue }
            flatbread.become(doneness.item)
            flatbread.setWarning(doneness.needsWarning)
        }
        updateGrillGauges(now: now)
    }

    /// A ring around every slot with a flatbread on it; none around an empty one.
    private func updateGrillGauges(now: TimeInterval) {
        for slot in grill.slots.indices {
            guard let gauge = grill.gauge(onSlot: slot, at: now) else {
                grillGauges[slot]?.removeFromParent()
                grillGauges[slot] = nil
                continue
            }
            let ring = grillGauges[slot] ?? {
                let ring = GrillGaugeNode(scale: layout.scale)
                ring.zPosition = Self.grillGaugeZ
                addChild(ring)
                grillGauges[slot] = ring
                return ring
            }()
            ring.position = centre(of: .grill(slot))
            ring.show(gauge)
        }
    }

    // MARK: - Plates and glasses coming out

    /// Sets out any plate or glass the day has gained since the last frame.
    /// A second plate goes in on the far left, so the plates already there
    /// count one further along.
    func syncTools() {
        guard let tools = day?.tools else { return }
        let newPlates = tools.plates - plates.count
        if newPlates > 0 {
            for node in bubbles {
                if case .plate(let index) = node.placement { node.placement = .plate(index + newPlates) }
            }
            plates.insert(contentsOf: Array(repeating: .plate, count: newPlates), at: 0)
            plateSpots = KitchenLayout.plates(plates.count)
        }
        if tools.glasses > glasses.count {
            glasses += Array(repeating: .glass, count: tools.glasses - glasses.count)
            glassSpots = KitchenLayout.glasses(glasses.count)
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
        dishNode.setScale(Self.placedScale(on: station))
        addChild(dishNode)
        bubbles.append(dishNode)
    }

    /// The rules of the plate or glass at `station`; nil for the grill.
    func assembly(at station: KitchenBubbleNode.Placement) -> AssemblyStation? {
        switch station {
        case .grill: nil
        case .plate(let index): plates[index]
        case .glass(let index): glasses[index]
        }
    }

    /// Applies `change` to the plate or glass at `station`; the grill has
    /// no assembly, so nothing happens there.
    private func changeAssembly<Failure: Error>(
        at station: KitchenBubbleNode.Placement,
        _ change: (inout AssemblyStation) throws(Failure) -> Void
    ) throws(Failure) {
        switch station {
        case .grill: return
        case .plate(let index): try change(&plates[index])
        case .glass(let index): try change(&glasses[index])
        }
    }

    func centre(of station: KitchenBubbleNode.Placement) -> CGPoint {
        switch station {
        case .grill(let slot):
            let slots = KitchenLayout.grillSlots(grill.slots.count)
            return layout.scenePoint(slots[min(slot, slots.count - 1)])
        case .plate, .glass:
            return layout.sceneRect(artRect(of: station)).center
        }
    }
}
