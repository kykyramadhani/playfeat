# Story levels and customers

## Who owns what

A story level is configuration (`LevelData`), a day is live rules/state (`KitchenDay`), and the scene is the physical presentation (`KitchenScene`). `KitchenView` constructs and connects them, runs calibration and the countdown, and presents the report.

The customer behavior is injected through `CustomerFlow`. Story days use `RefillFlow`; marathons use `MarathonFlow`. The counter, score and scene interaction are shared rather than copied into two game engines.

## Loading a level

`LevelLoader.load("1-1")` resolves the bundled file `level_1-1.json`, decodes `LevelData`, and calls `validate()`. Errors distinguish a missing file, an unreadable/undecodable file and invalid decoded content.

Important fields:

| Group | Fields and meaning |
|---|---|
| Identity | `id`, `name`, `planet` |
| Duration | `durationSec`: last time new story customers may arrive, not necessarily the final disappearance time |
| Customer refill | `counterSpots`, `refillDelaySec`, first order, weighted order pool, angry-customer schedule, regular/angry patience |
| Movement/supply | Gravity direction and multiplier, bubble lifetime, interval, useful share, starter bubble times/lanes and ingredient pool |
| Kitchen rules | `cups` enables glasses; `burnTimeMultiplier` stretches post-bake warning/burn timing |
| Progress/rewards | Three `starTargets`, displayed `energyCost` |

Validation requires a refill configuration, 1–3 counter spots, exactly three strictly increasing targets, starter lanes in 1–4, useful share in 0–1, at least one positive order weight, known dish IDs and known bubble ingredients. It does **not** validate every possible numeric hazard: for example, the current validator does not comprehensively reject all negative durations or invalid `angryEvery` values. Treat validation coverage as explicit code, not as a guarantee that arbitrary JSON is safe.

The generated marathon configuration intentionally has no story refill and no star targets. It is constructed directly; it is not loaded through this story validator.

## Starting a day

1. The board selects a bundled level and calls `SceneManager.goToKitchen`.
2. A fresh `KitchenView`, keyed by `kitchenVisit`, creates a `KitchenDay` with `RefillFlow`, saved dish pricing and owned kitchen tools.
3. The day immediately creates customers due at time zero, but its play clock remains stopped.
4. The view prepares the scene with `StoryBubbleSupply`, starts hand tracking, and performs calibration.
5. Any unseen New Tools/New Menu introductions are dismissed and persisted.
6. The 3–2–1–GO countdown completes; the view starts the day and gameplay music.
7. Each SpriteKit update ticks the day and reads the resulting play-time delta.

The clock is based on `PlayClock`, whose credited tick delta is capped at 0.25 seconds. A long wall-clock stall is not credited wholesale. A test advancing directly from time 0 to 90 with one call therefore does not simulate 90 seconds of play.

## Customer lifecycle

`RefillFlow` has one logical refill timer per allowed counter spot. The first customer is due immediately; later initial spots are staggered by `refillDelaySec`. A served or lost customer schedules another arrival after that same delay. Regular orders are drawn from positive weights in sorted-key order; injected seeded randomness can reproduce a sequence in tests.

Customer numbers start at one. `angryAt` or an `angryEvery` multiple produces an angry customer ordering `slimyTentacles`; otherwise the first customer uses `firstOrder`, and later regulars use the weighted pool.

An `Arrival` is not yet a seated customer. `Counter` maintains waiting arrivals and typed physical seats. It finds the oldest waiting arrival that can occupy a free seat of its type, subject to the flow's current counter-spot cap. Patience starts when seated, not while waiting. The headcount includes both seated and waiting customers.

A frame's `advance` gathers arrivals, seats waiting customers, removes all whose patience expired, records their penalties/refill consequences, and seats waiting customers again. Keep these responsibilities separate when changing queue behavior.

## Scoring, tips and stars

A successful `KitchenDay.serve(dish, at: seat)` must match the occupied customer's requested dish. It removes the customer, credits ingredient-based dish pay, credits the flow-specific tip, and informs the customer flow that a spot freed and a dish was served.

For story mode:

