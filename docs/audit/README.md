# PlayFeat / AstroFeast codebase audit

Audited on **20 November 2026** against commit `a893173` **plus the current working tree**, including the uncommitted fuel-star animation work. This is an engineering review of the local source, configuration, resources, and tests. Findings below are open; this audit changes documentation only.

**Assessment:** the project has a useful separation between game rules, hand tracking, rendering, and interface code, supported by extensive unit tests. The main risks are build reproducibility, loss of live game state during language changes, a failing cursor test baseline, and incomplete integration of Planet 2 and marathon features.

## Scope and architecture

The local tree contains **198 application Swift files / 19,823 lines**, **72 test Swift files / 6,431 lines**, **12 story-level JSON files**, and **168 string-catalog entries**. Counts include untracked Swift files present when reviewed and exclude assets from the line counts.

| Area | Current implementation | Review focus |
|---|---|---|
| App and navigation | SwiftUI, `SceneManager`, explicit `AppScreen` destinations | View identity, ownership, kitchen handover, app lifecycle |
| Camera and input | AVFoundation capture; Vision hand/body pose; player selection; gesture strategies | Authorization, queue ownership, start/stop, calibration |
| Story game | `KitchenDay`, customer flows, cooking/assembly tools, bubble supplies | Timing, serving, progression, content validation |
| Marathon | `MarathonSession`, staged customer mixes, upgrade cards | Round transitions, results, score persistence |
| Rendering | SpriteKit scenes over SwiftUI kitchen art or camera preview | Cursor geometry, paused interactions, coordinate mapping |
| Storage and economy | UserDefaults for progression/coins/settings; SwiftData for multiplier inventory | Error handling, purchase consistency, test isolation |
| Services and resources | GameKit leaderboard, AVAudio, bilingual catalog, bundled assets | Score meaning, localization, build warnings |

The current launch path leads to the galaxy, planet board, and illustrated kitchens. The root project README's play instructions describe the retained classic camera mode. The app display name in `Info.plist` is **AstroFeast**; the Xcode module/project is **PlayFeat**. No third-party package dependencies were found in the local project.

This was a targeted source audit across the main subsystems, not an exhaustive proof of every code path. Camera accuracy, accessibility behavior on a device, live Game Center delivery, device performance, and recovery from actual disk failures were not exercised.

## Verification results

| Check | Result |
|---|---|
| Toolchain | Xcode 27.2, build `27B52` |
| Build/test destination | iPad Pro 13-inch (M5), iOS Simulator 26.5 |
| Debug application and test build | Compiled successfully, with warnings |
| Unit test definitions | **475 total: 470 passed, 5 failed, 0 skipped**, across 65 suites |
| Failure detail | Parameterized executions produce **7 failing test cases and 9 assertion issues**; all concern cursor mirroring or pinch offsets |
| UI tests | Not run: `Testing/Functionality.xctestplan` includes only `PlayFeatTests`; UI tests remain launch/performance scaffolding |
| Bundled levels | All 12 parse as JSON; existing parameterized load/playability tests passed |
| Additional level checks | Positive duration/bubble intervals, three rising star targets, and positive non-null `angryEvery` checked for all shipped files |
| Localization catalog | All 168 entries have an Indonesian localization; existing localization tests passed. This does not establish translation quality or cover text outside the catalog |
| Clean-checkout build | Blocked by an untracked, ignored `project.pbxproj`; the successful build used the local copy |

Test command used:

```sh
xcodebuild \
  -project PlayFeat.xcodeproj \
  -scheme PlayFeat \
  -destination 'platform=iOS Simulator,id=81EEEEBB-F802-4F66-BB09-C8299B4CA99F' \
  -derivedDataPath /tmp/playfeat-audit-derived \
  -resultBundlePath /tmp/playfeat-audit-tests.xcresult \
  test
```

The command returned exit code **65** because tests failed. On another machine, substitute an available iPad simulator ID and use a fresh result-bundle path. Local evidence is in `/tmp/playfeat-audit-tests.log`, `/tmp/playfeat-audit-tests.xcresult`, and `/tmp/playfeat-audit-summary.json`; these temporary artifacts are not committed. Test totals above use the result bundle's top-level definition counts, rather than counting parameterized executions as separate definitions.

