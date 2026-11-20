# Marathon mode

## A continuing kitchen, not the classic game

The marathon is reached from the planet board's unlocked trophy, then `MarathonView` calls `SceneManager.startMarathon`. That creates a `MarathonSession`, whose one `KitchenDay` is reused by `KitchenView` throughout the run.

The session injects `MarathonFlow` for customers and `MarathonBubbleSupply` for ingredients. The same grill, stations, hands, physics and customer-serving scene used by story mode remain in use. The older lives/recipe/bell engine is not the marathon implementation.

## Run, round and break

A run begins at round 1 with one plate, no glass, base dish pricing, one grill slot and six-second baking. Saved permanent kitchen upgrades are not loaded into this session's constructor.

Each round lasts 90 seconds of **play time**. `day.roundEndsAt` starts at 90 and increases by 90 after each break. The same customers, items, score and cooking state remain, rather than constructing another day.

At a round boundary, `KitchenDay.tick` holds the clock because `isRoundOver` is true. `KitchenView.startBreak` asks for cards and presents `RoundCompleteOverlay`. The overlay has its own 15-second countdown and continues automatically with the selected card, or without a purchase if skipped. Continuing advances the deadline, updates grill upgrades and dismisses the break; a 3-2-1 plays before play time runs again.

Rendering is not universally paused during a round break: play time and interaction are gated, while the view/scene can still render. When a round ends mid-carry, carried items are not settled: they freeze where the hand held them (`isFrozenInAir`), out of gravity's reach, and stay there into the next round until a hand grabs them again. Any other stop (pause, app leaving the foreground, the run ending) settles carried items as usual. Treat "freeze" in comments as a statement about play time/rules, not proof that every cursor or presentation animation stops.

## Customer difficulty and stages

`MarathonFlow` begins with regular patience 45 seconds, angry patience 25 seconds and arrival spacing 15 seconds. After each served dish:

```text
regular patience = max(12, previous × 0.97)
angry patience   = max(12, previous × 0.97)
arrival spacing  = max(3, previous × 0.95)
```

New customers arrive on that spacing beat. Waiting arrivals use the shared typed counter; their patience begins after seating. Three lost customers end the run, regardless of the round's remaining time.

Stage 1 allows two seated customers at once and deals shuffled groups of three pepper-flatbread orders plus two mushroom-flatbread orders. Stage 2 begins after eight served dishes, allows three seated customers and introduces dessert/angry orders. Each stage-2 group contains one angry dessert order, two regular pepper orders, one regular mushroom order and one regular dessert order. Already-dealt deck entries are consumed before another group is dealt. The cap applies to seated customers; timed arrivals can also accumulate in the waiting queue.

The initial group is reordered so its first order is regular pepper flatbread. Randomness is injected so tests can reproduce dealing.

## Tools earned during a run

| Unlock | Trigger |
|---|---|
| Second plate | 6 dishes served |
| First glass | Dessert stage reached, or dessert already present |
| Second glass | 14 dishes served |

`KitchenView` refreshes tools when delivered-order count or present-customer count changes. `KitchenScene.syncTools` adds the physical stations and shifts existing plate indices when inserting a leftmost plate.

## Temporary coins and cards

Marathon coins are tips earned in this run minus card spending. Tips are `floor(remaining patience seconds / 3)`, not the story green/yellow/red tip table. Run points are still the day's total dish points plus tips after missed-order point penalties.

Each break offers up to three cards. The first three offers are predefined with fallback substitution; later offers use the fallback list. Owned cards disappear from future offers. Faster Grill II requires Faster Grill I. The session checks that a card is offered, that no card was already bought that break, and that the balance covers its price.

| Card | Price | Effect |
|---|---:|---|
| Faster Grill I / II | 40 / 60 | Bake in 4.5 / 3 seconds |
| Second Grill Spot | 65 | Two grill slots |
| Cozy Seats | 50 | Patience multiplier 1.2 |
| Blazing Pepper | 35 | Pepper value 18 |
| Royal Mushroom | 30 | Mushroom value 24 |
| Double Tentacle | 25 | Tentacle value 17 |
| Slimier Slime | 25 | Slime value 12 |
| Golden Flatbread | 45 | Raw flatbread value 16 |

Coins spent are tracked separately from all coins/tips earned. Buying a card does not reduce the reported earned-tip total. Upgrades are bounded by a three-second minimum bake and a 1.2 maximum patience multiplier. No temporary card purchase writes permanent shop ownership.

## Supply and end report

Marathon supply adjusts its interval to current demand, uses a 70% scheduled useful pattern, guarantees overdue missing ingredients where possible, and limits timed floating supply. See the dedicated bubble guide for its formula.

At three lost customers, the kitchen stops and shows `MarathonReportView` over the scene. The header shows `session.points`; report rows show rounds played, integer average dishes per round and customers served. The report's `totalLabel` currently says Total Points while its `total` argument is `session.coinsEarned` (tips). That is a current naming/data mismatch, not a second score formula.

The reviewed marathon end path does not save a new global highscore, bank global coins or submit a Game Center score. The marathon home reads the existing global `highscore` and leaderboard, which are currently written by the classic game. Do not assume a run was persisted just because its report was displayed.

## Source map and tests

- [Session](../../PlayFeat/Game/Marathon/MarathonSession.swift), [customer flow](../../PlayFeat/Game/Marathon/MarathonFlow.swift)
- [Stage rules](../../PlayFeat/Game/Marathon/MarathonStage.swift), [cards](../../PlayFeat/Game/Marathon/MarathonCard.swift), [supply](../../PlayFeat/Game/Marathon/MarathonBubbleSupply.swift)
- [Marathon home](../../PlayFeat/UI/Screens/MarathonView.swift), [kitchen integration](../../PlayFeat/UI/Screens/KitchenView.swift), [break/report UI](../../PlayFeat/UI/Overlays/MarathonOverlays.swift)
- [Marathon tests](../../Testing/PlayFeatTests/Game/Marathon/MarathonSessionTests.swift)

Related: [story/common day rules](05-story-levels-and-customers.md), [items](06-kitchen-items-and-interactions.md), [Game Center](17-game-center.md). [Back to index](README.md).
