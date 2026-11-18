# Architecture and app lifecycle

## The main separation

The app combines three layers:

1. **Input:** AVFoundation captures camera frames; Vision converts them into selected-player body and hand data.
2. **Rules and state:** `KitchenDay` and related value types own kitchen scoring, customers, cooking rules and progression calculations. The classic game uses `GameStateManager` instead.
3. **Presentation and interaction:** SwiftUI owns screens, backgrounds and popups. SpriteKit scenes own moving nodes, hit areas, hand interaction and frame-by-frame rendering.

The important direction is `camera → processed hand data → scene interaction → game state → UI`. Views can observe the same game objects that a scene updates, but image recognition does not belong in a view or in a node.

## Object ownership

| Owner | Creates or retains | Lifetime |
|---|---|---|
| `PlayFeatApp` | `AudioManager`, `InventoryManager`, `HandPoseManager`, a separate `CameraManager` | App lifetime |
| `ContentView` | `SceneManager`, launch-screen visibility | Root interface lifetime |
| `HandPoseManager` | Its actual `CameraSession` and `HandFrameProcessor` | Shared across screens |
| `KitchenView` | Story `KitchenDay`, `KitchenScene`, calibration/countdown/pause presentation state | One kitchen visit |
| `SceneManager` | Active `MarathonSession`, current story `LevelReport`, route and kitchen visit number | Root interface lifetime |
| `MarathonSession` | One continuing `KitchenDay`, upgrades and round bookkeeping | One marathon run |
| `GameplayView` | Classic `GameStateManager` and `GameScene` | One classic run |

The separate `CameraManager` property on `PlayFeatApp` is not the live capture session. Actual frames are produced by `handPoseManager.camera` (`CameraSession`), which has its own permission helper. Trace the actual owner before changing camera behavior.

## Dependency injection

`PlayFeatApp` installs audio, inventory, hand tracking, scene phase and the SwiftData container into the environment inside `PhoneSafeSides`. That placement matters: on supported phone layouts the wrapper uses a separate hosting controller, and SwiftUI environment values do not automatically cross that controller boundary.

Scenes receive explicit, weak dependencies such as `day`, `handInput` and `audio`. `HandInputSource` and `SoundPlaying` let scene tests substitute scripted hands and a sound recorder. There is no need for a camera or speakers to test most interaction rules.

## State and updates

The main shared reference types use `@Observable`. SwiftUI subscribes to properties it actually reads. Rapidly changing implementation details are sometimes marked `@ObservationIgnored`: examples include classic countdown internals and audio players. This avoids redrawing the interface for every internal tick.

`KitchenScene.update(_:)` advances its `KitchenDay` using SpriteKit's current time, computes the change in play time, synchronizes tools, requests due bubbles, moves loose items, updates cooking, processes hands, then updates target glows. The classic manager uses its own timer and event log; its scene polls state and numbered events.

## Threads

| Execution context | Work |
|---|---|
| Main actor/thread | SwiftUI, SpriteKit state, published hand data, navigation, storage-facing UI |
| Camera session queue | Capture configuration and starting/stopping the session |
| Camera video queue | Frame callback, synchronous Vision processing, identity/gesture state |

`HandPoseManager` performs the processing on the video queue and dispatches the completed output to the main queue. `HandFrameProcessor` is `@unchecked Sendable` because its mutable state is deliberately confined to that queue. Its `nonisolated` declarations are not permission to call it concurrently.

The project currently sets default actor isolation to `MainActor`. Pure rules and background-used data types explicitly opt out where needed.

## Leaving and returning to the app

`PlayFeatApp` reacts to scene phase:

- `.inactive`: suspend frame processing and stop the camera before background GPU work becomes disallowed.
- `.background`: keep tracking suspended and fade out music.
- `.active`: resume tracking if a screen still wants the camera; fade paused music back in.

`HandPoseManager` keeps `isCameraWanted` separate from suspension. Returning to the foreground should not start the camera if the player already left gameplay or reached the report.

Screens separately freeze their game clock and SpriteKit rendering. Kitchen play uses `day.pause()`; the SpriteView is paused outside the foreground and when the day is over. A return from the background requests a new countdown. A brief inactive interruption can resume directly. The classic screen has parallel logic using its manager's pause state.

Story results keep `KitchenView` mounted. `endDay()` stops music and the camera, banks the result once, and sets `SceneManager.levelReport`. Changing the report does not change `screen`; Back/Next/Retry perform navigation later.

## Change boundaries and common mistakes

- Add a gameplay rule to its rules type, not to the HUD that displays it.
- Keep camera configuration off the scene update loop.
- A camera can be running while no camera preview is visible: the kitchen needs tracking after calibration.
- Pausing `KitchenDay` stops play time; pausing a SpriteView stops its rendering loop. They address different work.
- Retrying the same level must increment `kitchenVisit`. `ContentView` keys the kitchen with that number to construct a fresh day.
- Never assume the classic event-driven flow also drives kitchen effects or score persistence.

## Source map

- [App composition](../../PlayFeat/App/PlayFeatApp.swift)
- [Root screen switch](../../PlayFeat/UI/Screens/ContentView.swift)
- [Route ownership](../../PlayFeat/App/SceneManager.swift)
- [Kitchen screen and lifecycle](../../PlayFeat/UI/Screens/KitchenView.swift)
- [Kitchen update loop](../../PlayFeat/Scenes/KitchenScene/KitchenScene.swift)
- [Input publication](../../PlayFeat/Vision/HandPoseManager.swift)
- [Navigation tests](../../Testing/PlayFeatTests/App/SceneManagerTests.swift)

Related: [menus](10-menus-and-navigation.md), [storage](14-storage-and-inventory.md), [testing](18-testing-and-debugging.md). [Back to index](README.md).