## Findings by priority

**P1:** fix before relying on a release or shared build. **P2:** functional, reliability, or accessibility issue to address next. **P3:** maintenance or content-hardening work. “Source-confirmed” means the behavior follows from the current implementation; it does not mean it was reproduced through the interface on hardware.

| ID | Priority | Finding | Evidence |
|---|---|---|---|
| A01 | P1 | A clean checkout lacks the Xcode project definition | Git index and ignore checks |
| A02 | P1 | Changing language rebuilds and resets an active story kitchen | Source-confirmed ownership/identity issue |
| A03 | P1 | Hand-cursor mirroring and offset tests fail | Simulator test run |
| A04 | P2 | Marathon home displays classic results; marathon results are not saved there | Source-confirmed integration gap |
| A05 | P2 | Every shop item is locked when opened from Planet 2 | Source-confirmed incompatible unlock IDs |
| A06 | P2 | Planet 2 opens Planet 1's recipe book | Source-confirmed content gap |
| A07 | P2 | Interrupting a resume countdown can leave a kitchen stopped | Source-derived lifecycle failure; device reproduction pending |
| A08 | P2 | Inventory persistence can crash at startup or silently fail writes | Source-confirmed error paths |
| A09 | P2 | A pending camera start can run after a stop request | Source-derived callback ordering; device reproduction pending |
| A10 | P2 | Marathon report labels tips earned as total points | Source-confirmed value/label mismatch |
| A11 | P2 | Story-level loading errors silently launch classic mode | Source-confirmed fallback behavior |
| A12 | P2 | Custom volume sliders have no accessibility adjustment action | Source-confirmed missing semantics; assistive-device check pending |
| A13 | P3 | Level validation accepts dangerous numeric configurations | Source-confirmed validation gap; shipped values checked |
| A14 | P3 | Build emits concurrency and missing-accent-color warnings | Compiler/asset build output |

### A01 — The project cannot be reconstructed from tracked files

**Evidence:** [`.gitignore`](../../.gitignore), line 65, excludes `PlayFeat.xcodeproj/project.pbxproj`. `git ls-files PlayFeat.xcodeproj` lists the workspace metadata and shared scheme, but not the project definition. No XcodeGen/Tuist project specification was found.

**Impact:** a teammate or CI checkout lacks targets, build settings, folder membership, and the configuration that supplies the camera usage description. Having synchronized source folders does not replace the Xcode project itself. The local successful build does not establish that the repository is buildable elsewhere.

**Recommended change:** track the project definition, or track a generator specification and a documented generation command. Keep personal Xcode state ignored. Validate the intended iPadOS 17 minimum from the resolved target settings; the current simulator build used 17.0, while project-level settings also contain 26.5.

**Acceptance check:** a clean checkout builds and runs the unit test plan using only tracked configuration, without copying another developer's local project.

### A02 — Language switching discards story-run state

**Evidence:** [`ContentView.swift`](../../PlayFeat/UI/Screens/ContentView.swift), line 60, applies `.id(language)` around the screen subtree. [`KitchenView.swift`](../../PlayFeat/UI/Screens/KitchenView.swift), lines 31 and 54–68, owns a story `KitchenDay` in local `@State`. Settings is reachable from the kitchen's pause popup, and [`SettingsView.swift`](../../PlayFeat/UI/Overlays/SettingsView.swift) changes the language immediately.

**Trigger:** play part of a story day, pause, open Settings, and change ENG/IND.

**Impact:** the identity change destroys the old kitchen subtree, including the day, calibration, countdown, scene, and pause/settings state. The replacement story kitchen initializes a fresh day, losing the current run. Marathon retains its day through `SceneManager.marathon`, but still recreates scene-local stations and carried/cooking items, so its restoration is incomplete too.

**Recommended change:** retain the complete active-session state outside the language-keyed subtree, or refresh localized presentation without replacing the gameplay owner. Merely preserving `KitchenDay` would not preserve scene-local item state.

**Acceptance check:** changing language during a paused story or marathon preserves elapsed time, score, customers, cooked/held items, calibration, and pause status. Add a focused view/lifecycle regression check.

