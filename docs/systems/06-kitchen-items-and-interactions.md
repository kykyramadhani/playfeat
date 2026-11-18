# Kitchen items and interactions

## Item identity is separate from artwork

Kitchen gameplay uses string IDs centralized in `KitchenMenu`. These IDs appear in level JSON, recipe rules, supply logic, item nodes and scoring. `KitchenArt` translates IDs into image asset names. Do not use an asset filename as an ingredient ID unless the mapping explicitly says so.

| Meaning | Gameplay ID | Main artwork |
|---|---|---|
| Raw flatbread | `duskFlatbread` | `FlatbreadRaw` |
| Baked flatbread | `bakedFlatbread` | `FlatbreadBaked` |
| Burnt flatbread | `burntFlatbread` | `FlatbreadBurnt` |
| Pepper | `emberPepper` | `Pepper` |
| Mushroom | `duskMushroom` | `GlowyMushroom` |
| Tentacle | `tentacle` | `KitchenTentacle` |
| Slime | `slime` | `GreenMugDrink` placeholder |
| Pepper dish | `pepperFlatbread` | `PepperFlatbread` |
| Mushroom dish | `mushroomFlatbread` | `MushroomFlatbread` |
| Glass dessert | `slimyTentacles` | `SlimyTentaclesGlass` |

Placed mushroom art changes to `MushroomTopping`; a placed tentacle becomes `TentacleGlass`. Whole-glass images use special sizing so the depicted mug lines up with the counter glass. Premium images exist among assets, but the reviewed `KitchenArt` mapping does not automatically select a premium image when a pricing upgrade is bought.

## Recipes and pricing ingredients

```text
bakedFlatbread + emberPepper  → pepperFlatbread
bakedFlatbread + duskMushroom → mushroomFlatbread
slime + tentacle             → slimyTentacles
```

`KitchenMenu.dish(madeFrom:)` requires an exact ingredient set and rejects duplicate input items. Recipe assembly is order-independent where the station placement rules allow both orders.

For scoring and supply demand, a baked flatbread maps back to its raw bubble ingredient. Default ingredient values are raw flatbread 10, pepper 10, mushroom 15, tentacle 10 and slime 5. `DishPricing` sums a dish's bubble ingredients, so default dish values are 20, 25 and 15 respectively, before tips.

## Node and rules state

`KitchenBubbleNode` represents both a drifting bubble and the food eventually placed on a station. It remembers its ingredient, radius, holder ID, optional placement, optional falling start time, lane and remembered cooking time. `become` changes the item and redraws it. The bubble shell and placed art are presentation, not authoritative recipe rules.

Placement is `.grill(slot)`, `.plate(index)` or `.glass(index)`. The current kitchen has no storage-box inventory subsystem: items are carried, placed, falling, refused, or served. `AssemblyStation` owns plate/glass contents; `Grill` owns cooking timers. The scene connects those rules to nodes.

## One hand update, step by step

1. Read each published hand and convert cursor/joints from view to scene coordinates.
2. Create or update its `HandCursorNode`, including remembered chirality and selected grip state.
3. Stop gameplay interaction unless the day is running and neither the day nor the marathon round is over.
4. Detect a transition into the active grip. If the hand is empty, find the nearest eligible free item touched by any recognized joint or cursor, within item radius plus `grabSlack` (30 scene points).
5. Lift a placed item off its station, mark it held by the hand ID and clear its falling state.
6. Ease the item toward the cartoon hand's drawn pinch, clamped inside the scene.
7. If a carried completed dish reaches a customer who wants it, serve magnetically without requiring release.
8. Otherwise, release only after a continuously neutral/open grip lasts `releaseDelay = 0.1` seconds.

Current kitchen `dragSmoothing` is 0.5, converted from a per-60-Hz fraction into a frame-delta-aware easing fraction by `GameScene.easing`. This is additional to upstream palm smoothing. Cursor movement and carried-food movement therefore have different latency sources.

