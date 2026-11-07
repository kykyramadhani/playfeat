//
//  StorageTableTests.swift
//  PlayFeatTests
//  Created by kyky on 07/11/26.
//
//  One item per slot; taking an item (to the trash or the grill) frees it.
//

import Testing
@testable import PlayFeat

struct StorageTableTests {

    @Test func placedItemsStayUntilTaken() throws {
        var table = StorageTable<String>(slotCount: 2)
        try table.place("emberPepper", in: 0)

        #expect(table.firstEmptySlot == 1)
        let taken = try table.take(from: 0)
        #expect(taken == "emberPepper")
        #expect(table.firstEmptySlot == 0)
    }

    @Test func aSlotHoldsOnlyOneItem() throws {
        var table = StorageTable<String>(slotCount: 2)
        try table.place("emberPepper", in: 1)

        #expect(throws: StorageTableError.slotTaken(1)) { try table.place("duskFlatbread", in: 1) }
    }

    @Test func aLevelWithNoSlotsHasNoTable() {
        var table = StorageTable<String>(slotCount: 0)

        #expect(table.firstEmptySlot == nil)
        #expect(throws: StorageTableError.noSuchSlot(0)) { try table.place("emberPepper", in: 0) }
    }
}