### A03 — Cursor orientation has no passing regression baseline

**Evidence:** [`HandCursorNode.swift`](../../PlayFeat/Scenes/Nodes/HandCursorNode.swift), lines 64–83, uses `.left ? 1 : -1` for both offset and art mirroring. [`HandCursorNodeTests.swift`](../../Testing/PlayFeatTests/Scenes/Nodes/HandCursorNodeTests.swift) expects the opposite art convention and a negative right-hand horizontal offset.

Five failing test definitions:

- `chiralityControlsTheArtworkOnEitherHalfOfTheScreen(chirality:)`
- `unknownChiralityKeepsTheArtworkAndHeldFoodPosition(chirality:)`
- `aKnownReadingUpdatesBothTheArtworkAndHeldFoodPosition()`
- `anInitiallyUnknownCursorUsesDefaultArtUntilIdentified()`
- `aRightHandHoldsFoodUpAndToTheLeftOfThePalm()`

The last test observed `offset.dx == 88.0`, where it expects a negative value. The parameterized tests account for multiple failing executions/assertions.

**Impact:** the existing suite is red, and implementation, comments, and tests disagree about the art's handedness. A test failure alone does not prove which convention matches the actual artwork.

**Recommended change:** inspect the current hand textures and mirrored-camera convention on a device, establish the intended left/right orientation, and align both implementation and meaningful assertions with that decision. Do not invert assertions solely to obtain a green run.

**Acceptance check:** all cursor tests pass, and food appears at the drawn fingertips for both hands on either side of the screen.

### A04 — Marathon scores are disconnected from its home screen

**Evidence:** [`MarathonView.swift`](../../PlayFeat/UI/Screens/MarathonView.swift), lines 17 and 31–32, reads `GameStorage.highscore` and the existing Game Center ranking. [`GameStateManager.swift`](../../PlayFeat/Game/GameStateManager.swift), line 303, saves/submits classic dish counts. [`KitchenView.endDay`](../../PlayFeat/UI/Screens/KitchenView.swift), line 243, shows the marathon report without saving a marathon best or submitting it.

**Impact:** finishing a marathon does not update its displayed “Highest Score.” The ranking on that screen represents classic dish counts, while marathon results use points. The problem is already acknowledged in [the Game Center system guide](../systems/17-game-center.md).

**Recommended change:** define the marathon score unit and whether bests are per planet. Give them separate storage keys and, if needed, separate leaderboard IDs; save once at marathon completion. Preserve classic rankings in their original unit.

**Acceptance check:** a completed marathon updates the appropriate best; a lower score does not replace it; signed-out/offline play still saves locally; the leaderboard and home label describe the same unit.

### A05 — Planet 2's shop is permanently locked

**Evidence:** [`PlanetSelectView.swift`](../../PlayFeat/UI/Screens/PlanetSelectView.swift), line 73, passes only `GameStorage.clearedLevels(on: planet)` into `ShopPopup`. [`KitchenShop.swift`](../../PlayFeat/Data/Models/KitchenShop.swift), lines 46–58, defines only upgrades unlocked by `1-*` levels. The predicate checks exact membership of `availableAfter`.

**Impact:** Planet 2 supplies `2-*` cleared IDs, so every item is locked even after finishing Planet 2. Ingredient offerings also belong to Planet 1. Existing globally owned tool upgrades can still apply in play, making the locked presentation more confusing.

**Recommended change:** make the shop catalog planet-aware, or explicitly expose a shared shop with the full relevant progression set. If Planet 2's shop is unfinished, provide an accurate unavailable state.

**Acceptance check:** test each planet's available/locked/maxed offerings against its progression, including a player who already owns Planet 1 upgrades.

### A06 — Planet 2 lacks relevant recipe guidance

**Evidence:** [`PlanetSelectView.swift`](../../PlayFeat/UI/Screens/PlanetSelectView.swift), line 67, opens `RecipeBookView` without planet context. [`RecipeBook.swift`](../../PlayFeat/Data/Models/RecipeBook.swift), line 39, contains baked flatbread, two flatbread dishes, and Slimy Tentacles only. Planet 2 defines four different dishes in [`K2332b.swift`](../../PlayFeat/Data/Models/Level/Planet/K2332b.swift). Every existing recipe description is also placeholder lorem ipsum.

