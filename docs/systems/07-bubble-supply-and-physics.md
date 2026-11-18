# Bubble supply and physics

## The supply interface

A scene should not hardcode which ingredient spawns next. `BubbleSupply` receives play time, a `BubbleContext` snapshot and a random generator, and returns due `LevelData.BubbleEntry` values. `KitchenView` injects `StoryBubbleSupply` or `MarathonBubbleSupply` when preparing the scene.

The context includes seated customers' orders, nonfloating kitchen items, floating bubble ingredients, allowed pool, occupied entry lanes, average remaining patience and marathon customer spacing. Customers are ordered by seating time. Carried, placed and falling food count as kitchen items; a free, unplaced, nonfalling node counts as a floating bubble.

`KitchenScene` stores the mutated supply back after each request. These suppliers have private schedule state; treating them as freshly constructed every frame would restart the schedule.

## Calculating what is missing

`IngredientNeeds` builds a counted inventory and allocates it to orders, oldest first. A completed dish satisfies a whole matching order. Otherwise the function consumes available bubble ingredients for that dish and returns whatever remains missing.

Baked bread counts as raw bread for demand; burnt bread counts as nothing. Counts matter: a single pepper does not satisfy two pepper-flatbread orders. This is different from simple set membership.

Story supply includes already-floating bubble ingredients in this inventory. Marathon supply computes needs from kitchen items, then separately avoids resending an ingredient already floating where possible.

## Useful versus decoy bubbles

`UsefulBubblePattern` converts the desired share to whole percent and uses integer arithmetic. For the first `n` timed bubbles, its scheduled useful count is `ceil(n × percent / 100)`. At 80%, the pattern starts useful/useful/useful/useful/decoy and repeats.

This is a scheduling preference, not a promise that exactly that percentage of actual spawned items will remain useful to a changing kitchen. Urgency guarantees can override it; an empty useful/decoy set or the current pool can also change the result.

## Story schedule

`StoryBubbleSupply` emits sorted starter entries once their `at` time is due. Timed spawning begins after the last starter plus `bubbleEverySec`, and advances by that interval. It can emit multiple entries to catch up with a delayed frame.

For a timed spawn it calculates useful ingredients from current orders. If nothing is missing, ingredients used by those orders can still be considered useful. It chooses useful supply on the pattern's useful turns, or when the next interval would violate the shared six-second useful-supply wait. Other turns choose decoys, falling back to the pool when a distinct decoy is unavailable.

The supplier does not stop at the level duration. The day/scene's running state governs updates, so existing customers still get bubbles during story overtime.

## Marathon schedule

The marathon begins with raw bread at time 0 in lane 2 and pepper at time 2 in lane 3. Its timed supply targets:

| Dial | Value |
|---|---:|
| Useful pattern share | 0.7 |
| Interval bounds | 0.8–2 seconds |
| Useful missing-item guarantee | 3 seconds |
| Timed spawning screen cap | 8 floating bubbles |
| Supply margin | 1.3 |
| Estimated bubble ingredients per dish | 2 |

Demand is the greater of missing-ingredient count divided by average remaining patience, and two ingredients divided by customer spacing. The next interval is approximately `usefulShare / (supplyMargin × demand)`, clamped to the bounds. No demand selects the slowest interval.

Each missing ingredient has a need-start time and last-sent time. An overdue missing ingredient not already floating can override the ordinary pattern. The cap guards timed spawning; starter handling is separate. The marathon's pool grows with its stage.

## Entry lanes

There are four lanes. `BubbleLanes.freeLane` prefers a clear lane that was not just used. If necessary it reuses a clear lane, or any lane if all are busy. A scene marks a lane busy when a floating bubble is still near its gravity-dependent entry point, within approximately `bubbleRadius × 2.4`.

`GravityDirection` supplies the unit vector and entry edge. Do not assume lane coordinates always mean the bottom edge: input configuration can describe other directions.

## Drift and falling

Floating bubbles drift at a constant speed chosen to cross the usable window distance within `bubbleLifeSec`. Released items use `FallMotion`, with full speed `gravity.multiplier × 1.25` kitchen heights per second. A kitchen height is measured from the window's scene-space upper edge to the screen's lower edge. Falling speed ramps up over 0.2 seconds and then stays capped.

The scene moves nodes using **play-time delta**, not raw frame delta. It removes items behind the table or outside their permitted bounds. A bubble's usable window crossing accounts for its radius, so it disappears when its edge reaches the table boundary rather than drawing over the counter. A refused item has a future falling start time; before that time its ramp clamps to zero.

Animation actions and rule time are distinct. Always check the scene's pause/render state when changing effects that run outside the day clock.

## Changing supply safely

For a new ingredient, update `KitchenMenu`, recipe demand, level pools, art and validation together. A recipe that requires something excluded from its allowed pool may never be completable even if the usefulness ratio is high.

Use seeded generators in tests for reproducibility. Verify quantity accounting, starters, urgent supply, lane choice, overtime and completed/burnt-food inventory. A high screen cap is not a substitute for faster processing or reliable tracking.

## Source map and tests

- [Supply protocol and context](../../PlayFeat/Game/Level/BubbleSupply.swift)
- [Story supply](../../PlayFeat/Game/Level/StoryBubbleSupply.swift), [marathon supply](../../PlayFeat/Game/Marathon/MarathonBubbleSupply.swift)
- [Demand accounting](../../PlayFeat/Game/Level/IngredientNeeds.swift), [useful pattern](../../PlayFeat/Game/Level/UsefulBubblePattern.swift)
- [Motion rules](../../PlayFeat/Game/Level/FallMotion.swift), [gravity directions](../../PlayFeat/Data/Models/Level/GravityDirection.swift)
- [Scene spawning and removal](../../PlayFeat/Scenes/KitchenScene/KitchenScene.swift)
- [Story supply tests](../../Testing/PlayFeatTests/Game/Level/StoryBubbleSupplyTests.swift), [pattern tests](../../Testing/PlayFeatTests/Game/Level/UsefulBubblePatternTests.swift), [motion tests](../../Testing/PlayFeatTests/Game/Level/FallMotionTests.swift)

Related: [story days](05-story-levels-and-customers.md), [items](06-kitchen-items-and-interactions.md), [marathon](13-marathon-mode.md). [Back to index](README.md).
