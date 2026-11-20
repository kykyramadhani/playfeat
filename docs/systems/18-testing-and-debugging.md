# Testing and debugging

## What is testable without the camera

Most rules are small value types or accept injected dependencies. Hand classification math, gesture evidence, identity matching, coordinate mapping, customer rules, recipes, stations, supply and scoring can be tested using made-up inputs.

Scenes read `HandInputSource` and `SoundPlaying`, so tests can use `ScriptedHandInput` and `SoundRecorder`. `SeededGenerator` makes random customer/supply behavior reproducible. `InventoryManager(inMemory: true)` isolates the SwiftData inventory for tests that need it.

These tests do not establish real Vision recognition accuracy, camera exposure behavior, GPU latency, sound hardware behavior or Game Center delivery.

## Test organization

| Folder | Main coverage |
|---|---|
| `App` | Screen routes, story report staying in the kitchen, Back/Next/Retry |
| `Camera` | Format ranking and zoom clamping |
| `Vision` | Mapping, player selection, body-hand matching, calibration and input modes |
| `Vision/Gestures` | Pinch thresholds, geometry, evidence timing, identity and dwell |
| `Game/Level` | Story customers/scoring, stations, grill, tools, supply and progress |
| `Game/Marathon` | Session, cards, stages and run behavior |
| `Game` | Classic matching, clocks, lives, events, difficulty and pause |
| `Scenes` | Grab/drag/placement, rendering geometry, serving and item appearance |
| `Data/Models` | Shop catalog/offers and recipe-book consistency |
| `Data/Storage` | Bundled level loading/validation |
| `Resources` | Referenced artwork exists |
| `Shared/Localization` | Resource languages and runtime translation behavior |
| `UI` | Layout and HUD/overlay geometry rules |

The repository uses Swift Testing (`@Test`, `#expect`, `#require`) for unit tests. The separate UI-test target still contains starter-style coverage. `Testing/Functionality.xctestplan` selects `PlayFeatTests`; inspect the shared scheme to see which test targets and launch configuration your current checkout enables.

## Running checks

Open `AstroFeast.xcodeproj`, choose an available iPad simulator and run the unit tests with Xcode's test action. For command-line use, first discover destinations:

```sh
xcodebuild -showdestinations -project AstroFeast.xcodeproj -scheme AstroFeast
```

Then replace `SIMULATOR_UDID` below with a real available destination ID:

```sh
xcodebuild test \
  -project AstroFeast.xcodeproj \
  -scheme AstroFeast \
  -destination 'platform=iOS Simulator,id=SIMULATOR_UDID' \
  -derivedDataPath /tmp/playfeat-tests-derived \
  -only-testing:PlayFeatTests \
  CODE_SIGNING_ALLOWED=NO
```

Use `-only-testing:PlayFeatTests/SceneManagerTests` when investigating that suite. The local project contains recommended-SDK deployment settings and higher project-level values even though older prose describes iOS 17 support. Check effective build settings and your installed runtimes; do not assume every old simulator qualifies. The app target enables Mac Catalyst, while current unit-test targets are configured for iPad rather than Catalyst.

The project includes the shared AstroFeast scheme and the Functionality test plan.

## Debug launch arguments

The Debug-only helpers in `DesignScale.swift` accept:

| Argument | Effect |
|---|---|
| `-debugGameplay YES` | Skip launch/tutorial/calibration into the classic game route |
| `-debugSkipSeatCheck YES` | Bypass the planet kitchen's seat check; it does not synthesize hands |
| `-debugScreenSize 1133x744` | Simulate a layout/window size |
| `-debugRotateAfter 8` | Change the simulated dimensions after a delay |
| `-debugLandscape YES` | Request landscape presentation for layout checks |

These paths are compiled under `DEBUG`. Verify the scheme's Run configuration before expecting them to work. A simulator can test layout and scripted interaction but is not a substitute for a real camera hand-tracking session.

## Symptom-based investigation

### Hand is missing or flickering

Check authorization, frame delivery, selected body, required input-mode wrist, joint confidence, body-wrist filtering and identity coasting—in that order. Debug logs report dropped classifications, missing player bodies, rejected wrist matches, continuation rescues and coasting.

### Hand moves slowly, while FPS seems fine

Separate rendering FPS, processed camera-result frequency, Vision duration, main-thread publication delay, cursor smoothing and carried-food smoothing. The current capture path caps maximum rate at 30 where configured, body detection runs every third frame, and cursor smoothing is 0.5. The current SpriteView call sites do not enable an FPS counter by default.

### Food will not place, combine or serve

Inspect the exact item ID, station acceptance table, node placement and rule contents, target priority, typed customer seat, desired dish, refusal hold and play/round state. A raw bread on a plate is accepted storage there but is not baked and cannot complete a flatbread recipe.

### Stars or rewards look wrong

Stars use total kitchen income, not dishes delivered or the classic count. Compare the total with the JSON thresholds and confirm that previous best was read before saving. Current report stars reveal in place; no flying animation is expected. Progress is reloaded on returning to the board.

### Tests disagree with the current cursor art

The current cursor code uses left `xScale = 1`, right `-1`, and updated pinch/size constants. Some existing cursor tests still assert the earlier convention. Inspect that source mismatch and verify the intended mirrored-camera appearance before deciding whether to change artwork logic or expectations. Do not change unrelated gameplay to make a stale image-orientation assertion pass.

### A language or setting does not update

Trace the shared key constant, persistence write and live consumer. Check language apply-before-store ordering, compiled `.lproj` resources and plain-String versus localized text. Check view lifetime when the root language identity rebuilds.

## Device verification

For camera/interaction changes, play through calibration, one/two-hand mode, Pinch/F-Pinch, pickup, cooking, assembly, magnetic serving, deliberate release and brief tracking loss. Repeat after rotation/window resizing, a background round trip, pause/resume, Retry and Next. For rule changes, also exercise overtime, a failed day and postgame persistence.

Record actual runtime evidence when reporting a performance or animation fix. A compiling view and passing navigation tests alone do not prove that a visual animation is visible on screen.

## Source map

- [Unit test tree](../../Testing/PlayFeatTests/)
- [Test plan](../../Testing/Functionality.xctestplan), [shared scheme](../../AstroFeast.xcodeproj/xcshareddata/xcschemes/AstroFeast.xcscheme)
- [Scripted hands](../../Testing/PlayFeatTests/Scenes/ScriptedHandInput.swift), [sound recorder](../../Testing/PlayFeatTests/Audio/SoundRecorder.swift), [seeded generator](../../Testing/PlayFeatTests/Shared/SeededGenerator.swift)
- [Launch/layout helpers](../../PlayFeat/Shared/DesignScale.swift)
- [Existing cursor expectations](../../Testing/PlayFeatTests/Scenes/Nodes/HandCursorNodeTests.swift)

Related: [architecture](01-architecture-and-app-lifecycle.md), [hand tracking](03-hand-tracking-and-gestures.md), [rendering](16-rendering-assets-and-layout.md). [Back to index](README.md).