**Impact:** players on Planet 2 cannot learn its noodle, clam, or cookie recipes from the book accessible on that board. Existing recipe-book coverage intentionally checks Kepler only.

**Recommended change:** supply entries for the selected planet, derive preparation steps from its kitchen rules, replace placeholder descriptions, and localize the new text.

**Acceptance check:** every playable dish on every planet has accurate preparation guidance, including pot/grill intermediates and dessert stations.

### A07 — Resume-countdown interruptions can strand the kitchen

**Evidence:** [`KitchenView.swift`](../../PlayFeat/UI/Screens/KitchenView.swift), lines 186–192 and 338–359. On return, `isInterrupted` is cleared before the resume countdown finishes. A subsequent interruption only sets it when `day.isRunning` is true; during the countdown the day is stopped. The countdown task can then finish while inactive, fail its final phase guard, and return without starting the day or scheduling another countdown.

**Trigger to verify:** background a running day; return; during the new countdown, open Control Center and leave it open until the countdown would finish; dismiss Control Center.

**Impact:** the next `.active` sees `isInterrupted == false` and leaves the day stopped. Recovery may require manually opening pause/resume or restarting. The initial start countdown also lacks a foreground check before `day.start()`.

**Recommended change:** model countdown/resume as lifecycle state, keep a pending resume until play actually starts, and cancel/restart countdowns across inactivity. Keep manual pause separate from app interruption.

**Acceptance check:** repeated interruptions during initial and resume countdowns always recover to an intentional paused/counting/running state, with no clock advance outside active play.

### A08 — Inventory failures can terminate launch or lose purchase consistency

**Evidence:** [`InventoryManager.swift`](../../PlayFeat/Data/Storage/InventoryManager.swift), line 29, calls `fatalError` if the SwiftData container cannot open. Fetches and saves at lines 36, 41, 55, and 65 discard errors. [`PlayFeatApp.swift`](../../PlayFeat/App/PlayFeatApp.swift) constructs inventory unconditionally at launch. The classic [`ShopView.buyItem`](../../PlayFeat/UI/Screens/ShopView.swift), line 197, subtracts UserDefaults coins before adding an inventory multiplier.

**Impact:** an inventory initialization failure prevents access to the whole game. A failed fetch is treated like an empty inventory; a failed save can appear successful in memory. In the retained classic shop, coin spending and granting inventory can diverge because they use separate stores and errors are suppressed.

**Recommended change:** distinguish fetch failure from absence, propagate save failures, present a recoverable storage state, and coordinate purchases so the debit and grant succeed together or compensate on failure. Avoid silently replacing persistent inventory with an unsaved empty record.

**Acceptance check:** inject container/fetch/save failures; the app remains recoverable, no successful grant/consume is reported after a failed save, and failed purchases do not remove coins.

### A09 — Camera start callbacks do not honor later stop requests

**Evidence:** [`CameraSession.start`](../../PlayFeat/Camera/CameraSession.swift), line 89, waits for an authorization callback and then always configures/starts if granted. [`CameraManager.requestCameraPermission`](../../PlayFeat/Camera/CameraManager.swift) dispatches even an already-authorized response asynchronously. `stop()` only queues a stop; it does not invalidate pending starts. `HandPoseManager` records `isCameraWanted`, but the completion does not check it before starting capture.

**Impact:** a start followed immediately by stop can queue the stop before the permission completion queues its start. The camera can consequently restart after leaving the requesting screen or suspending the app. The frame processor's suspension guard reduces background Vision work but does not cancel capture startup.

**Recommended change:** track desired running state or a start-generation token, recheck it after authorization and on the session queue, and invalidate pending work when stopping/suspending. Also set `isConfigured` only after configuration succeeds so failed input setup can recover.

**Acceptance check:** start/stop before permission completion, rapid navigation, and foreground/background transitions leave capture running only when an active screen still requests it.

### A10 — Marathon report displays two different values as points

