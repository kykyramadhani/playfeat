import Foundation

/// Translates changes in the kitchen into sounds, once per transition rather
/// than once per rendered frame. The scene supplies its authoritative clock.
final class KitchenSoundscape {
    private struct CustomerID: Hashable {
        let seat: Int
        let arrived: TimeInterval
        init(_ customer: SeatedCustomer) {
            seat = customer.seat
            arrived = customer.seatedAt
        }
    }

    private struct SlotID: Hashable {
        let tool: CookingTool.Kind
        let index: Int
    }

    private struct CookingState {
        let placedAt: TimeInterval
        let doneness: CookingTool.Doneness
    }

    private weak var sounds: (any SoundPlaying)?
    private var customers: Set<CustomerID> = []
    private var warned: Set<CustomerID> = []
    private var missed = 0
    private var cooking: [SlotID: CookingState] = [:]

    init(sounds: any SoundPlaying) { self.sounds = sounds }

    func update(day: KitchenDay, cookers: [CookingTool.Kind: CookingTool]) {
        guard day.isRunning, !day.isOver, !day.isRoundOver else {
            stopLoops()
            // A final loss can end the run on this frame.
            announceLosses(day.ordersMissed)
            return
        }

        let present = Set(day.presentCustomers.map(CustomerID.init))
        for customer in day.presentCustomers {
            let id = CustomerID(customer)
            if !customers.contains(id) {
                sounds?.play(customer.type == .angry ? .angryArrive : .customerArrive)
            }
            if customer.patienceLeft(at: day.elapsed) < KitchenRules.PatienceZone.redBelow,
               !warned.contains(id) {
                sounds?.play(.patienceRed)
                warned.insert(id)
            }
        }
        customers = present
        warned.formIntersection(present)
        announceLosses(day.ordersMissed)
        updateCooking(cookers, at: day.elapsed)
    }

    private func announceLosses(_ count: Int) {
        for _ in missed..<max(missed, count) { sounds?.play(.customerLeaves) }
        missed = count
    }

    private func updateCooking(_ cookers: [CookingTool.Kind: CookingTool], at now: TimeInterval) {
        var next: [SlotID: CookingState] = [:]
        for tool in CookingTool.Kind.allCases {
            let cooker = cookers[tool]
            var isCooking = false
            var isWarning = false
            for index in cooker?.slots.indices ?? 0..<0 {
                guard let slot = cooker?.slots[index],
                      let state = cooker?.doneness(onSlot: index, at: now) else { continue }
                let id = SlotID(tool: tool, index: index)
                if let before = cooking[id], before.placedAt == slot.placedAt {
                    if before.doneness == .cooking, state == .cooked || state == .overcooking {
                        sounds?.play(.bakeReady)
                    }
                    if before.doneness != .ruined, state == .ruined { sounds?.play(.bakeBurnt) }
                }
                isCooking = isCooking || state == .cooking
                isWarning = isWarning || state.needsWarning
                next[id] = CookingState(placedAt: slot.placedAt, doneness: state)
            }
            syncLoop(tool == .pot ? .boilingPot : .bakeLoop, key: "kitchen.\(tool.rawValue).cooking", active: isCooking)
            syncLoop(.bakeWarning, key: "kitchen.\(tool.rawValue).warning", active: isWarning)
        }
        cooking = next
    }

    private func syncLoop(_ effect: SoundEffect, key: String, active: Bool) {
        if active { sounds?.startLoop(effect, key: key) } else { sounds?.stopLoop(key: key) }
    }

    func stopLoops() {
        for tool in CookingTool.Kind.allCases {
            sounds?.stopLoop(key: "kitchen.\(tool.rawValue).cooking")
            sounds?.stopLoop(key: "kitchen.\(tool.rawValue).warning")
        }
    }

    func clearCooking() {
        stopLoops()
        cooking.removeAll()
    }
}
