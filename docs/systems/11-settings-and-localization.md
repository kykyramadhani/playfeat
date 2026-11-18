# Settings and localization

## Settings are persisted values with live consumers

`SettingsView` is a popup, not a separate `AppScreen`. It uses `@AppStorage` for persistent values. Audio changes are also pushed into the shared `AudioManager` immediately. Hand mode and grip are read directly from UserDefaults by the camera-processing pipeline, so those consumers do not need a settings-view reference.

| Setting | Storage key | Default | Consumer |
|---|---|---|---|
| Music volume | `settings.musicVolume` | 0.45 | `AudioManager.musicVolume` |
| Effect volume | `settings.sfxVolume` | 1.0 | `AudioManager.effectsVolume` |
| Language | `settings.language` | `english` | `AppLocalization` and root locale |
| One-hand mode | `oneHandModeEnabled` | false | `HandInputModeSetting` |
| Preferred hand | `preferredHand` | `right` | `OneHandMode` / calibration |
| Pickup gesture | `gripGesture` | `pinch` | `GripGesture.stored`, frame classifier/detector |

Language raw values are `english` and `indonesia`; their resource/locale codes are `en` and `id`. Do not replace the stored enum names with language codes without a migration.

## Volume controls

The custom `VolumeSlider` maps touch position to a clamped 0–1 value while keeping its thumb inside the track. Settings writes the persisted double and applies a float to the audio object continuously. The effects slider plays a UI click when editing ends as a preview of the new level.

The audio manager reads saved volumes once during initialization, provided the keys actually exist. Missing keys preserve defaults. Its volume fields are observation-ignored because their clamping setters assign to themselves; observing those setters caused recursive observation behavior previously. Settings observes its own stored values instead.

## Hand controls

One-hand mode reveals a left/right selector and changes which body wrist must be present during calibration. The frame processor reads the current mode each frame. Changing the preferred hand affects body filtering, not merely the cursor art.

The pickup selector chooses Pinch or F-Pinch. `GripGesture.stored` falls back to Pinch if a saved string is unsupported. Changing the gesture causes `HandIdentityTracker` to replace each hand's detector, discarding evidence gathered for the old gesture.

The current Settings UI does not expose frame rate, smoothing, thresholds, or an app-specific Reduce Motion toggle. Those tuning values live in code. The removed flying-star implementation's motion check is no longer part of the current report.

## Language-switch sequence

A language change needs more than writing a key, because `Bundle.main` normally resolves a localization independently of this custom picker.

1. `SettingsView` calls `AppLocalization.apply(nextLanguage)` first.
2. That function changes `Bundle.main` to a forwarding subclass once and points its localized lookups to the selected `.lproj` bundle.
3. Settings then writes the new `@AppStorage` language.
4. `ContentView` observes the change, applies the locale and uses `.id(language)` to rebuild already-resolved UI.
5. `PlayFeatApp.init` reapplies the stored language before the first interface text is drawn on a later launch.

The order prevents a rebuild against the previous language. The forwarding bundle falls back to base localization when the requested compiled resource bundle is missing.

## Localized text conventions

`Localizable.xcstrings` holds the catalog. `Text("literal")`, `LocalizedStringResource`, and `AppLocalization.string` cover different call sites. A computed plain `String` passed to `Text` is generally displayed as that value, so computed calibration/tutorial copy goes through explicit localization.

Use `Text(verbatim:)` intentionally for proper names or numeric/nontranslated display text. `Info.plist` declares `en` and `id`. Font registration is separate from translation; the app uses Atkinson Hyperlegible through shared font helpers.

Changing the root view identity rebuilds screen subtrees. If expanding live language switching during an active kitchen, check the lifetime of local `@State` days, countdown tasks and camera setup rather than assuming the switch is presentation-only.

## Accessibility-related behavior

The app supports one-hand selection, explicit accessibility labels/values on many counters and controls, modal traits on reports, and a rotate-to-landscape prompt. Custom-drawn controls need accessibility semantics as well as visuals; implementing a drag gesture does not automatically provide every slider accessibility action.

System preferences are separate from app settings. If a future animation reads `@Environment(\.accessibilityReduceMotion)`, that value comes from the operating system unless explicitly overridden in the view hierarchy. There is currently no flying-star behavior to debug through that setting.

## Extending settings or languages

Add a shared key constant with its owner, define a default compatible with existing installs, and connect both persistence and the live consumer. For a new language, update `AppLanguage`, the string catalog, compiled localizations and tests. Avoid adding a setting that only changes a UI toggle without changing its actual runtime owner.

## Source map and tests

- [Settings popup and controls](../../PlayFeat/UI/Overlays/SettingsView.swift)
- [Language enum](../../PlayFeat/Shared/Localization/AppLanguage.swift), [bundle redirection](../../PlayFeat/Shared/Localization/AppLocalization.swift)
- [Root language rebuild](../../PlayFeat/UI/Screens/ContentView.swift), [declared localizations](../../PlayFeat/Info.plist)
- [String catalog](../../Localizable.xcstrings)
- [Hand setting factory](../../PlayFeat/Vision/InputModes/HandInputModeSetting.swift), [grip setting](../../PlayFeat/Vision/Gestures/GripGesture.swift)
- [Localization tests](../../Testing/PlayFeatTests/Shared/Localization/LocalizationTests.swift), [grip tests](../../Testing/PlayFeatTests/Vision/Gestures/GripGestureTests.swift)

Related: [audio](12-music-and-sound.md), [calibration](04-calibration-and-player-selection.md), [storage](14-storage-and-inventory.md). [Back to index](README.md).