**Evidence:** [`MarathonReportView`](../../PlayFeat/UI/Overlays/MarathonOverlays.swift), lines 258–259, supplies `totalLabel: "Total Points"` with `total: session.coinsEarned`. The same report separately shows `session.points` under “Total Marathon Points.” In [`MarathonSession.swift`](../../PlayFeat/Game/Marathon/MarathonSession.swift), `coinsEarned` is tips, whereas `points` is the day's total score.

**Impact:** the report labels tip coins as points and can show contradictory totals.

**Recommended change:** use `session.points` for the points total, or label the tip total as marathon coins earned, according to the intended report design.

**Acceptance check:** a run whose dish earnings and tips differ displays distinct, correctly labeled values.

### A11 — A broken story level silently becomes a different game mode

**Evidence:** [`PlanetSelectView.startLevel`](../../PlayFeat/UI/Screens/PlanetSelectView.swift), line 249, catches every loader error through `try?` and opens classic gameplay. The detail popup also suppresses loader errors. [`SceneManager.goToNextLevel`](../../PlayFeat/App/SceneManager.swift) similarly treats load failure as a return to the board.

**Impact:** missing, undecodable, and invalid level files produce no diagnostic for the player and can send them to unrelated classic play, where completing a run will not clear the selected story level. All shipped level-load tests passed; this is a failure-path risk.

**Recommended change:** surface a localized load-failure state with level ID and a return action; log the underlying typed error for diagnosis. Treat the end of a planet separately from an invalid next level.

**Acceptance check:** missing and malformed level fixtures show a recoverable error and never start classic gameplay implicitly.

### A12 — Volume controls are drag-only custom drawings

**Evidence:** [`VolumeSlider`](../../PlayFeat/UI/Overlays/SettingsView.swift), line 139, renders shapes with a `DragGesture`; it supplies no accessibility label, current value, or `accessibilityAdjustableAction`. The adjacent row label does not turn the drawing into an adjustable control.

**Impact:** assistive-technology users lack the standard adjustment action available on a native slider. This deserves particular attention in a game designed with a disability-support community.

**Recommended change:** use a styled native `Slider`, or expose one labeled adjustable accessibility element with a percentage value and bounded increment/decrement behavior.

**Acceptance check:** both music and sound-effects volume can be identified and adjusted through VoiceOver and an appropriate Switch Control workflow, without a precise drag.

### A13 — Invalid numeric level values can pass validation

**Evidence:** [`LevelValidation.swift`](../../PlayFeat/Data/Models/Level/LevelValidation.swift), line 29, validates item IDs, slots, lanes, star ordering, and useful-bubble share, but not positive timing fields or `refill.angryEvery`. [`RefillFlow.isAngry`](../../PlayFeat/Game/Level/RefillFlow.swift), line 91, evaluates `number % angryEvery`; zero traps.

**Impact:** a future JSON edit such as `angryEvery: 0` passes validation and can crash gameplay. Zero/negative bubble lifetimes and invalid patience/timing values also escape validation. The additional checks in this audit found no such values in shipped files; these levels are bundled content, not remote input.

**Recommended change:** validate positive durations/intervals, nonnegative appropriate values, finite weights, and positive non-null repeat frequencies. Return contextual `LevelDataError` cases.

**Acceptance check:** invalid numeric fixtures fail at load time; valid current levels continue to load.

### A14 — Compiler diagnostics show unresolved isolation boundaries

The test build reported application warnings at:

- [`FlyingFuelStar.swift`](../../PlayFeat/UI/Components/PlanetSelect/FlyingFuelStar.swift), line 39: a `nonisolated` geometry function references main-actor-isolated `arcLift`.
- [`TutorialPage.swift`](../../PlayFeat/Data/Models/TutorialPage.swift), line 76: a synchronous nonisolated context calls main-actor-isolated `AppLocalization.string`.
- [`GameStorage.swift`](../../PlayFeat/Data/Storage/GameStorage.swift), line 36: a function reference to actor-isolated `bestStars(forLevel:)` crosses a nonisolated context.
- Test macros and [`FlyingFuelStarTests.swift`](../../Testing/PlayFeatTests/UI/Components/PlanetSelect/FlyingFuelStarTests.swift), line 21: additional isolation/async diagnostics, several explicitly identified as errors in Swift 6 language mode.
- Asset compilation: configured accent color `AccentColor` is absent from the catalogs.

