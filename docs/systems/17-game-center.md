# Game Center

## Current integration

`GameCenter` is a small static adapter around GameKit. It handles authentication presentation, score submission, loading leaderboard entries and showing Apple's leaderboard dashboard. `LeaderboardEntry` copies display data out of GameKit so views do not need to retain `GKPlayer` objects.

Leaderboards: the classic game's `com.reability.playfeat.mostdishes`, and one Buffet (marathon) leaderboard per planet, in points: `com.reability.playfeat.buffet.kepler_186f` and `com.reability.playfeat.buffet.k2_332b` (`GameCenter.buffetLeaderboardID(on:)`; IDs take no hyphens). All three are in `GameCenterResources.gamekit` for local testing. Story mode reports achievements instead (below). The app entitlements enable Game Center. The service's configured identifier and score meaning must match the code; changing a screen title alone does not create a new leaderboard.

## Authentication

`ContentView.onAppear` calls `GameCenter.authenticate()` after a window exists. The local player's authentication handler can return a sign-in controller, which is presented from a root view controller found through connected window scenes.

The app does not block cooking on authentication. The helper does not expose a rich observable sign-in/error state to the interface. This is why a signed-out or offline session can still play locally.

## Submission flow

The classic `GameStateManager.saveResult()` calls `GameCenter.submit(totalDishesServed)` at game over. Submission first checks whether the local player is authenticated, then launches an asynchronous GameKit submission. It submits every run, not only local personal bests; the leaderboard service owns its best-score behavior.

The value named `totalDishesServed` comes from the classic completed-dish tally, recorded when a recipe is assembled. Difficulty uses a separate delivery count. This distinction exists in the current implementation and matters if leaderboard meaning is tightened later.

Errors are ignored with `try?`; there is no persistent retry/outbox queue. Local coins/highscore saving occurs independently, so a failed network submission does not erase the local result.

## Buffet leaderboard

`KitchenView.bankMarathonRun` saves a marathon run's points as the local best (`GameStorage.recordMarathon`) and submits them to its planet's Buffet leaderboard, once per run: when the third customer is lost, or when the player gives up from the pause card (HOME or RESTART). `MarathonView` lists that leaderboard's top five, and tapping the board opens Game Center's own view of it. A signed-out player, offline request, missing leaderboard or empty ranking all produce an empty list.

## Story achievements

When a story day ends, `KitchenView.reportAchievements()` saves its stars first, then reports every achievement `StoryAchievement.earned(after:bestStars:)` finds, at 100%. Achievements already earned are reported again harmlessly. The rules are plain data in `Game/StoryAchievement.swift`, covered by `StoryAchievementTests`.

Each needs an achievement with this ID in App Store Connect (`com.reability.playfeat.achievement.<id>`), with its title, descriptions and image there:

| ID | Earned by |
|---|---|
| `firstSale`, `hotGrill`, `twoToppings`, `somethingSweet`, `theAngryAlien`, `doubleTrouble` | Clearing levels 1-1 to 1-6 (at least one star) |
| `upsideDown`, `pickATopping`, `grillIsBack`, `sweetStars`, `angryAgain`, `fullTide` | Clearing levels 2-1 to 2-6 |
| `keplerChef`, `tideChef` | Clearing every level of Kepler-186f / K2-332 b |
| `keplerStarChef`, `tideStarChef` | Three stars on every level of that planet |
| `perfectDay` | Three stars on any level |
| `nobodyLeftHungry` | A day with no customer lost and at least 3 served |
| `calmTheStorm` | Serving an angry alien |
| `sweetTooth` | Serving the planet's dessert |
| `tipJar` | 20 tips in one day |
| `starCollector`, `superstar` | 10 and 30 stars across the story |

## Troubleshooting

Check the signed-in player, entitlements, bundle provisioning, exact leaderboard ID, whether the submitting end path actually runs, and whether the score uses the intended unit. An empty custom list is insufficient evidence that the user has no scores. For device/service testing, account for the absence of a retry path and the fact that current errors are not surfaced as a visible alert.

## Source map

- [GameKit adapter](../../PlayFeat/Network/GameCenter.swift), [view-facing entry model](../../PlayFeat/Network/LeaderboardEntry.swift)
- [Authentication caller](../../PlayFeat/UI/Screens/ContentView.swift)
- [Submission callers](../../PlayFeat/Game/GameStateManager.swift) (classic), [kitchen](../../PlayFeat/UI/Screens/KitchenView.swift) (Buffet points, story achievements)
- [Achievement rules](../../PlayFeat/Game/StoryAchievement.swift)
- [Marathon-home reader](../../PlayFeat/UI/Screens/MarathonView.swift), [leaderboard UI](../../PlayFeat/UI/Components/PlanetSelect/LeaderboardList.swift)
- [Entitlements](../../PlayFeat/PlayFeat.entitlements)

There is no dedicated live Game Center integration test in the current unit-test inventory. Verify network behavior on an appropriately configured account/device rather than relying on rules tests.

Related: [marathon](13-marathon-mode.md), [classic game](15-classic-game-mode.md), [storage](14-storage-and-inventory.md). [Back to index](README.md).
