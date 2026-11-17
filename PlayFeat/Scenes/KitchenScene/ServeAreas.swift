//
//  ServeAreas.swift
//  PlayFeat
//  Created by kyky on 13/11/26.
//
//  Handing a finished dish to a customer. Each position has an invisible
//  serve area around the alien and its order sheet. A dish let go in there
//  goes to that customer: the dish they ordered is served; any other dish
//  is turned away with a red cross and lost, as in the prototype. The
//  payment and the customer leaving are KitchenDay's.
//

import SpriteKit

extension KitchenScene {

    /// The customer a let-go `node` is handed to, if it is a dish let go in
    /// a customer's serve area. Where two areas overlap, the customer who
    /// wants the dish wins.
    func customerSeat(around node: KitchenBubbleNode) -> Int? {
        guard let day, KitchenMenu.recipes[node.ingredient] != nil else { return nil }
        let reached = KitchenLayout.seats.indices.filter { seat in
            day.isOccupied(seat) && layout.sceneRect(KitchenLayout.seats[seat].serveArea).contains(node.position)
        }
        return reached.first { day.wants(node.ingredient, at: $0) } ?? reached.first
    }

    /// The seat whose serve area holds `point` and whose customer ordered
    /// `dish`: where a carried dish would be served.
    func seat(wanting dish: String, around point: CGPoint, in day: KitchenDay) -> Int? {
        KitchenLayout.seats.indices.first { seat in
            day.wants(dish, at: seat)
                && layout.sceneRect(KitchenLayout.seats[seat].serveArea).contains(point)
        }
    }

    /// Serves the customer at `seat` if they ordered `node`; otherwise the
    /// dish is turned away and lost.
    func serveOrReject(_ node: KitchenBubbleNode, at seat: Int) {
        if let day, day.serve(node.ingredient, at: seat) {
            audio?.play(.putOrder)
            handOver(node, to: seat)
        } else {
            audio?.play(.wrongIngredient)
            showCross(at: layout.sceneRect(KitchenLayout.seats[seat].orderSheet).center)
            remove(node)
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

    /// A red cross that rises and fades over a customer who got the wrong dish.
    private func showCross(at point: CGPoint) {
        let cross = SKLabelNode(text: "✗")
        cross.fontName = Atkinson.bold
        cross.fontSize = bubbleRadius * 1.1
        cross.fontColor = UIColor(named: "PatienceLow") ?? .red
        cross.verticalAlignmentMode = .center
        cross.position = point
        cross.zPosition = Self.heldZ + 1
        addChild(cross)
        cross.run(.sequence([
            .group([.moveBy(x: 0, y: bubbleRadius * 0.6, duration: 0.8), .fadeOut(withDuration: 0.8)]),
            .removeFromParent(),
        ]))
    }
}
