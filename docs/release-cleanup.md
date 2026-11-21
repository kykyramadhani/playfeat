# Release cleanup: unused code and assets

Delete these before an App Store build. Found on 21 Nov 2026, at commit
`fd59d52` (branch `feature/planet-two-food-art`), by tracing which types,
assets and sounds a reachable screen still uses. Re-check each item with the
`grep` at the bottom before deleting: the code may have moved on since.

Most of this is **the original sandwich game (v1)**. It is still compiled,
but no release path reaches it:

- `.gameplay` is opened only by `PlanetSelectView.startLevel(at:)` when a level
  has no data file. All 12 levels have one in `Resources/Levels/`.
- It can also be opened by the debug launch flag `debugGameplay`.
- `.postGame`, `.mainMenu` and `.shop` are reached only from inside that game.

## 1. Move these out first

The kitchen still borrows a few pieces from the old game. Move them before
deleting the files they live in:

| What | Lives in | Used by | Move to |
|---|---|---|---|
| `GameScene.clamped(_:radius:in:)`, `GameScene.easing(base:delta:)` | `Scenes/GameScene/GameScene.swift` | `Scenes/KitchenScene/Hands.swift` | `KitchenScene`, or `Shared/Extensions/CGPoint+Distance.swift` |
| `IngredientNode.aspectFit(_:into:)` | `Scenes/Nodes/IngredientNode.swift` | `Scenes/Nodes/KitchenBubbleNode.swift` | `KitchenBubbleNode` or `Shared/` |
| `enum HandState` | `Scenes/GameScene/HandTracking.swift` | `Scenes/KitchenScene/Hands.swift` | `Vision/` (delete `HandTracker` with the old game) |
| `GameScene` references in `HandCursorNode` | `Scenes/Nodes/HandCursorNode.swift` | the kitchen's hands | Keep `HandCursorNode`; drop only its `GameScene`-specific code |
| `SoundPlaying` | `Audio/SoundPlaying.swift` | `KitchenScene`, `KitchenSoundscape` | Keep; remove only the `GameAudio` conformance |

## 2. Entry points to remove

- `App/AppScreen.swift`: the cases `mainMenu`, `shop`, `gameplay`,
  `postGame(GameResult)`.
- `App/SceneManager.swift`: `play()`, `goToPostGame(_:)`, `replayGame()`,
  `goToMainMenu()`, `goToShop()`.
- `UI/Screens/ContentView.swift`:
  - the switch cases for those screens;
  - the `InventoryManager` environment value;
  - the `DebugLaunch.skipToGameplay` branch;
  - the `.mainMenu` and `.shop` entries in the menu-music check.
- `UI/Screens/PlanetSelectView.swift`: the `sceneManager.play()` fallback in
  `startLevel(at:)`. Show an error, or nothing, instead.
- `Shared/DesignScale.swift`: `DebugLaunch.skipToGameplay`.
- `Data/Storage/GameStorage.swift`: `record(_ result: GameResult)`,
  `highscore` and `scoreKey`. Only the old game reads or writes them.
- **Game Center: decide this before deleting.** `GameCenter.submit` is called
  only from `Game/GameStateManager.swift`, the old game. `MarathonView` still
  shows the top entries of that same leaderboard
  (`com.reability.playfeat.mostdishes`), but nothing in the new game submits a
  score to it.
  - Before removing `GameStateManager`, have the Buffet submit its score, for
    example from `GameStorage.recordMarathon`.
  - Or point the Buffet screen at a new leaderboard.
  - `GameCenter.showLeaderboard()` is called only from `GameOpening`.
- `Audio/AudioManager.swift`: the `MusicTrack.classic` default argument of
  `startMusic`.
- `Audio/SoundEffects.swift`: the cases `addPoint`, `loseHeart`, `reset`,
  `scuffleCloud`, `bell`, and `MusicTrack.classic`.
- `App/PlayFeatApp.swift`: `InventoryManager` and `.modelContainer`. This drops
  SwiftData. The old inventory store is left on players' devices, which is
  harmless, but drop it on purpose.

## 3. Code files to delete

**Old game: screens and overlays**
- `UI/Screens/GameplayView.swift`, `PostGameView.swift` (also declares
  `GameResult`), `ShopView.swift`, `TutorialView.swift`
- `UI/Overlays/GameOpening.swift`, `GameHUD.swift`, `GameOverOverlay.swift`,
  `HeartCard.swift`, `PointCard.swift`, `RecipeCard.swift`, `LoseHeartOverlay.swift`
  - Check `UI/Components/RedEdgeFlash.swift` first: it mentions
    `LoseHeartOverlay`.
- `UI/Components/GameBoardView.swift`, `PayCheckView.swift`,
  `BackgroundImage.swift`, `CoinMultiplierView.swift`,
  `DebugSkeletonOverlay.swift`, `TutorialBubble.swift`, `LoopingVideoView.swift`
- `UI/Components/Button/ButtonComponent.swift`, `BackButton.swift`,
  `SettingsButton.swift`
- `UI/Styles/ButtonComponentStyle.swift`

