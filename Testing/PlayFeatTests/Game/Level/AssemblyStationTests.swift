//
//  AssemblyStationTests.swift
//  PlayFeatTests
//  Created by Owen Limantoro on 12/11/26.
//
//  The plate and the glass: what each takes, in any order, and the dish the
//  ingredients become once they make a recipe.
//

import Testing
@testable import PlayFeat

struct AssemblyStationTests {

    private typealias Menu = KitchenMenu

    // MARK: - Plate

    @Test(arguments: [Menu.bakedFlatbread, Menu.pepper, Menu.mushroom])
    func anEmptyPlateTakesEachOfItsIngredients(item: String) {
        #expect(AssemblyStation.plate.accepts(item))
    }

    /// Raw flatbread must be grilled first, and burnt flatbread is no use.
    @Test(arguments: [Menu.rawFlatbread, Menu.burntFlatbread, Menu.slime, Menu.tentacle])
    func thePlateRefusesAnythingElse(item: String) {
        #expect(!AssemblyStation.plate.accepts(item))
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

    @Test func twoToppingsWithoutBreadMakeNothing() throws {
        var plate = AssemblyStation.plate
        try plate.add(Menu.pepper)
        try plate.add(Menu.mushroom)

        #expect(plate.completedDish == nil)
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

    @Test func slimeAndTentacleMakeTheSorbet() throws {
        var glass = AssemblyStation.glass
        try glass.add(Menu.tentacle)
        try glass.add(Menu.slime)

        #expect(glass.completedDish == Menu.sunsetSorbet)
    }

    @Test(arguments: [Menu.pepper, Menu.mushroom, Menu.bakedFlatbread, Menu.rawFlatbread])
    func theGlassTakesDrinkIngredientsOnly(item: String) {
        #expect(!AssemblyStation.glass.accepts(item))
    }
}
