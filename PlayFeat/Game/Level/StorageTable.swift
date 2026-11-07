//
//  StorageTable.swift
//  PlayFeat
//  Created by kyky on 07/11/26.
//
//  The table that parks one item per slot: an ingredient, a baked flatbread
//  or a finished dish. Items here never fall, burn or expire, so the table
//  only has to remember what sits where. Clearing a slot is done by carrying
//  the item to the trash bin, which is just `take(from:)`.
//

nonisolated enum StorageTableError: Error, Equatable {
    case noSuchSlot(Int)
    case slotTaken(Int)
    case slotEmpty(Int)
}

nonisolated struct StorageTable<Item> {
    private(set) var slots: [Item?]

    init(slotCount: Int) {
        slots = Array(repeating: nil, count: max(slotCount, 0))
    }

    var firstEmptySlot: Int? { slots.firstIndex { $0 == nil } }

    mutating func place(_ item: Item, in slot: Int) throws(StorageTableError) {
        guard slots.indices.contains(slot) else { throw .noSuchSlot(slot) }
        guard slots[slot] == nil else { throw .slotTaken(slot) }
        slots[slot] = item
    }

    /// Lifts the item off `slot` and returns it.
    mutating func take(from slot: Int) throws(StorageTableError) -> Item {
        guard slots.indices.contains(slot) else { throw .noSuchSlot(slot) }
        guard let item = slots[slot] else { throw .slotEmpty(slot) }
        slots[slot] = nil
        return item
    }
}