**Old game: engine and rules**
- `Scenes/GameScene/`: the whole folder, after section 1. That is
  `GameScene.swift`, `HandTracking.swift`, `Input.swift`, `Layout.swift`,
  `Serving.swift`, `SpawnGrid.swift`, `Spawning.swift`.
- `Scenes/Nodes/IngredientNode.swift`, `PlateNode.swift`, `BellNode.swift`,
  `TrayTimerNode.swift`, `ResetButtonNode.swift`
- `Scenes/Animation/BellAnimation.swift`, `ScuffleCloudAnimator.swift`
- `Game/GameStateManager.swift`, `GameState.swift`, `GameEvent.swift`,
  `GameEventLog.swift`, `Difficulty.swift`, `RecipeDeck.swift`,
  `RunTally.swift`, `Countdown.swift`
  - Keep `Game/PlayClock.swift`: `KitchenDay` uses it.
- `Vision/Gestures/SwipeDirection.swift`, used only by the bell.
  - Keep `HoverDetector`: seat calibration uses it.
- `Audio/GameAudio.swift`
- `Data/Models/Recipe.swift`, `Ingredient.swift`, `GameArt.swift`,
  `ShopItem.swift`, `TutorialPage.swift`
- `Data/Storage/InventoryManager.swift`, `UserInventory.swift`

**Never used anywhere, even by the old game**
- `UI/Screens/SplashScreenView.swift`. `LaunchView` replaced it.
  - The comment in `Resources/Launch Screen.storyboard` still names it.
  - `CLAUDE.md` still describes it.
- `UI/Screens/OnboardingView.swift`
- `UI/Overlays/IntroductionPopup.swift`
- `UI/Components/ShopComingSoonPopup.swift`

## 4. Assets to delete (`Resources/Assets.xcassets`)

Referenced only by the files above:

- **Old ingredients and dishes:** `bubble`, `cheese`, `chicken`, `chili`,
  `cucumber`, `lettuce`, `mayonnaise`, `tomato`, `salad`, `ChickenGeprek`,
  `ChickenMayonnaise`, `ChickenMozarella`
- **Old screens:** `MainMenuBackground`, `HighscoreCard`, `TrayPlate`,
  `GetCooking`, `Paycheck`, `Coin`, `ServedDish`, `OnboardingBackground`,
  `Excited`, `Happy`
- **Old board:** `ResetButton`, `RingingBell`, `Tray`
- **Old tutorial:** `TutorialBG1`, `TutorialBG4b`, `TutorialBG5`,
  `TutorialBG6`, `TutorialBG7`, `TutorialBG11`, `TutorialPopover`
- **Colours:** `AppAccent`, `AppBackground`, `AppText`
- **Referenced by nothing at all:** `Sunrise/GaugeTrack` (colour)

Not unused, although no code spells their names: `Aliens/Alien{Regular,Square,Triangle}{1,2,3}`.
`AlienSpecies.imageName(in:)` builds those names at runtime.

## 5. Sounds and other media

- `Resources/Sounds/gameplay_getcooking.wav`: the old game's music.
- `Resources/Sounds/Sound Effect/add_point.wav`, `lose_heart.wav`,
  `reset.wav`, `scuffle_cloud.wav`, `bell_2x.wav`
- `Resources/Tutorial/`: all six `TutorialClip*.mov`, used only by `TutorialPage`.
- `Resources/Animation/ScuffleCloud/`: `1.png` to `4.png`.

## 6. Tests to delete or update

**Delete with the old game**
- `Testing/PlayFeatTests/Game/`: `GameLoopTests`, `GameTestSupport`,
  `RecipeMatchingTests`, `RecipeDeckTests`, `LivesTests`, `GameEventLogTests`
- `Testing/PlayFeatTests/Audio/GameAudioTests.swift`
- `Testing/PlayFeatTests/Scenes/GameScene/`: the whole folder
- `Testing/PlayFeatTests/Scenes/Nodes/TrayTimerGeometryTests.swift`
- `Testing/PlayFeatTests/UI/Screens/TutorialLayoutTests.swift`

**Update, don't delete**
- `Game/PlayClockTests`: drop the `Countdown` parts.
- `Data/Models/DishTimeLimitTests`: check what it covers, since it uses `Recipe`.
- `Resources/ArtAssetTests`: drop the `BellNode`, `Recipe` and `Ingredient`
  art checks.
- `Shared/Localization/LocalizationTests`:
  - drop the `Recipe` and `TutorialPage` strings;
  - remove those keys from `Localizable.xcstrings` too.
- `App/SceneManagerTests`: drop the `GameResult` / post-game cases.
- `Scenes/ScriptedHandInput.swift` and `Scenes/Nodes/HandCursorNodeTests.swift`:
  replace their `GameScene` use.

## Before deleting anything

1. Do it on its own branch (`refactor/remove-classic-game`), and run ⌘U before
   and after.
2. Re-check each name. If anything outside the files above still uses it, keep
   it:
   ```bash
   grep -rnw "<TypeOrAssetName>" PlayFeat Testing | grep -v "//"
   ```
3. Build for Release as well as Debug: `debugGameplay` and the other
   `DebugLaunch` flags only exist in Debug.
4. Play every screen once on a device: galaxy, planet board, a story day,
   Buffet, shop, recipe book, settings.
