//
//  MarathonCard.swift
//  PlayFeat
//  Created by kyky on 17/11/26.
//
//  The upgrade cards offered between marathon rounds, with the prototype's
//  prices and effects. Each can be bought once; Faster Grill II needs
//  Faster Grill I. Which cards a planet's Buffet deals is its Deck: the
//  first breaks offer set hands, swapping a card that can't be bought for
//  the next one from the fallback list; after them the fallback list alone
//  deals.
//

import Foundation

nonisolated enum MarathonCard: String, CaseIterable, Hashable {
    case fasterGrill1
    case fasterGrill2
    case secondGrillSpot
    case cozySeats
    case blazingPepper
    case royalMushroom
    case doubleTentacle
    case slimierSlime
    case goldenFlatbread
    case fasterPot

    enum Effect: Equatable {
        case cookSec(CookingTool.Kind, TimeInterval)
        case grillSlots(Int)
        case patienceScale(Double)
        case ingredientValue(String, Int)
    }

    static let cardsPerBreak = 3
    /// Cook time never drops below this, nor patience stretch above the max.
    static let minCookSec: TimeInterval = 3
    static let maxPatienceScale = 1.2

    var price: Int {
        switch self {
        // ponytail: the pot's price waits on the balancing sheet; Faster Grill I's for now.
        case .fasterGrill1, .fasterPot: 40
        case .fasterGrill2: 60
        case .secondGrillSpot: 65
        case .cozySeats: 50
        case .blazingPepper: 35
        case .royalMushroom: 30
        case .doubleTentacle, .slimierSlime: 25
        case .goldenFlatbread: 45
        }
    }

    /// The card that has to be bought first, if any.
    var needs: MarathonCard? { self == .fasterGrill2 ? .fasterGrill1 : nil }

    var effect: Effect {
        switch self {
        case .fasterGrill1: .cookSec(.grill, 4.5)
        case .fasterGrill2: .cookSec(.grill, 3)
        case .fasterPot: .cookSec(.pot, 4.5)
        case .secondGrillSpot: .grillSlots(2)
        case .cozySeats: .patienceScale(1.2)
        case .blazingPepper: .ingredientValue(KitchenMenu.pepper, 18)
        case .royalMushroom: .ingredientValue(KitchenMenu.mushroom, 24)
        case .doubleTentacle: .ingredientValue(KitchenMenu.tentacle, 17)
        case .slimierSlime: .ingredientValue(KitchenMenu.slime, 12)
        case .goldenFlatbread: .ingredientValue(KitchenMenu.rawFlatbread, 16)
        }
    }

    /// Whether `owned` cards leave this one for sale.
    func isAvailable(owning owned: Set<MarathonCard>) -> Bool {
        !owned.contains(self) && (needs.map(owned.contains) ?? true)
    }

    // MARK: - Offers

    /// The cards one planet's Buffet deals.
    struct Deck {
        /// The hands of the first breaks, in order.
        let setOffers: [[MarathonCard]]
        /// Stand-ins for a set card that can't be bought, then every later hand.
        let fallback: [MarathonCard]

        /// The cards offered at break `number` (from 1).
        func offer(forBreak number: Int, owning owned: Set<MarathonCard>) -> [MarathonCard] {
            var offer: [MarathonCard] = []
            func canAdd(_ card: MarathonCard) -> Bool { card.isAvailable(owning: owned) && !offer.contains(card) }

            guard setOffers.indices.contains(number - 1) else {
                return Array(fallback.filter(canAdd).prefix(cardsPerBreak))
            }
            
            let hand = setOffers[number - 1]
            for card in hand {
                if canAdd(card) {
                    offer.append(card)
                } else if let stand = fallback.first(where: { canAdd($0) && !hand.contains($0) }) {
                    offer.append(stand)
                }
            }
            return offer
        }
    }
}
