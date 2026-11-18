# Storage and inventory

## Persistence is split by purpose

The app uses UserDefaults for small settings/progression values and SwiftData for the classic multiplier inventory. Most gameplay state stays in memory. Bundled JSON provides level configuration, not a save file.

| Data | Owner/store | Survives relaunch? |
|---|---|---|
| Wallet, classic highscore, best story stars | `GameStorage` / UserDefaults | Yes |
| Permanent kitchen upgrades and seen introductions | `GameStorage` / UserDefaults | Yes |
| Language, volumes, hand mode and grip | Settings-related constants / UserDefaults | Yes |
| Classic multiplier count | `UserInventory` / SwiftData | Yes |
| Kitchen items, cooking state, customers, current run clock | `KitchenDay` and scene | No checkpoint implementation |
| Marathon rounds, cards, temporary coins | `MarathonSession` | No |
| Current route/report/calibration | `SceneManager` and screen state | In-memory UI state |

There is no account-specific save service, cloud synchronization or saved mid-run restoration in the reviewed implementation.

## UserDefaults key reference

| Key | Meaning |
|---|---|
| `coins` | Global wallet |
| `highscore` | Classic completed-dish personal best, also read by marathon home |
| `bestStars_<levelID>` | Highest stored stars for that level |
| `upgrade_<upgradeID>` | Purchased permanent kitchen upgrade level |
| `seenIntroductions` | Array-backed set of introduction IDs |
| `marathonSpoilerSeen` | Whether the marathon spoiler warning was accepted |
| `settings.musicVolume`, `settings.sfxVolume` | Persisted audio volumes |
| `settings.language` | `english` / `indonesia` enum raw value |
| `oneHandModeEnabled`, `preferredHand` | One-hand mode and selected side |
| `gripGesture` | `pinch` / `fPinch` |

Check owner constants before renaming keys. A new key without migration makes an existing user's data look absent.

## Story save boundary

`KitchenView.endDay` reads the previous best before saving. `GameStorage.recordDay` improves best stars only if the new count is higher, and adds total income to coins with a nonnegative floor on the result. The resulting `LevelReport` retains the previous best for comparison.

The screen's existing-report guard prevents repeated end handling in the normal presentation flow. The underlying `recordDay` operation is not itself idempotent: explicitly calling it twice adds income twice. UI appearance is not the save trigger, and simply revisiting the report should not bank another reward.

`progress(on:)` builds a `PlanetProgress` from the ordered best-star keys. Cleared levels are IDs with at least one star. Tool counts and ingredient pricing are derived from upgrade levels and the catalog, rather than stored as another independent set of numbers.

## Permanent purchases

`buyUpgrade` checks the wallet, subtracts a supplied price and increments the supplied upgrade ID. The popup is responsible for catalog/unlock/max-level offer checks. Writes happen immediately. Existing `@State` coin/progress snapshots in unrelated views do not automatically refresh just because UserDefaults changed.

The current wallet/property setters do not provide general transaction or synchronization guarantees. If multiple purchase entry points are introduced, centralize validation and state notification rather than depending on UI snapshots.

## SwiftData multiplier inventory

`InventoryManager` creates a `ModelContainer` with `UserInventory` as its schema and uses its main context. The model has a unique string ID and an integer `coinMultipliers` count. The manager fetches the first existing record or creates `user_inventory` if none is found, then exposes a refreshed count to UI.

`addMultipliers` saves an increased count. `consumeMultiplier` checks availability, subtracts one, saves and refreshes. Tests can construct `InventoryManager(inMemory: true)` to avoid writing a persistent model store.

Container creation failure terminates initialization. Several later fetch/save operations use `try?`; those paths do not surface storage errors as UI failures. The intended single record is a convention around the unique ID and manager, not a general multi-user inventory system.

## Classic reward save boundary

At classic game over, `GameStateManager.saveResult` consumes a multiplier when active, calls `GameStorage.record(result)` and submits completed dishes to Game Center. `GameResult` multiplies the whole base paycheck when a multiplier is active. `record` adds coins and updates highscore if the result is better.

This is separate from story `recordDay`. The marathon currently has no matching persistence call at its own end. Network submission is optional and is not a substitute for a local save.

## Reset and migration considerations

A fresh install defaults integer keys to zero, while settings and tool readers provide their own defaults. Removing UserDefaults does not remove the SwiftData model store; removing the model store does not clear story stars or settings. Any future reset feature must specify which data categories it resets and coordinate both stores if appropriate.

For migrations, preserve established IDs and map renamed ones. A recipe image name, level ID, upgrade ID and stored enum raw value are all different identity domains even when their strings look related.

## Source map and tests

- [Wallet/progression/upgrades](../../PlayFeat/Data/Storage/GameStorage.swift)
- [SwiftData manager](../../PlayFeat/Data/Storage/InventoryManager.swift), [model](../../PlayFeat/Data/Storage/UserInventory.swift)
- [Story banking caller](../../PlayFeat/UI/Screens/KitchenView.swift), [classic banking caller](../../PlayFeat/Game/GameStateManager.swift)
- [Setting owners](../../PlayFeat/UI/Overlays/SettingsView.swift)
- [Shop tests](../../Testing/PlayFeatTests/Data/Models/KitchenShopTests.swift), [game-loop tests](../../Testing/PlayFeatTests/Game/GameLoopTests.swift), [progress tests](../../Testing/PlayFeatTests/Game/Level/PlanetProgressTests.swift)

Related: [economy](09-shop-and-economy.md), [settings](11-settings-and-localization.md), [reports/navigation](10-menus-and-navigation.md). [Back to index](README.md).
