//
//  Stations.swift
//  PlayFeat
//  Created by Owen Limantoro on 12/11/26.
//
//  The kitchen's stations as the scene sees them: where each one takes a
//  dropped item, putting items down and lifting them off, the grill cooking
//  what sits on it, and the plate and glass turning their ingredients into a
//  dish. The rules themselves are in `Grill` and `AssemblyStation`.
//

import SpriteKit

extension KitchenScene {

    // MARK: - Dropping onto a station

    /// The station that takes `node` where it was let go, if any. A drop
    /// counts when the item's centre is within half a bubble of the station,
    /// since the stations are drawn smaller than the bubbles carried to them.
    func station(taking node: KitchenBubbleNode) -> KitchenBubbleNode.Placement? {
        let candidates: [(placement: KitchenBubbleNode.Placement, area: CGRect, accepts: Bool)] = [
            (.grill, KitchenLayout.grill, grill.accepts(node.ingredient)),
            (.plate, KitchenLayout.plate, plate.accepts(node.ingredient)),
            (.glass, KitchenLayout.glass, glass.accepts(node.ingredient)),
        ]
        return candidates.first { $0.accepts && dropArea(of: $0.area).contains(node.position) }?.placement
    }

    private func dropArea(of artRect: CGRect) -> CGRect {
        let slack = bubbleRadius * 0.5
        return layout.sceneRect(artRect).insetBy(dx: -slack, dy: -slack)
    }

    /// Puts `node` down on `station`. Call only with a station from
    /// `station(taking:)`; anything it then refuses falls instead.
    func put(_ node: KitchenBubbleNode, on station: KitchenBubbleNode.Placement) {
        if let assembly = assemblyStation(station) {
            do {
                try self[keyPath: assembly].add(node.ingredient)
            } catch {
                node.fallingSince = day?.elapsed ?? 0
                return
            }
        } else if station == .grill {
            grill.place(at: day?.elapsed ?? 0)
        } else {
            return
        }

        setDown(node, at: station, position: centre(of: station))
        // Later items sit on top: the topping over the bread.
        let stackHeight = assemblyStation(station).map { self[keyPath: $0].contents.count } ?? 1
        node.zPosition = 2 + CGFloat(stackHeight) * 0.1
        combineIfComplete(station)
    }

    // MARK: - Lifting off

    /// Takes `node` off the station it sits on, as the hand picks it up.
    func liftOffStation(_ node: KitchenBubbleNode, at station: KitchenBubbleNode.Placement) {
        if let assembly = assemblyStation(station) {
            // The node sits there, so it is in the contents; nothing to recover from.
            try? self[keyPath: assembly].remove(node.ingredient)
        } else if station == .grill {
            grill.clear()
            node.setWarning(false)
        }
    }

    // MARK: - Grill

    /// Bakes, warns about and burns the flatbread on the grill as play time
    /// passes.
    func updateGrill(now: TimeInterval) {
        guard let doneness = grill.doneness(at: now),
              let flatbread = bubbles.first(where: { $0.placement == .grill }) else { return }
        flatbread.become(doneness.item)
        flatbread.setWarning(doneness.needsWarning)
    }

    // MARK: - Dishes

    /// Once the plate or glass holds a full recipe, its ingredients are
    /// replaced by the finished dish, which can be picked up as one item.
    private func combineIfComplete(_ station: KitchenBubbleNode.Placement) {
        guard let assembly = assemblyStation(station),
              let dish = self[keyPath: assembly].completedDish else { return }
        self[keyPath: assembly].combine()

        for ingredient in bubbles.filter({ $0.placement == station }) {
            remove(ingredient)
        }

        let dishNode = KitchenBubbleNode(ingredient: dish, radius: bubbleRadius)
        dishNode.position = centre(of: station)
        dishNode.placement = station
        dishNode.setScale(Self.parkedScale)
        addChild(dishNode)
        bubbles.append(dishNode)
    }

    /// The plate's or glass's rules, for a station that assembles dishes.
    private func assemblyStation(
        _ station: KitchenBubbleNode.Placement
    ) -> ReferenceWritableKeyPath<KitchenScene, AssemblyStation>? {
        switch station {
        case .plate: \.plate
        case .glass: \.glass
        case .grill, .storage: nil
        }
    }

    private func centre(of station: KitchenBubbleNode.Placement) -> CGPoint {
        switch station {
        case .grill: layout.sceneRect(KitchenLayout.grill).center
        case .plate: layout.sceneRect(KitchenLayout.plate).center
        case .glass: layout.sceneRect(KitchenLayout.glass).center
        case .storage(let slot): layout.scenePoint(KitchenLayout.storageSlots[slot])
        }
    }
}
