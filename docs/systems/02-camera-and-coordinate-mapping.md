# Camera and coordinate mapping

## Responsibilities

`CameraManager` handles permission checks, camera discovery, format ranking and zoom calculations. `CameraSession` owns the `AVCaptureSession`, its video output and queues. `CameraPreviewView` displays that session through an `AVCaptureVideoPreviewLayer`. `CameraViewMapping` converts Vision's positions into the same displayed image geometry.

One capture session is shared by the preview and Vision. Removing the preview after calibration does not remove the session used by hand tracking.

## Startup sequence

1. A screen calls `HandPoseManager.start()`.
2. `CameraSession.start` asks its permission helper for authorization and reports the resulting status on the main thread.
3. If authorized, it configures the capture session once, then starts it on the session queue.
4. Each delivered sample buffer is converted to a pixel buffer and forwarded through `onFrame` on the video queue.
5. `HandPoseManager` processes that buffer and publishes the finished output to the main thread.

A denied or restricted permission produces no frames; the interface shows `CameraPermissionDeniedOverlay`. Repeated calls to start are intended to be harmless. Reconfiguration values should be set before the first start: `isConfigured` prevents rebuilding the session on every screen appearance.

## Current capture settings

| Setting | Implementation |
|---|---|
| Camera position | Front |
| Capture width candidates | 640 through 1920 pixels |
| Format eligibility | A supported frame-rate range whose maximum is at least 30 |
| Ranking | Horizontal field of view, then calculated vertical field of view, then width |
| Frame duration | Minimum duration `1/30` when the selected format supports 30 |
| Fallback preset | `hd1280x720`, before selecting an explicit device format |
| Pixel format | 32-bit BGRA |
| Late output frames | Discarded |
| iPad/device zoom multiplier | 1.75 times the device's widest allowed zoom |
| Mac zoom multiplier | 1.0 |
| Preview gravity | `resizeAspectFill` |
| Center Stage | Disabled cooperatively when configured to do so |

The minimum frame duration caps maximum capture rate on that configured path. It does not guarantee exactly 30 processed hand updates per second. The code does not set a matching maximum frame duration. Inference cost, exposure and hardware behavior still affect delivered/processed frames.

Ranking prioritizes view coverage and resolution, not minimum recognition latency. Raising frame rate requires a supported format; changing a number alone cannot make an unsupported camera mode work.

## Three coordinate spaces

| Space | Typical value | Origin and direction |
|---|---|---|
| Vision | A normalized point such as `(0.25, 0.75)` | Bottom-left, y increases upward |
| SwiftUI / view | Points within the actual view bounds | Top-left, y increases downward |
| SpriteKit scene | Scene points | Normally bottom-left, y increases upward |

`HandPoseManager.cursor(for:in:)`, joint mapping and body mapping return **view** points. Scenes must pass them through `convertPoint(fromView:)`. Assigning the view point directly to a node makes vertical movement incorrect.

`CameraViewMapping` first transforms normalized y to `1 - y`. For aspect fill, it calculates:

```text
scale = max(viewWidth / bufferWidth, viewHeight / bufferHeight)
displayedSize = bufferSize × scale
origin = (viewSize - displayedSize) / 2
viewPoint = origin + flippedNormalizedPoint × displayedSize
```

Some origin values are negative because aspect fill crops the camera image. Aspect fit uses the smaller scale and may produce positive letterbox margins. A zero/unknown buffer size, or stretch gravity, uses a simple normalized-to-view stretch.

The input buffer dimensions are measured after capture rotation. The mapping uses those dimensions, rather than assuming that all cameras are 4:3.

## Mirroring and rotation

The capture output is mirrored before Vision reads it. The preview is also mirrored. `CameraViewMapping` therefore does not apply another horizontal flip.

`CameraSession` attaches to the preview layer and uses a rotation coordinator. It applies the **preview angle to both connections** so displayed pixels and recognized joints agree. An angle is rejected if any existing connection cannot support it; rotating only one side would break alignment.

This pipeline also explains why handedness artwork and anatomical labels need care. The body reader swaps Vision's wrist labels for the mirrored input. Hand cursor chirality has its own artwork convention; see the hand-tracking guide.

## Performance investigation

A smooth 60-FPS SpriteKit scene can repeatedly draw a 30-FPS or slower tracking result. Measure capture delivery, processing duration, main-thread publication and rendering separately before attributing latency to the drawing node.

Late-frame dropping prevents a long queue of stale capture frames, but expensive processing still reduces fresh-result frequency. Lowering maximum capture width can be an experiment; it may also make small/faraway hands harder to recognize. Source inspection alone does not establish which device is faster.

Do not change `automaticallyConfiguresApplicationAudioSession = false` casually: the camera is video-only, and changing the shared audio session on camera start/stop can interrupt game music.

## Source map and tests

- [Permissions, formats and zoom](../../PlayFeat/Camera/CameraManager.swift)
- [Capture lifecycle and queues](../../PlayFeat/Camera/CameraSession.swift)
- [Preview layer](../../PlayFeat/Camera/CameraPreviewView.swift)
- [Mapping math](../../PlayFeat/Vision/CameraViewMapping.swift)
- [Format ranking tests](../../Testing/PlayFeatTests/Camera/FormatRankingTests.swift)
- [Zoom tests](../../Testing/PlayFeatTests/Camera/ZoomClampTests.swift)
- [Mapping tests](../../Testing/PlayFeatTests/Vision/HandPoseMappingTests.swift)

Related: [hand tracking](03-hand-tracking-and-gestures.md), [rendering](16-rendering-assets-and-layout.md). [Back to index](README.md).
