# Planets and progression

## The two selectors

`GalaxyMapView` chooses a planet. `PlanetSelectView` is the selected planet's home: spaceship/fuel gauge, six level cards, recipe book, marathon access and shop. They use `PlanetScreen` for their common backdrop, music and top bar.

Only `Planet.kepler186f` is currently configured, with ordered IDs `1-1` through `1-6`. The order is significant for unlocks, display numbers and Next navigation.

## From a level card to a kitchen

The board loads `PlanetProgress` from saved best stars. Each `LevelCard` receives its level number, best star count and lock state.

1. A locked card opens a notice instead of a level.
2. An unlocked card opens `LevelDetailPopup` with targets, earned stars and energy cost.
3. Play attempts `LevelLoader.load` and enters the kitchen.
4. A load failure falls back to the classic `GameplayView`; the board currently hides the loader error with `try?`.
5. Retry/Next navigation goes through `SceneManager`, which increments `kitchenVisit` for a fresh kitchen instance.

A level being unlocked in UI and a level being valid in JSON are different checks. `SceneManager.goToKitchen` itself is not an unlock/security gate; direct callers can enter a supplied level.

## Unlock rules

`PlanetProgress` is a value object derived from an array of best stars:

| Rule | Current condition |
|---|---|
| First story level | Always unlocked |
| Any later story level | Previous array entry has at least one star |
| Marathon entry | First level has at least one star |
| Planet complete | Every level has at least one star |
| Enough fuel | At least 15 total best stars |
| Departure ready | Enough fuel **and** every level played with a star |

Best stars never decrease on replay. They are read in planet order and are not a count of all stars earned across repeated runs.

The marathon button adds a spoiler warning the first time it is opened before the planet is complete. Accepting that warning persists `hasSeenMarathonSpoiler`. Once seen, or once every level has a star, the button opens the marathon screen directly.

## Fuel calculation

The gauge has ten bars. Ordinarily:

```text
bars = floor(min(totalBestStars, 15) / 15 × 10)
```

Until departure is ready, the gauge is capped at nine bars. This prevents five levels at three stars each from showing a full tank while the sixth level is unplayed. At least one star on every level plus 15 total fills all ten bars.

Fuel is derived from saved stars; there is no separate consumable fuel balance. Tapping the gauge opens an explanation notice rather than buying or spending gas.

## Finishing a story level

The day banks its income and best-star improvement before showing `LevelReportView` over the frozen kitchen. Back goes to the board; Retry restarts the same level; Next loads the following level or returns to the board after `1-6`.

`PlanetSelectView.loadProgress()` reads saved progress on appearance, so it shows the latest stars and fuel after returning. The current implementation has no flying-star transfer animation or pending-animation queue. The report only lights earned stars in place.

## Leaving Kepler

The first locked planet in the galaxy can be tapped. The departure state selects one of:

- A fuel notice when total best stars are below 15.
- An unplayed-levels notice when the total is sufficient but a level still has zero stars.
- `NewPlanetPopup` when both requirements are met.

The popup's Proceed action currently closes the popup. There is no second-planet `Planet` configuration, level board or kitchen route behind it. Further locked-planet drawings are presentation placeholders.

## Energy and coins on the selector

`PlanetScreen` displays the saved global coin count, while energy is the design's fixed `25/25` sample. Level energy costs are real configuration fields displayed by level details, but starting a level or marathon does not deduct energy. Do not implement progression logic by reading the rendered string.

The board's `progress` and the shared top bar's coin count are local snapshots. If adding purchases or rewards without leaving these views, ensure those snapshots are refreshed where needed; UserDefaults alone is not an observable model.

## Adding another planet

The current selector hardcodes Kepler in several places, not just in `Planet.swift`. Review GalaxyMapView, PlanetSelectView, next-level lookup, storage progress grouping, marathon configuration, shop unlock IDs, art and localized notices. Replacing the next-planet popup with a route requires carrying an actual selected-planet identity through navigation.

## Source map and tests

- [Planet IDs](../../PlayFeat/Data/Models/Level/Planet.swift), [progress calculations](../../PlayFeat/Game/Level/PlanetProgress.swift)
- [Galaxy selector](../../PlayFeat/UI/Screens/GalaxyMapView.swift), [level selector](../../PlayFeat/UI/Screens/PlanetSelectView.swift)
- [Shared selector frame](../../PlayFeat/UI/Components/PlanetSelect/PlanetScreen.swift), [fuel drawing](../../PlayFeat/UI/Components/PlanetSelect/FuelGauge.swift)
- [Routes](../../PlayFeat/App/SceneManager.swift), [saved progression](../../PlayFeat/Data/Storage/GameStorage.swift)
- [Progression tests](../../Testing/PlayFeatTests/Game/Level/PlanetProgressTests.swift), [route tests](../../Testing/PlayFeatTests/App/SceneManagerTests.swift)

Related: [story management](05-story-levels-and-customers.md), [shop](09-shop-and-economy.md), [menus](10-menus-and-navigation.md). [Back to index](README.md).
