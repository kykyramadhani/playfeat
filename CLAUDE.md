# PlayFeat

A hand-tracking cooking game made with and for the community at PUSPADI
(Pusat Pemberdayaan Penyandang Disabilitas), Bali — Apple Developer Academy
Challenge 5 & Final Challenge.

The front camera and Vision track the player's hands and upper body; the
hands are drawn as cartoon hands over an illustrated planet kitchen. Players
pinch floating ingredient bubbles, cook and assemble dishes at the counter,
and serve them to alien customers before their patience runs out. No touch
input is needed during play.

## Platforms

| Platform | Status |
|---|---|
| iPadOS | **Published** — the only shipping target right now |
| iOS (iPhone) | Planned. Taken out of the app target (`TARGETED_DEVICE_FAMILY = "2,6"`) until it is tested; layouts already scale |
| macOS | Planned. Some Mac code paths exist (`ProcessInfo.isiOSAppOnMac`), not shipped |

- **Minimum OS: iOS / iPadOS 17.0.** Don't use APIs newer than 17 without an
  `if #available` check and a fallback.
- Landscape lock (left and right), portrait is still being used but added hints unavailable, because of the new requirement of iOS 27.
- Languages: English (`en`) and Indonesian (`id`), in `Localizable.xcstrings`.

## Capabilities in use

- **Camera** — front camera through AVFoundation (`NSCameraUsageDescription`).
  Picks the widest format and turns off Center Stage so both hands and the
  torso stay in frame.
- **Vision** — `VNDetectHumanHandPoseRequest` (hands) and
  `VNDetectHumanBodyPoseRequest` (finds the nearest player, ignores bystanders).
- **SpriteKit** — the kitchen board (`KitchenScene`): bubbles, hands, stations.
- **SwiftUI** — every screen, overlay and HUD element.
- **Game Center** — sign-in, one Buffet leaderboard per planet and the story
  achievements (`com.apple.developer.game-center` entitlement). Always
  optional: the game works fully offline or signed out.
- **UserDefaults** — coins, stars, energy, upgrades, seen introductions and
  settings (`GameStorage`, `EnergyStore`, `@AppStorage`).
- **AVAudio** — music and sound effects.
- **Accessibility** — Atkinson Hyperlegible font, one-hand mode in Settings.

One third-party dependency: **Lottie** (`lottie-spm`, SPM), which plays the
intro story's panel animations (`Resources/Animation/IntroStory/`). Their
artwork comes from the asset catalog (`Story/`); captions stay in SwiftUI so
they can be translated. Ask before adding any other package.

### Game flow

```
Launch screen → LaunchView (loading bar)
      │ first launch after install only
      ▼
Intro story (six Lottie comic panels) ──▶ Galaxy map
                                              │ a planet
                                              ▼
                                  Planet level board ──▶ Buffet screen (marathon)
                                              │ a level         │ PLAY
                                              ▼                 ▼
               Kitchen: seat check → 3-2-1 → story day / Buffet run
                                              ▼
                     Report over the frozen kitchen → NEXT / RETRY / board
```

- `SceneManager` (App/) holds the current `AppScreen` (`introStory`, `galaxy`,
  `planetSelect`, `marathon`, `kitchen(LevelData)`, `kitchenHandover`);
  `ContentView` switches on it. There is no `NavigationStack`: every exit
  jumps to a known screen. The seat check, countdown and report are *phases
  inside* `KitchenView`, not separate screens.
- NEXT / RETRY / RESTART go through `kitchenHandover`, so the old kitchen is
  torn down before a fresh one is built.
- Starting a story level spends energy (`EnergyStore`).

### A story day and a Buffet run

- **Story day** (`KitchenDay` + `RefillFlow`, Game/Level/): a 90-second day.
  Alien customers step up to the counter with an order; the player cooks and
  assembles it from bubbles and serves it over the customer. Patience zones
  set the tip; a customer who runs out of patience leaves. New customers stop
  10 s before the end, and whoever is still waiting can be served in overtime.
  Stars come from the day's points.
- **Buffet** (`MarathonSession` + `MarathonFlow`, Game/Marathon/): one
  continuous day of rounds with card breaks between them; three lost
  customers end it. Each planet's best points go to its Game Center
  leaderboard.

## Architecture

`KitchenView` assembles a day, back to front:

1. **Kitchen art** — `KitchenBackdrop`, the planet's illustrated kitchen. The
   camera preview (`CameraPreviewView`) shows only during the seat check; it
   reuses the capture session in `HandPoseManager`.
