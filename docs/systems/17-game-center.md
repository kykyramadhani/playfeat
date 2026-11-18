# Game Center

## Current integration

`GameCenter` is a small static adapter around GameKit. It handles authentication presentation, score submission, loading leaderboard entries and showing Apple's leaderboard dashboard. `LeaderboardEntry` copies display data out of GameKit so views do not need to retain `GKPlayer` objects.

The configured leaderboard ID is `com.reability.playfeat.mostdishes`. The app entitlements enable Game Center. The service's configured identifier and score meaning must match the code; changing a screen title alone does not create a new leaderboard.

## Authentication

`ContentView.onAppear` calls `GameCenter.authenticate()` after a window exists. The local player's authentication handler can return a sign-in controller, which is presented from a root view controller found through connected window scenes.

The app does not block cooking on authentication. The helper does not expose a rich observable sign-in/error state to the interface. This is why a signed-out or offline session can still play locally.

## Submission flow

The classic `GameStateManager.saveResult()` calls `GameCenter.submit(totalDishesServed)` at game over. Submission first checks whether the local player is authenticated, then launches an asynchronous GameKit submission. It submits every run, not only local personal bests; the leaderboard service owns its best-score behavior.

The value named `totalDishesServed` comes from the classic completed-dish tally, recorded when a recipe is assembled. Difficulty uses a separate delivery count. This distinction exists in the current implementation and matters if leaderboard meaning is tightened later.

Errors are ignored with `try?`; there is no persistent retry/outbox queue. Local coins/highscore saving occurs independently, so a failed network submission does not erase the local result.

## Loading the marathon-home list

`MarathonView` runs a task that requests the top five entries. The helper loads the configured leaderboard and global/all-time ranks starting at 1. It maps rank, player display name, score and whether the row belongs to the local player into `LeaderboardEntry`.

A signed-out player, offline request, missing leaderboard or empty ranking all produce an empty array. The interface's empty state does not distinguish these causes. Loading is tied to the view task; an authentication change after that request does not have an explicit automatic refresh subscription here.

`showLeaderboard()` can present Apple's dashboard with a retained delegate to dismiss it. That API is separate from the custom five-row list.

## Important current gap

Despite appearing on the marathon home, the current leaderboard is still submitted by the **classic** game. `MarathonSession`/`KitchenView.endDay` do not currently submit marathon points or update the global best score at marathon end. The home screen also reads `GameStorage.highscore`, which the classic result path updates.

If marathon points are meant to replace classic dish count, decide whether to use a separate leaderboard and local storage key. Silently mixing those score units in one ranking would make results incomparable.

## Troubleshooting

Check the signed-in player, entitlements, bundle provisioning, exact leaderboard ID, whether the submitting end path actually runs, and whether the score uses the intended unit. An empty custom list is insufficient evidence that the user has no scores. For device/service testing, account for the absence of a retry path and the fact that current errors are not surfaced as a visible alert.

## Source map

- [GameKit adapter](../../PlayFeat/Network/GameCenter.swift), [view-facing entry model](../../PlayFeat/Network/LeaderboardEntry.swift)
- [Authentication caller](../../PlayFeat/UI/Screens/ContentView.swift)
- [Submission caller](../../PlayFeat/Game/GameStateManager.swift)
- [Marathon-home reader](../../PlayFeat/UI/Screens/MarathonView.swift), [leaderboard UI](../../PlayFeat/UI/Components/PlanetSelect/LeaderboardList.swift)
- [Entitlements](../../PlayFeat/PlayFeat.entitlements)

There is no dedicated live Game Center integration test in the current unit-test inventory. Verify network behavior on an appropriately configured account/device rather than relying on rules tests.

Related: [marathon](13-marathon-mode.md), [classic game](15-classic-game-mode.md), [storage](14-storage-and-inventory.md). [Back to index](README.md).
