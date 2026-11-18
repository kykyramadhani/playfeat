# Music and sound

## Ownership and interfaces

`PlayFeatApp` creates one `AudioManager` and injects it into SwiftUI. Scenes receive it through the `SoundPlaying` protocol. Tests use `SoundRecorder` instead of audio hardware. The classic game attaches a `GameAudio` listener to translate rule events into sound; the kitchen scene calls effect playback directly at interaction points.

Music control belongs to screens/session lifecycle, not to each ingredient node. A button usually uses `ClickButton`, which plays `.uiClick` before executing its action.

## Initialization

`AudioManager` configures an `.ambient` audio session, preloads WAV bytes for every `SoundEffect`, and reads saved volume settings. The capture session is video-only and explicitly avoids reconfiguring this shared audio session.

The manager retains active one-shot players until their delegate reports completion. Each play call creates its own player from cached data, allowing repeated/overlapping effects without cutting off the previous sound. Missing resources are logged or skipped; adding an enum case without bundling the file does not create sound automatically.

## Music tracks and rate

| Use | Caller behavior |
|---|---|
| Planet/galaxy/marathon-home chrome | `PlanetScreen` starts `home_soundtrack` |
| Kitchen/classic play after countdown | `startMusic()` defaults to `gameplay_getcooking` |
| End of day or screen teardown | Stop/fade gameplay music |
| Background/foreground | Fade/pause and resume the retained player |

Music files are resolved by base name with `.wav`. A music player loops indefinitely. Starting an already-playing identical track is a no-op, preventing every screen update or round from restarting it. Starting a different track stops/fades the old player and begins the new one with a fade-in; it does not wait synchronously for the old fade to finish.

The default music fade-in is 1.5 seconds; the usual stop and background fades are 0.6 seconds. `setMusicRate` is an absolute setter clamped to 0.5–2.0, with rate playback enabled on the player.

The classic `Difficulty` tier drives music tempo through `GameAudio`. Kitchen/marathon code does not currently apply that same tier-based tempo rule.

## Effects catalog

| Event/purpose | Enum / WAV base name |
|---|---|
| Reward/star chime | `addPoint` / `add_point` |
| Classic bell | `bell` / `bell_2x` |
| Grab and place | `bubbleGrab` / `bubble_grab`, `bubblePut` / `bubble_put` |
| Low classic dish time | `clockRunningOut` / `clock_running_out` |
| Countdown | `countdown` / `countdown321` |
| Lost life/failure feedback | `loseHeart` / `lose_heart` |
| Submit an order | `putOrder` / `put_order` |
| Reset | `reset` / `reset` |
| Button press | `uiClick` / `ui_click` |
| Refused/wrong ingredient | `wrongIngredient` / `wrong_ingredients` |
| Finished-dish cloud | `scuffleCloud` / `scuffle_cloud` |

Exact callers determine where these play. An enum's name is not a global subscription to all similarly named game events.

## Classic event-driven audio

`GameAudio.attach` sets the manager's single `onEvent` listener. The scene and HUD independently consume the numbered event log; they do not take that callback slot.

Run restart stops the warning, synchronizes tempo and plays reset. A lost life stops the warning and plays its sting. A dish served plays the order sound and schedules a reward chime 0.35 seconds later, unless the game has ended meanwhile. Low-time begin/end events start and stop a dedicated looping warning player.

The warning loop is separate from background music and ordinary one-shots. It must be stopped when the relevant countdown ends or play stops, not merely hidden with the HUD.

## Volume and background behavior

Effects default to 1.0 and music to 0.45. Settings persists the values and updates the live manager. `isEnabled` is a runtime master guard; the current Settings popup mainly exposes volumes rather than a persisted master switch.

Background fading marks a player as awaiting resume, lowers volume and pauses after the delay. The delayed pause checks that the same player is still current and the fade-out is still intended. Foreground return clears that flag, resumes and fades in. This prevents a late background callback from pausing music that already resumed.

`stopAll` immediately stops retained one-shots, warning and music. `stopMusic` clears the current music identity and also stops the warning when a music player is present.

## Troubleshooting and changes

For silence, check volume keys, runtime enable state, exact WAV resource name, loaded scene lifecycle and platform audio behavior. For repeated clicks, verify that a custom button is not playing `.uiClick` in addition to `ClickButton`. For runaway tempo, pass an absolute target rate rather than repeatedly adding a delta.

Add a new effect to `SoundEffect`, bundle its WAV, choose the owning event/interaction, and extend recorder-based tests if its timing or event mapping matters. Do not put `AVAudioPlayer` in a pure game-rules type.

## Source map and tests

- [Playback and lifecycle](../../PlayFeat/Audio/AudioManager.swift), [effects catalog](../../PlayFeat/Audio/SoundEffects.swift)
- [Scene protocol](../../PlayFeat/Audio/SoundPlaying.swift), [classic event listener](../../PlayFeat/Audio/GameAudio.swift)
- [Button sound wrapper](../../PlayFeat/UI/Components/Button/ClickButton.swift)
- [Home music owner](../../PlayFeat/UI/Components/PlanetSelect/PlanetScreen.swift), [kitchen owner](../../PlayFeat/UI/Screens/KitchenView.swift)
- [Audio event tests](../../Testing/PlayFeatTests/Audio/GameAudioTests.swift), [test recorder](../../Testing/PlayFeatTests/Audio/SoundRecorder.swift)

Related: [lifecycle](01-architecture-and-app-lifecycle.md), [settings](11-settings-and-localization.md), [classic events](15-classic-game-mode.md). [Back to index](README.md).
