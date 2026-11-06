# PlayFeat

A hand-tracking cooking game made with and for the community at **PUSPADI** (Pusat Pemberdayaan Penyandang Disabilitas), Bali — Apple Developer Academy Challenge 5 & Final Challenge.

The front camera fills the screen and Vision tracks the player's hands and upper body. Players **pinch** floating ingredient bubbles, drag them onto a plate to match the recipe, then carry the finished dish to the bell. No touch input is needed during play.

## How to play

1. A recipe card shows the dish and its ingredients; the dish clock starts.
2. Pinch (thumb + index finger) an ingredient bubble, drag it, and open your fingers to drop it on the plate. Wrong ingredients are decoys.
3. Hold a hand over the reset button to empty the plate.
4. When the plate matches the recipe, the bell rings on the left or right — carry the plate to that side.
5. Each served dish adds to your score, and leftover clock time becomes a speed bonus. Lose all lives and the run ends.

## Platforms

| Platform | Status |
|---|---|
| iPadOS | Published, the only shipping target |
| iOS (iPhone) | Planned |
| macOS | Planned |

- Minimum OS: iOS / iPadOS 17.0
- Languages: English, Indonesian

## Tech

SwiftUI · SpriteKit · Vision (hand + body pose) · AVFoundation · SwiftData · Game Center (optional leaderboard) · Accessibility (Atkinson Hyperlegible font, one-hand mode).

No third-party dependencies.

## Run

1. Open `PlayFeat.xcodeproj` in Xcode.
2. Select an iPad (a real device is recommended: the simulator has no camera).
3. Build and run, and allow camera access.

## Project layout

```
PlayFeat/
  App/       app entry, screen routing
  Camera/    AVFoundation capture
  Vision/    hand/body tracking, pinch & hover gestures
  Game/      state, recipes, clock, difficulty
  Data/      models and storage
  Audio/     music and sound effects
  UI/        screens and overlays
Testing/     unit and UI tests
docs/        design notes
```
