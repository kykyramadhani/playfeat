//
//  ServeAreas.swift
//  PlayFeat
//  Created by kyky on 13/11/26.
//
//  Handing a finished dish to a customer. Each seat has an invisible serve
//  area around the alien and its order sheet; a dish let go with its centre
//  anywhere in there goes to that customer, as long as it is what they
//  ordered. The payment and the customer leaving are KitchenDay's.
//

import SpriteKit

extension KitchenScene {

    /// Serves `node` if it was let go in the serve area of a customer who
    /// ordered it. Where two areas overlap, the customer who wants the dish wins.
    /// - Returns: whether it was served; if not, the caller settles it as usual.
    func serve(_ node: KitchenBubbleNode) -> Bool {
        guard let day,
              let seat = seat(wanting: node.ingredient, around: node.position, in: day),
              day.serve(node.ingredient, at: seat) else { return false }

        audio?.play(.putOrder)
        handOver(node, to: seat)
        return true
    }

    /// The seat whose serve area holds `point` and whose customer ordered `dish`.
    func seat(wanting dish: String, around point: CGPoint, in day: KitchenDay) -> Int? {
        KitchenLayout.seats.indices.first { seat in
            day.wants(dish, at: seat)
                && layout.sceneRect(KitchenLayout.seats[seat].serveArea).contains(point)
        }
    }

    /// The dish glides into the customer's order sheet and is gone.
    private func handOver(_ node: KitchenBubbleNode, to seat: Int) {
        bubbles.removeAll { $0 === node }
        node.removeAllActions()
        let sheet = layout.sceneRect(KitchenLayout.seats[seat].orderSheet).center
        node.run(.sequence([
            .group([.move(to: sheet, duration: 0.2), .scale(to: Self.parkedScale, duration: 0.2)]),
            .group([.scale(to: 0.1, duration: 0.15), .fadeOut(withDuration: 0.15)]),
            .removeFromParent(),
        ]))
    }
}