2. **Game layer** — `KitchenScene`, a transparent SpriteKit scene. Owns all
   physical interaction: bubbles, hands, stations, grab/drag/drop, serving.
3. **HUD layer** — SwiftUI overlays: orders, patience, points, pause,
   countdown, reports, Buffet cards.

Data flows one way: **Vision → Game → Scene / UI**. `KitchenScene` reads hand
data and the day's state every frame in `update(_:)` (polling suits a 60 fps
loop). SwiftUI observes the same objects.

## Folder structure

```
PlayFeat/
├── App/        Entry point, root navigation and screen routing
├── Game/       Game rules and state: story days, Buffet runs, scoring, clocks.
│               No SwiftUI or SpriteKit here.
├── Vision/     Everything built on the Vision framework: hand and body pose
│   └── Gestures/  Gesture detectors built on pose data (pinch, grip, hover)
├── Camera/     Camera permission, device and format selection, preview view
├── Audio/      Music and sound effects
├── Network/    Online services (Game Center)
├── Data/
│   ├── Models/   Plain data types (levels, planets, kitchen art, shop, ...)
│   └── Storage/  Saving and loading (UserDefaults)
├── Scenes/     Everything SpriteKit
│   ├── KitchenScene/  The kitchen scene, split into extensions by concern
│   └── Nodes/         Reusable SKNodes
├── UI/         Everything SwiftUI
│   ├── Screens/     Full-screen views (one per navigation destination)
│   ├── Overlays/    Views shown over gameplay
│   ├── Components/  Reusable building blocks (buttons, cards, ...)
│   └── Styles/      Button and view styles
├── Shared/     Small helpers used everywhere: extensions, layout scaling,
│               localization
└── Resources/  Assets, fonts, sounds, level JSON, Lottie animations

PlayFeatTests/    Unit tests. Same folders as the app, so the tests for
                  Vision/ live in PlayFeatTests/Vision/
PlayFeatUITests/  UI tests (still starter scaffolding)
```

Put a new file in the folder whose job it matches. If it doesn't fit any of
them, ask before making a new top-level folder. Don't create folders grouped
by language construct (no `Enums/`, `Protocols/`, `Extensions/` at the top
level). Keep a type next to the feature that uses it.

All three targets use Xcode **synchronized folders**: moving or adding files on
disk needs no `project.pbxproj` edits.

## Clean code, style and conventions

**Every time you write or change code, follow the clean-code skill:**
@.claude/skills/clean-code/SKILL.md
Full checklist for larger changes and reviews:
@.claude/skills/clean-code/clean-code-rules.md

Summary:

- **Names explain intent.** Types are nouns (`RecipeCard`), functions are verbs
  (`serveDish()`). Avoid vague names like `data`, `info`, `helper`, `temp`.
- **Small functions that do one thing**, at one level of abstraction. Aim for
  under ~20 lines.
- **0–2 arguments**, 3 at most. Replace a Bool flag argument with two functions.
- **Commands vs. queries:** a function changes state *or* returns a value, not both.
- **Small types with one responsibility.** Find the type that owns new logic
  instead of adding it wherever is nearby.
- **Comments explain *why*, not *what*.** Rewrite confusing code rather than
  commenting it. Never commit commented-out code.
- **No force-unwraps (`!`) or silent failures.** Use optionals, `throws` and
  typed errors with context.
- **DRY, YAGNI, KISS, Boy Scout:** no duplication, nothing built for imagined
  needs, the simplest working solution, and leave each file cleaner.
- **Design patterns only when they remove a real problem**, not for show.

### Naming and formatting

- **camelCase** for variables, properties, functions and enum cases
  (`patienceLeft`, `case kitchenHandover`).
- **UpperCamelCase** for types and protocols (`KitchenDay`, `HandInputSource`).
- No `snake_case`, no Hungarian notation, no type prefixes.
- Shared point and number maths (`distance(to:)`, `eased(toward:by:)`,
  `clamped(to:)`) lives in `Shared/Extensions/CGPoint+Distance.swift` and is
  `nonisolated`, so the Vision pipeline can use it too. Use it instead of
  writing another `hypot` or `min(max())`.
- One main type per file, and the file is named after it. Extensions that split
  a type by concern go in a folder named after the type
  (`Scenes/KitchenScene/Hands.swift`).
- Header for new files:
  ```swift
  //
  //  FileName.swift
  //  PlayFeat
  //  Created by <Name> on <Current Date>.
  //
  //  One or two lines on what this type is for and why it exists.
  //
  ```