**Impact:** the current Swift 5 language-mode build succeeds, but actor boundaries are not warning-clean and migration to Swift 6 will require work. Missing accent configuration can affect controls using the default accent. App Intents metadata-skip notices were also emitted; they are not treated as defects because the app does not use App Intents.

**Recommended change:** make pure geometry/constants explicitly isolation-compatible, keep localization/storage calls on their intended actor, resolve test isolation, and align the accent build setting with an existing catalog color. Avoid blanket `nonisolated(unsafe)` suppression.

**Acceptance check:** rebuild the current targets without these warnings, then evaluate Swift 6 mode separately from feature changes.

## What is working well

- Game rules are largely small, independent types. Customer flow, cooking tools, star ratings, progression, and bubble supply have substantial direct tests.
- `HandFrameProcessor` owns processing on a serial video queue and publishes a frame result onto the main thread. Camera/view coordinate mapping and player identity are separated and tested.
- Story and marathon rules share `KitchenDay` while using distinct customer/bubble strategies. Planet definitions centralize their kitchen and visual differences.
- Kitchen handover explicitly tears down the old camera/player/music owners before entering the next day; navigation tests exercise retry and restart paths.
- Level loading has typed errors and validates domain identifiers before play. Every currently bundled level passes the existing load/playability checks.
- One-hand mode, alternative pickup gestures, readable fonts, bilingual copy, and some explicit accessibility labels are already implemented. The current fuel-star animation reads Reduce Motion.
- The inspected camera path captures video only and processes frames locally; no frame-upload or recording path was found in the reviewed application source. Game Center remains optional for gameplay.

## Coverage and maintenance gaps

The existing tests are strongest around pure rules and geometry. They do not establish the correctness of SwiftUI view identity changes, settings during play, repeated foreground/countdown transitions, disk-error recovery, or live Game Center integration. UI tests currently launch the app or measure launch time without asserting a gameplay flow. No tracked GitHub Actions workflow was found.

Additional observations to keep visible:

- Energy is displayed but intentionally has no spending/regeneration implementation (`LevelData.energyCost`, `PlanetScreen`). Present it as unfinished behavior until the economy is implemented.
- Classic `RunTally` increments at recipe completion, before successful bell delivery. Consequently “Dishes Served,” rewards, and its leaderboard count can include an assembled dish that later fails serving. Decide the intended score definition before sharing score units with marathon.
- `GameStateManager.gameOver()` has no idempotency guard before saving and consuming a multiplier. Existing callers should prevent duplicate completion, but a repeated direct call would pay/save again; protect the boundary before adding new callers.
- `GameStorage.buyUpgrade` trusts a caller-supplied ID and price and does not enforce unlocked/maxed catalog state. The current popup supplies a validated offer; moving these checks into the purchase operation would protect future callers and rapid repeated actions.
- Global UserDefaults and static service calls make persistence side effects harder to isolate. In-memory SwiftData test inventory does not also isolate `GameStorage` writes made by game-over tests.
- Root documentation and comments retain classic-mode assumptions, while the detailed system guides are closer to the current product. Some guides also lag the current uncommitted flying-star work. Keep feature-status statements synchronized with code.

## Suggested remediation order

1. Restore a reproducible tracked Xcode configuration and resolve the cursor-test baseline (A01, A03).
2. Preserve active-session ownership across language changes and stabilize interrupted countdown/camera transitions (A02, A07, A09).
3. Connect marathon persistence, leaderboard units, and report values (A04, A10).
4. Make shops and recipe guidance correct for each planet, with clear level-load failures (A05, A06, A11).
5. Add recoverable inventory persistence and accessible volume controls (A08, A12).
6. Harden content validation, resolve warnings, and add CI plus targeted lifecycle/UI coverage (A13, A14).

Re-run the existing test plan after implementation, then perform real-iPad checks for permission denial/recovery, both hands, one-hand mode, gestures, serving, rotation, language changes during pause, repeated interruptions, and signed-out/offline results. Simulator success cannot verify the camera interaction itself.

[Project README](../../README.md) · [System documentation](../systems/README.md)
