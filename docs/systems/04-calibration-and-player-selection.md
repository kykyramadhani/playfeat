# Calibration and player selection

## Why a body is tracked as well as hands

Hand detection alone cannot decide which person in the room is playing. The app first chooses an upper-body candidate, associates hands with that body's wrists, and locks the chosen player after seat calibration. Calibration also establishes that the required hands fit on screen at a useful scale.

This is positional continuity, not face recognition or biometric identity. The lock follows a nearby torso location and shoulder span.

## Body candidates

`HumanBodyPoseManager` requires two reliable shoulders with a positive separation. A candidate also carries a head point (nose, falling back to an ear), optional hips and optional wrists. Shoulder midpoint is the chest position. Shoulder separation is the scale used for movement and wrist tolerances.

Body detection currently runs every third camera frame. When a body request returns no candidates, previous candidates can remain for up to `bodyGracePeriod = 0.6` seconds. The joint confidence threshold is `0.25`.

The source buffer is already mirrored. The body reader explicitly swaps Vision's wrist labels when filling its left/right wrist properties. One-hand mode depends on these corrected body wrist properties; it does not use which half of the screen a hand occupies.

## Before calibration: select someone inside the box

`SeatCalibrationView` supplies a zone to `HandPoseManager.setPlayerZone`. The zone contains a view-space rectangle, the view size and preview gravity. `PlayerSelector.Zone` maps each body's chest into that same view space and accepts a body whose chest is inside it.

The target rectangle is centered, with width 54% and height 42% of the calibration view. A candidate inside that zone is only a candidate for playing; it still has to satisfy the full seat-check pose.

## Passing the seat check

`BodyCandidate.isAligned` requires:

1. A usable head point.
2. Both shoulders and every required wrist inside the target rectangle.
3. All hands required by the input mode visible in the body candidate.
4. Shoulder span at least 25% of the target rectangle's width.

Hips are not required, even though some older explanatory comments mention fitting the torso down to the hips.

An independent 30-Hz timer evaluates alignment and feeds `HoverDetector`. A still player may stop generating changed observable body values; a timer keeps the dwell moving anyway. The default dwell is one second, with each frame's contribution capped at 0.25 seconds. Leaving the correct pose resets the dwell. The border shows progress and completion calls the owning screen's calibration callback.

The screen then asks `HandPoseManager.lockOntoPlayer()`. Introductions and a countdown can follow before actual kitchen play begins.

## After calibration: follow the same player

`PlayerSelector` retains an anchor containing chest and shoulder span. A later candidate must be within `anchor.span × followTolerance`, currently a tolerance of `0.5`, and the closest qualifying candidate wins. The anchor is updated as that player shifts position.

If nobody is close enough, selection returns nil instead of silently adopting a distant bystander. The existing anchor remains available for reacquisition. Leaving the gameplay screen releases the player and zone so a later calibration starts afresh.

Hands are filtered separately. A hand's own wrist must be near a permitted player wrist, within shoulder span times `wristMatchTolerance = 0.6`, and must not be closer to another body's wrist. The configured input mode and hand count limit the result. An established hand can also survive a stale body-wrist reading through the tracker's tighter continuation check.

## One-hand mode

`HandInputModeSetting` reads `oneHandModeEnabled` and `preferredHand` from UserDefaults each processed frame. Defaults are two-hand mode and preferred right hand.

- `TwoHandMode` requires both visible body wrists and allows two hands.
- `OneHandMode` requires only the selected anatomical wrist and allows one hand.

The seat-check instruction is also provided by the input mode. Complete left/right sentences are localized instead of inserting an English hand name into a fixed sentence.

## When calibration seems stuck

Check the sequence rather than just the green border: authorization → body candidates → player-zone selection → head/shoulders/wrists → minimum shoulder size → continuous dwell. Good hand joints are insufficient if the shoulders are not selected. A hand outside the small calibration frame can fail the pose even while it is visible in the camera feed.

For a simulator layout check, `-debugSkipSeatCheck YES` bypasses the kitchen seat check in Debug builds. It does not create body or hand observations. Use a real camera to validate player selection and left/right mode behavior.

## Source map and tests

- [Calibration view](../../PlayFeat/UI/Overlays/SeatCalibrationView.swift)
- [Player selector](../../PlayFeat/Vision/PlayerSelector.swift)
- [Body extraction and association](../../PlayFeat/Vision/HumanBodyPoseManager.swift)
- [Input-mode factory](../../PlayFeat/Vision/InputModes/HandInputModeSetting.swift)
- [Dwell detector](../../PlayFeat/Vision/Gestures/HoverDetector.swift)
- [Calibration tests](../../Testing/PlayFeatTests/Vision/SeatCalibrationTests.swift)
- [Player selector tests](../../Testing/PlayFeatTests/Vision/PlayerSelectorTests.swift)
- [Body match tests](../../Testing/PlayFeatTests/Vision/PlayerBodyMatchTests.swift)
- [Input-mode tests](../../Testing/PlayFeatTests/Vision/InputModes/HandInputModeTests.swift)

Related: [hand tracking](03-hand-tracking-and-gestures.md), [settings](11-settings-and-localization.md). [Back to index](README.md).
