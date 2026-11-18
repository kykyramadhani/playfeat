# Shop and economy

## Three different purchase systems

| System | Interface | Currency | Persistence |
|---|---|---|---|
| Permanent kitchen upgrades | `ShopPopup` on the planet board | Global `GameStorage.coins` | Upgrade levels in UserDefaults |
| Marathon break cards | `RoundCompleteOverlay` | Tips earned during the current marathon, minus spending | Only that `MarathonSession` |
| Classic coin multiplier | Legacy `ShopView` | Global coins | Multiplier count in SwiftData |

The same word "shop" does not mean these systems share ownership or effects. Permanent kitchen upgrades affect story-day construction. Marathon initializes its own pricing/tools and uses temporary cards. Classic multipliers affect the classic paycheck, not kitchen dish prices.

## Permanent kitchen catalog

`KitchenShop` defines `KitchenUpgrade` values. Each upgrade has an ID, ingredient/tools tab, artwork, stat kind, values by level, prices for each next level, and `availableAfter` story level ID.

Current upgrades have one purchasable step:

| Upgrade | ID | Before → after | Price | Requires a star on |
|---|---|---|---:|---|
| Raw flatbread value | `ingredient.duskFlatbread` | 10 → 16 | 45 | 1-1 |
| Pepper value | `ingredient.emberPepper` | 10 → 18 | 35 | 1-1 |
| Mushroom value | `ingredient.duskMushroom` | 15 → 24 | 30 | 1-2 |
| Tentacle value | `ingredient.tentacle` | 10 → 17 | 25 | 1-3 |
| Slime value | `ingredient.slime` | 5 → 12 | 25 | 1-3 |
| Plates | `tool.plate` | 1 → 2 | 30 | 1-1 |
| Glasses | `tool.glass` | 1 → 2 | 30 | 1-4 |

There is no permanent grill upgrade in this Kepler catalog. The model supports other stat kinds, but a type's capability does not mean a matching product is currently sold.

## Displaying an offer

`ShopPopup` receives cleared level IDs and snapshots the coin balance and saved upgrade levels. `KitchenUpgrade.isUnlocked` checks its prerequisite level. `ShopUpgrade.offer` then returns one of:

- `locked`: prerequisite unavailable or invalid current value index.
- `maxed(value)`: no further value/price step.
- `buy(from,to,price,canAfford)`: a valid next step, with affordability calculated from current coins.

`UpgradeCard` draws that state. It should not invent purchase logic from a button label or image.

## Purchase sequence

1. The player activates a valid, affordable buy offer.
2. `ShopPopup.buy` verifies the offer is `.buy(..., true)`.
3. `GameStorage.buyUpgrade` checks the current global balance, deducts the price and increments `upgrade_<id>`.
4. The popup reloads its coin and upgrade-level snapshots, whether the purchase succeeded or the purse changed meanwhile.
5. A later story kitchen constructs `GameStorage.dishPricing`, `kitchenPlates` and `kitchenGlasses` from those saved values.

The storage helper currently trusts its caller's ID and price. It checks available coins but does not independently enforce catalog unlocks, maximum level or correct catalog price. Any future non-UI purchase entry point must preserve those validations, or move them into one shared purchase service.

## What upgrades actually change

Ingredient upgrades increase `DishPricing` values. Dish pay is the sum of its raw/bubble ingredients, even when the dish requires baked bread. For example, upgrading only pepper changes pepper-flatbread pay from 20 to 28. Tips remain governed by patience, not by ingredient value.

A glass upgrade increases owned capacity, but `KitchenTools` still hides all glasses on a level without cups. A plate upgrade is reflected in the next story day. The current static `KitchenArt` lookup does not swap all ingredients to the premium images found in the asset catalog.

## Where global coins come from

A completed story day adds its total income and records best stars. The classic game banks its multiplier-adjusted paycheck when its manager ends the run. Story penalties are deducted from points before income is banked, not directly from an already-saved wallet.

Marathon coins are a separate run-local balance derived from tips. The current marathon end path does not add them to the global wallet. Its report labels should not be mistaken for a completed global reward transaction.

## Legacy multiplier shop

`ShopItem.coinMultiplier` costs 100 coins and describes a 2× classic-run reward. `ShopView` deducts global coins and adds one multiplier through `InventoryManager`. Insufficient funds show a temporary notice.

At classic run start, the manager checks whether a multiplier exists. At game over it consumes one if active and banks a `GameResult` whose total coins are doubled. Inventory records and wallet balance use different storage mechanisms; the legacy purchase is not an atomic transaction spanning both.

## Source map and tests

- [Kitchen catalog](../../PlayFeat/Data/Models/KitchenShop.swift), [offer model](../../PlayFeat/Data/Models/ShopUpgrade.swift)
- [Kitchen shop popup](../../PlayFeat/UI/Overlays/ShopPopup.swift), [upgrade card](../../PlayFeat/UI/Components/Shop/UpgradeCard.swift)
- [Saved wallet/upgrades](../../PlayFeat/Data/Storage/GameStorage.swift), [pricing](../../PlayFeat/Game/Level/DishPricing.swift)
- [Marathon cards](../../PlayFeat/Game/Marathon/MarathonCard.swift)
- [Legacy shop](../../PlayFeat/UI/Screens/ShopView.swift), [legacy product](../../PlayFeat/Data/Models/ShopItem.swift), [inventory](../../PlayFeat/Data/Storage/InventoryManager.swift)
- [Catalog tests](../../Testing/PlayFeatTests/Data/Models/KitchenShopTests.swift), [offer tests](../../Testing/PlayFeatTests/Data/Models/ShopUpgradeTests.swift)

Related: [storage](14-storage-and-inventory.md), [marathon](13-marathon-mode.md), [items and dish values](06-kitchen-items-and-interactions.md). [Back to index](README.md).
