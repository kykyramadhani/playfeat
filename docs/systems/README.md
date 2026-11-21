# AstroFeast system documentation

These guides explain the implementation in this working tree, reviewed on **18 November 2026**. The app, Xcode project, and shared scheme are named **AstroFeast**. The Swift module is named **PlayFeat**. Some older files still say GetCooking or VisionChef.

Start with the architecture guide, then follow the system you want to change. Each category has its own file, source map, behavior walkthrough, and maintenance notes. Values in tables describe the reviewed code, not permanent product requirements. Follow the linked implementation when the code and an older comment disagree.

## Reading order and categories

| Area | Guide | What you will understand |
|---|---|---|
| Foundations | [01. Architecture and app lifecycle](01-architecture-and-app-lifecycle.md) | Ownership, dependency injection, observation, threads, foreground/background behavior |
| Input | [02. Camera and coordinate mapping](02-camera-and-coordinate-mapping.md) | Permissions, capture formats, mirroring, rotation, Vision/view/scene coordinates |
| Input | [03. Hand tracking and gestures](03-hand-tracking-and-gestures.md) | Palm extraction, stable IDs, smoothing, pinch detection, chirality, cursor drawing |
| Input | [04. Calibration and player selection](04-calibration-and-player-selection.md) | Seat check, one-hand mode, player locking, body/hand association |
| Story gameplay | [05. Story levels and customers](05-story-levels-and-customers.md) | JSON loading, level configuration, customers, patience, scoring, overtime, reports |
| Story gameplay | [06. Kitchen items and interactions](06-kitchen-items-and-interactions.md) | Picking up, carrying, dropping, grilling, assembling, serving and rejection |
| Story gameplay | [07. Bubble supply and physics](07-bubble-supply-and-physics.md) | Demand calculations, useful/decoy scheduling, lanes, gravity and disappearance |
| Progression | [08. Planets and progression](08-planets-and-progression.md) | Galaxy, level selection, unlocks, stars, fuel, marathon access |
| Progression | [09. Shop and economy](09-shop-and-economy.md) | Permanent upgrades, prices, purchase checks, dish value, separate legacy shop |
| App interface | [10. Menus and navigation](10-menus-and-navigation.md) | Launch, routes, popups, introductions, pause, retry, reports, retained screens |
| App interface | [11. Settings and localization](11-settings-and-localization.md) | Setting keys, live updates, languages, bundle redirection, accessibility choices |
| Feedback | [12. Music and sound](12-music-and-sound.md) | Audio ownership, tracks, effects, event-driven sound, volume and lifecycle |
| Other gameplay | [13. Marathon mode](13-marathon-mode.md) | Continuous day, rounds, breaks, cards, temporary coins, stages and difficulty |
| Data | [14. Storage and inventory](14-storage-and-inventory.md) | UserDefaults, SwiftData, saved progress, runtime state and save boundaries |
| Other gameplay | [15. Classic game mode](15-classic-game-mode.md) | The older recipe/plate/bell engine, clocks, lives, events and paycheck |
| Presentation | [16. Rendering, assets and layout](16-rendering-assets-and-layout.md) | SwiftUI/SpriteKit layering, design canvas, artwork sizing, coordinates and z-order |
| Services | [17. Game Center](17-game-center.md) | Authentication, leaderboard loading/submission, offline behavior and current gaps |
| Maintenance | [18. Testing and debugging](18-testing-and-debugging.md) | Test organization, launch arguments, diagnostics and practical investigation paths |

## Two gameplay engines: do not mix their rules

The primary route is:

```text
Launch / START → Galaxy → Planet level board
  → KitchenView + KitchenDay + KitchenScene
  → Story report over the frozen kitchen
```

The marathon uses the same kitchen and item interactions, with `MarathonSession`, `MarathonFlow`, and `MarathonBubbleSupply` supplying different rules.

The retained classic route is `GameplayView + GameStateManager + GameScene`. It uses different recipes, three lives, a bell, a legacy shop, and a separate `PostGameView`. A missing/invalid story level can still fall back to this route. A feature existing in the classic engine does not mean it is implemented in the planet kitchen.

## Current implementation boundaries

- Kepler-186f has six bundled story levels. The next planet shows an unlock/congratulations popup, but has no playable board yet.
- Starting a story level spends its energy cost; energy refills one point every 5 minutes up to 25.
- Story results stay over the frozen kitchen. Earned stars light up in place. Flying stars and the extra report fuel gauge have been removed.
- The recipe book has four real entries and six tile positions; remaining tiles are placeholders, not a full recipe-unlock system.
- Permanent kitchen upgrades, temporary marathon cards, and classic coin multipliers are three different systems.
- The current marathon report does not bank its score into `GameStorage.highscore` or submit it to Game Center. The classic game does submit its completed-dish count.
- Existing [multiplayer notes](../multiplayer-plan.md) describe planned work; they do not establish that networking gameplay has been implemented.

## How to use and maintain these guides

For a new feature, locate the owner in the relevant source map before changing a view. Follow the end-to-end walkthrough to find its callers and persistence boundary. Read the linked tests to see which behavior is intentional.

When changing a rule, update the rule's guide, any duplicated numeric table, and the examples that depend on it. When adding a category, add it to this index. Relative source links are intentionally portable between checkouts.

These are source-based system explanations. This documentation task did not run a new device playtest or certify every existing test as passing.