```text
points = dishEarnings - pointsLost
total income = points + tips
stars = count of level targets reached by total income
```

A customer giving up loses up to 10 **points**, capped by currently available points; accumulated tips are not deducted. Story tips are 5 when more than half the patience remains, 2 from 20% through 50%, and 0 below 20%. Angry story customers double that tip.

An unupgraded pepper flatbread pays 20; a quick green-zone serve adds 5, giving total income 25. On Level 1, that reaches the first target (20) but not the second (40). A wrong dish rejected by the scene is not the same as a timed-out customer: rejection removes the item, while the waiting customer's own patience continues.

## Current level values

All six story days have `durationSec = 90` and refill delay 2 seconds. Bubble IDs are explained in the items guide.

| Level | Counter spots | Gravity multiplier | Bubble interval / lifetime | Useful share | Glasses enabled | Star targets | Displayed energy |
|---|---:|---:|---|---:|---|---|---:|
| 1-1 | 1 | 0.4 | 3 s / 6 s | 0.80 | No | 20, 40, 60 | 3 |
| 1-2 | 1 | 0.4 | 3 s / 6 s | 0.80 | No | 20, 40, 60 | 3 |
| 1-3 | 2 | 0.5 | 2.5 s / 5 s | 0.65 | No | 20, 45, 65 | 3 |
| 1-4 | 2 | 0.6 | 2 s / 4 s | 0.60 | Yes | 35, 60, 75 | 4 |
| 1-5 | 2 | 0.6 | 2 s / 4 s | 0.60 | Yes | 35, 60, 75 | 4 |
| 1-6 | 3 | 0.6 | 2 s / 4 s | 0.60 | Yes | 50, 85, 105 | 5 |

These values are snapshots of the bundled JSON. Energy is currently UI information, not a charged resource.

## Overtime and results

At 90 seconds, `RefillFlow` stops creating new customers. The day ends only when the counter and waiting queue are empty. Existing customers can still be served; bubbles keep arriving in overtime while the day is running.

When `day.isOver` changes to true, `KitchenView.endDay` pauses play, stops music/camera, reads the previous best stars, banks the day, and creates a `LevelReport`. Best stars only increase; day income is added to the global coin balance. The report remains over the frozen kitchen. Stars reveal in place; there are currently no flying-star effects or extra report fuel gauge.

Back returns to the board. A day with zero stars offers Retry; a day with stars offers Next. Next after the final level returns to the board. A report snapshot is separate from the live day so the displayed result cannot drift with later gameplay state.

## Adding or changing a level

Update the JSON, its `Planet.levelIDs` entry if necessary, content references in `KitchenMenu`, and the introduction/shop/recipe-book rules that depend on level IDs. Verify typed seat capacity, usable bubble ingredients and the intended story/marathon distinction. Run loader, level-rule, progression and scene tests; then play the full day including overtime and results.

## Source map and tests

- [Configuration model](../../PlayFeat/Data/Models/Level/LevelData.swift), [validation](../../PlayFeat/Data/Models/Level/LevelValidation.swift), [loader](../../PlayFeat/Data/Storage/LevelLoader.swift)
- [Example level JSON](../../PlayFeat/Resources/Levels/level_1-1.json)
- [Live day](../../PlayFeat/Game/Level/KitchenDay.swift), [refill flow](../../PlayFeat/Game/Level/RefillFlow.swift), [counter](../../PlayFeat/Game/Level/Counter.swift)
- [Scoring constants](../../PlayFeat/Game/Level/KitchenRules.swift), [report snapshot](../../PlayFeat/Game/Level/LevelReport.swift)
- [Loader tests](../../Testing/PlayFeatTests/Data/Storage/LevelLoaderTests.swift), [day tests](../../Testing/PlayFeatTests/Game/Level/KitchenDayTests.swift), [star tests](../../Testing/PlayFeatTests/Game/Level/StarRatingTests.swift)

Related: [items](06-kitchen-items-and-interactions.md), [bubble supply](07-bubble-supply-and-physics.md), [progression](08-planets-and-progression.md). [Back to index](README.md).
