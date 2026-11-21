//
//  ServeAreas.swift
//  PlayFeat
//  Created by kyky on 13/11/26.
//
//  Handing a finished dish to a customer. Each position has an invisible
//  serve area: the alien and its order bubble, each by its own shape. The
//  player serves by opening their hand there; carrying a dish through it
//  serves nothing. The dish they ordered is handed over. Any other dish, or
//  anything lifted off a plate or glass (a flatbread missing its topping),
//  is turned away with a red cross and falls. The payment and the customer
//  leaving are KitchenDay's.
//

import SpriteKit

extension KitchenScene {

    /// The customer a let-go `node` is handed to, if it is offered as a dish
    /// in a customer's serve area. Where two areas overlap, the customer who
    /// wants the dish wins.
    func customerSeat(around node: KitchenBubbleNode) -> Int? {
        guard let day, isOfferedAsDish(node) else { return nil }
        let reached = KitchenLayout.seats.indices.filter { seat in
            day.isOccupied(seat) && serveArea(of: seat, contains: node.position)
        }
        return reached.first { day.wants(node.ingredient, at: $0) } ?? reached.first
    }

    /// A finished dish, or anything served up off a plate or glass. A bare
    /// ingredient from the air just falls past the customers.
    private func isOfferedAsDish(_ node: KitchenBubbleNode) -> Bool {
        KitchenMenu.isDish(node.ingredient) || (node.liftedFrom?.isForAssembly ?? false)
    }

    /// The seat whose serve area holds `point` and whose customer ordered
    /// `dish`: where a carried dish would be served.
    func seat(wanting dish: String, around point: CGPoint, in day: KitchenDay) -> Int? {
        KitchenLayout.seats.indices.first { seat in
            day.wants(dish, at: seat) && serveArea(of: seat, contains: point)
        }
    }

    /// Whether the scene point `point` is in the serve area of `seat` as
    /// placed on this screen.
    private func serveArea(of seat: Int, contains point: CGPoint) -> Bool {
        layout.seat(at: seat).serveAreaContains(layout.artPoint(fromScene: point))
    }

    /// Serves the customer at `seat` if they ordered `node`; otherwise the
    /// dish is turned away and falls.
    func serveOrReject(_ node: KitchenBubbleNode, at seat: Int) {
        if let day, let customer = day.presentCustomers.first(where: { $0.seat == seat }),
           day.serve(node.ingredient, at: seat) {
            if day.isRunning, !day.isRoundOver { tutorial?.served(node.ingredient, to: customer) }
            audio?.play(.putOrder)
            if day.lastTip > 0 { audio?.play(.tip) }
            handOver(node, to: seat)
        } else {
            audio?.play(.wrongIngredient)
            showCross(at: layout.sceneRect(layout.seat(at: seat).orderSheet).center)
            hangThenFall(node)
        }
    }

    /// The dish is drawn slowly into the alien, shrinking as it goes, then
    /// fades away; the customer leaves after it (KitchenBackdrop).
    private func handOver(_ node: KitchenBubbleNode, to seat: Int) {
        bubbles.removeAll { $0 === node }
        node.removeAllActions()
        let alien = layout.sceneRect(layout.seat(at: seat).alien).center
        let pullTime = KitchenRules.handOverSec * 0.75
        let vanishTime = KitchenRules.handOverSec - pullTime
        let pull = SKAction.move(to: alien, duration: pullTime)
        pull.timingMode = .easeInEaseOut
        node.run(.sequence([
            .group([pull, .scale(to: Self.parkedScale, duration: pullTime)]),
            .group([.scale(to: 0.1, duration: vanishTime), .fadeOut(withDuration: vanishTime)]),
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
