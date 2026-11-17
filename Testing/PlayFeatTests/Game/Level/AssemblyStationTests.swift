//
//  AssemblyStationTests.swift
//  PlayFeatTests
//  Created by Owen Limantoro on 12/11/26.
//
//  The plate and the glass, by the prototype's placement table: what each
//  takes, in either order, and the dish a base and a topping become.
//

import Testing
@testable import PlayFeat

struct AssemblyStationTests {

    private typealias Menu = KitchenMenu

    // MARK: - Plate

    /// A raw flatbread may sit on an empty plate too, though nothing goes on it.
    @Test(arguments: [Menu.bakedFlatbread, Menu.rawFlatbread, Menu.pepper, Menu.mushroom])
    func anEmptyPlateTakesEachOfItsIngredients(item: String) {
        #expect(AssemblyStation.plate.accepts(item))
    }

    /// Burnt flatbread is no use, and the dessert's are the glass's.
    @Test(arguments: [Menu.burntFlatbread, Menu.slime, Menu.tentacle])
    func thePlateRefusesAnythingElse(item: String) {
        #expect(!AssemblyStation.plate.accepts(item))
    }

    @Test func nothingGoesOnARawFlatbread() throws {
        var plate = AssemblyStation.plate
        try plate.add(Menu.rawFlatbread)

        #expect(!plate.accepts(Menu.pepper))
        #expect(!plate.accepts(Menu.bakedFlatbread))
    }

    @Test func thePlateTakesOneOfEachIngredient() throws {
        var plate = AssemblyStation.plate
        try plate.add(Menu.pepper)

        #expect(!plate.accepts(Menu.pepper))
    }

    @Test func bakedFlatbreadAndPepperMakeAPepperFlatbread() throws {
        var plate = AssemblyStation.plate
        try plate.add(Menu.bakedFlatbread)
        try plate.add(Menu.pepper)

        #expect(plate.completedDish == Menu.pepperFlatbread)
    }

    /// Any order: the topping first works just as well.
    @Test func theToppingCanGoOnBeforeTheBread() throws {
        var plate = AssemblyStation.plate
        try plate.add(Menu.mushroom)
        try plate.add(Menu.bakedFlatbread)

        #expect(plate.completedDish == Menu.mushroomFlatbread)
    }

    /// A topping only takes the baked bread on top, never a second topping.
    @Test func aToppingTakesOnlyTheBread() throws {
        var plate = AssemblyStation.plate
        try plate.add(Menu.pepper)

        #expect(!plate.accepts(Menu.mushroom))
        #expect(plate.accepts(Menu.bakedFlatbread))
    }

    @Test func combiningLeavesOnlyTheDish() throws {
        var plate = AssemblyStation.plate
        try plate.add(Menu.bakedFlatbread)
        try plate.add(Menu.pepper)

        plate.combine()

        #expect(plate.contents == [Menu.pepperFlatbread])
        #expect(!plate.accepts(Menu.mushroom))
    }

    /// A dish carried off can be put back, but only on an empty plate.
    @Test func aDishGoesBackOnlyOnAnEmptyPlate() throws {
        var plate = AssemblyStation.plate
        #expect(plate.accepts(Menu.pepperFlatbread))

        try plate.add(Menu.pepper)

        #expect(!plate.accepts(Menu.pepperFlatbread))
    }

    @Test func liftingAnIngredientOffMakesRoomForItAgain() throws {
        var plate = AssemblyStation.plate
        try plate.add(Menu.pepper)

        try plate.remove(Menu.pepper)

        #expect(plate.accepts(Menu.pepper))
    }

    @Test func addingARefusedItemSaysWhich() {
        var plate = AssemblyStation.plate

        #expect(throws: AssemblyStationError.refused(Menu.slime)) {
            try plate.add(Menu.slime)
        }
    }

    // MARK: - Glass

    @Test func aTentacleThenSlimeMakeTheSlimyTentacles() throws {
        var glass = AssemblyStation.glass
        try glass.add(Menu.tentacle)
        try glass.add(Menu.slime)

        #expect(glass.completedDish == Menu.slimyTentacles)
    }

    /// As in the prototype, the slime can go in first too.
    @Test func slimeThenATentacleMakeTheDessertToo() throws {
        var glass = AssemblyStation.glass
        try glass.add(Menu.slime)
        try glass.add(Menu.tentacle)

        #expect(glass.completedDish == Menu.slimyTentacles)
    }

    /// The plate has no order: a topping can wait there for the bread.
    @Test func thePlateTakesItsIngredientsInAnyOrder() {
        #expect(AssemblyStation.plate.accepts(Menu.pepper))
        #expect(AssemblyStation.plate.accepts(Menu.bakedFlatbread))
    }

    @Test(arguments: [Menu.pepper, Menu.mushroom, Menu.bakedFlatbread, Menu.rawFlatbread])
    func theGlassTakesDrinkIngredientsOnly(item: String) {
        #expect(!AssemblyStation.glass.accepts(item))
    }
}