- Lines under ~120 characters. Group code with `// MARK: -`.

### Swift and SwiftUI

- Use `let` and value types (`struct`, `enum`) by default.
- Use `@Observable` for new observable classes, not `ObservableObject` /
  `@Published`. Pass them with `@State` / `@Environment` / `@Bindable`.
- Don't add new singletons (`static let shared`). Create objects once in
  `PlayFeatApp` and inject them.
- Keep SwiftUI `body` small; extract subviews as soon as it gets hard to scan.
- Colors and fonts come from the asset catalog and `Font+Atkinson`; layout sizes
  come from `DesignScale`. No magic numbers repeated across files.
- Every user-facing string goes through `Localizable.xcstrings` with an
  Indonesian translation. `LocalizationTests` fails if one is missing.
- Pull tricky math (coordinate mapping, gesture timing, matching) into a
  `static func` or a small struct so it can be unit-tested without a camera
  or SpriteKit view.

### Project-specific gotchas

- An asset's lookup name is its **imageset folder name**, and lookups are
  **case-sensitive**. `ArtAssetTests` catches mismatches.
- Two-part start: iOS shows `PlayFeat/Resources/Launch Screen.storyboard` while
  the app loads, then `LaunchView` shows the logo and loading bar. The launch
  screen is only the plain `SplashBackground` color. Don't add the logo or text
  to it: launch screens can't use Atkinson.
- Because `project.pbxproj` is gitignored, anything only the project file knows
  about never reaches a teammate's clone. So the launch screen is wired through
  tracked files: the storyboard lives inside the synchronized `PlayFeat/` folder
  (bundled automatically), and `UILaunchStoryboardName` is in
  `PlayFeat/Info.plist`. Keep both there even if Xcode's target settings also
  set them. iOS caches launch screens: delete the app (or reset the simulator)
  to see a change.
- `#expect` captures its argument immutably. Move a `mutating` call into a
  `let` before the macro (see `HoverDetectorTests`).
- Vision runs on a background video queue. Anything it publishes must be sent
  to the main thread.
- **No GPU work outside the foreground.** iOS rejects it
  (`kIOGPUCommandBufferCallbackErrorBackgroundExecutionNotPermitted`). Vision
  and SpriteKit both use the GPU, so leaving `.active` is handled in two places:
  - `PlayFeatApp` (app-wide): `.inactive` → `HandPoseManager.suspend()` drops
    frames before Vision and stops the camera; `.background` also fades the
    music out. `.active` resumes both (the camera only if a screen still
    wants it).
  - `KitchenView` (per day): pauses the day and `SpriteView` at `.inactive`
    too, since hand tracking is already off. A brief `.inactive` resumes at
    once; returning from `.background` plays a 3-2-1 first. A day killed by
    iOS while in the background is lost (no mid-day save).
  - `scenePhase` is forwarded explicitly into `ContentView`, because
    `PhoneSafeSides` hosts the app in its own hosting controller.

## Testing

- **⌘U** runs all unit tests (Swift Testing: `import Testing`, `@Test`, `#expect`).
- Run the tests **before and after every refactor**. They should pass both
  times with no changes to the tests.
- New logic comes with tests in the matching `PlayFeatTests/` folder.
- Camera and Vision changes also need a manual check on a real iPad: pinch,
  drag, drop, cooking, serving a customer, rotation, one-hand mode.

## Git workflow

- **Never commit directly to `main`.** Every new feature or fix gets its own
  branch from an up-to-date `main`:
  - `feature/<short-name>`, e.g. `feature/shop-screen`
  - `fix/<short-name>`, e.g. `fix/shorter-closing-window`
  - `refactor/<short-name>`, e.g. `refactor/observable-migration`
- **Commit messages have no fixed format, but must summarize the changes:**
  what changed and why, in plain words. One logical change per commit.
  - Good: `Move hand-tracking rules into OneHandMode / TwoHandMode strategies`
  - Bad: `update`, `fix stuff`, `wip`
- Run ⌘U before merging. Merge back into `main` through a pull request on GitHub.
- Claude: create or switch to the right branch **before** editing code, and
  commit or push only when asked.

## Reference
`CODE_AUDIT.md` lists known bugs and tech debt found in an earlier audit.

## Planned: multiplayer (two-iPad co-op)

The full design, message list, open questions and step order are in
[`docs/multiplayer-plan.md`](docs/multiplayer-plan.md). Read it before starting
any multiplayer work, and keep it up to date as decisions are made.