An uncertain grip does not count as deliberate opening. Vanished held hands have scene-level grace, currently 0.35 seconds. Upstream identity coasting is a separate grace layer; their effects can accumulate. Paused/ended interaction drops held items through the normal settle logic when that handling runs.

## Release target priority

`settle` first clears the holder and then resolves:

1. A completed dish in an occupied customer's serve area: serve it if correct, otherwise reject/remove it with a red cross.
2. A station under the item: place it if accepted, otherwise show refusal feedback and let it fall after a short hold.
3. No target: drop it; an item already behind the table is removed immediately.

The target helper and green tool glow share station rules so a highlighted acceptable station corresponds to an actual placement. Customer areas remain visually invisible. Rejected station items hang for `refuseHoldSec = 0.3` seconds, cannot be immediately grabbed again, and trigger a red shake and error sound.

## Plate and glass assembly

An empty plate can hold raw/baked flatbread, a topping, or a completed flatbread dish. A raw flatbread can sit on a plate but cannot combine into a recipe. A baked flatbread plus pepper/mushroom combines in either accepted order. The glass accepts slime, tentacle or the completed dessert, with slime and tentacle combining in either order.

The rules object first accepts the ingredient and detects a completed recipe. The scene replaces the participating ingredient nodes with one completed-dish node at the same station. Lifting an item removes it from the station's rules state; removing only its drawing would leave a phantom ingredient behind.

Story tools come from saved ownership, with glasses suppressed on levels whose `cups` is false. Marathon tools grow during a run. Adding a second plate inserts a new leftmost plate, and existing node placement indices are shifted to match.

## Cooking and burning

A raw flatbread bakes in 6 seconds by default. The grill remembers previously cooked seconds when bread is lifted and replaced. Placing valid bread on an occupied grill slot knocks the old item off rather than adding two items to one slot.

With burn multiplier 1:

- Before 6 seconds: raw/cooking.
- From 6 seconds: baked and usable.
- From 14 seconds: overcooking/glowing.
- From 18 seconds: burnt and unusable in recipes.

Generally, glow time is `bakeSec + 8 × multiplier` and burn time is `bakeSec + 12 × multiplier`. The gauge's about-to-burn warning uses a separate final-three-second rule. All of these use day play time, so a pause does not burn food in the background.

## Serving

Customers have serve rectangles around their alien/order sheet. A carried dish can be magnetically pulled into a matching customer's expanded reach. Releasing in overlapping areas prefers a customer requesting that dish. A successful handover updates `KitchenDay`, removes the node from active scene bookkeeping, animates it into the order sheet and plays the order sound.

## Source map and tests

- [Item/recipe IDs](../../PlayFeat/Game/Level/KitchenMenu.swift), [art mapping](../../PlayFeat/Data/Models/KitchenArt.swift), [pricing](../../PlayFeat/Game/Level/DishPricing.swift)
- [Item node](../../PlayFeat/Scenes/Nodes/KitchenBubbleNode.swift), [hand interactions](../../PlayFeat/Scenes/KitchenScene/Hands.swift)
- [Station integration](../../PlayFeat/Scenes/KitchenScene/Stations.swift), [station rules](../../PlayFeat/Game/Level/AssemblyStation.swift), [grill](../../PlayFeat/Game/Level/Grill.swift)
- [Serving](../../PlayFeat/Scenes/KitchenScene/ServeAreas.swift), [drop feedback](../../PlayFeat/Scenes/KitchenScene/DropTargets.swift)
- [Station tests](../../Testing/PlayFeatTests/Scenes/KitchenScene/KitchenStationTests.swift), [serving tests](../../Testing/PlayFeatTests/Scenes/KitchenScene/KitchenServingTests.swift), [grill tests](../../Testing/PlayFeatTests/Game/Level/GrillTests.swift)

Related: [hand tracking](03-hand-tracking-and-gestures.md), [supply](07-bubble-supply-and-physics.md), [shop](09-shop-and-economy.md). [Back to index](README.md).
