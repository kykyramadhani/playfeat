# Rendering, assets and layout

## Layer ownership

In the kitchen, SwiftUI draws the illustrated background, tools, customers and order sheets. A transparent SpriteKit scene draws bubbles, food, cursor hands, cooking gauges and target feedback. SwiftUI places HUD, calibration, introductions, pause and reports above the scene.

In classic mode the backmost layer is the live camera preview, followed by `GameScene` and the classic HUD. Both scenes use transparent backgrounds and `SpriteView` options allowing transparency and ignoring sibling order.

Ignoring sibling order makes explicit z-order important. Do not rely on the order of `addChild` calls to resolve overlapping equal-depth content.

## Two layout systems with different purposes

The current design canvas is **1366 × 1024**, from `TutorialView.pageSize` and `KitchenLayout.artSize`.

`designScaled()` lays SwiftUI controls out in a virtual canvas and scales the result down to fit, never above 1×. `DesignCanvas.scale` uses the smaller width/height fit and accounts for orientation. It protects fixed-size typography and popup designs on smaller windows.

`KitchenLayout`, by contrast, uses **aspect fill** for the illustrated kitchen. Its scale is the larger width/height ratio, so the kitchen covers the window and overflow is cropped. Art coordinates are translated with centered crop offsets. It exposes conversions for view points, scene points, rectangles and lengths.

These are deliberately not interchangeable. A kitchen station hit rectangle must use `KitchenLayout`; a popup's font/padding usually uses the design canvas. Camera overlays need `CameraViewMapping`, a third transformation based on actual camera pixels and preview gravity.

## SpriteKit coordinates and sizing

Kitchen art is authored in top-left/y-down coordinates. `KitchenLayout.scenePoint` maps through the view transformation and flips y into SpriteKit coordinates. Its rectangle conversion transforms the art rectangle's bottom-left corner and scales its size.

`GameBoardView` and the kitchen scene layer set scene size from actual `GeometryReader` bounds, with scene scale mode `resizeFill`. Camera and SpriteKit surfaces remain outside inflated SwiftUI design canvases to avoid rendering unnecessarily large framebuffers. Classic board metrics apply `DesignCanvas.scale` explicitly where needed.

The current cursor size is `bubbleRadius × 2.5`. Kitchen bubble radius is 70 art points scaled by kitchen layout. Texture replacement can therefore change apparent hand/food alignment without changing tracking coordinates.

## Node presentation and z-order

| Context | Current significant depths |
|---|---|
| Kitchen | Held food 0, target glows 1, placed/base food around 2, grill gauges 3, hand cursors 60 |
| Classic | Hand cursors 60, held ingredients/plate 100 |
| SwiftUI reports | Added above kitchen content with view z-index 200 |

Child nodes also have their own local depths—for example, a bubble shell sits above its food sprite. Parent and child ordering must be considered together. The classic comment "held food above the hand" does not describe the kitchen's current held depth.

Drop glows use cached colored silhouettes plus the original tool image, spread over several halo sizes. This preserves the drawing instead of multiplying a colored tint into near-black art. Refusal uses a red silhouette and shake. Customer serving zones remain invisible.

## Artwork lookup and trimming

Asset lookup names are case-sensitive imageset names, not arbitrary exported PNG names. `KitchenArt` and classic `GameArt`/`Ingredient` provide the mapping. Renaming an imageset requires updating its callers and asset tests.

`TrimmedArt` scans a downsampled alpha channel, finds opaque bounds, adds a small margin and crops the original image. It caches both images and textures. This makes food exported with different transparent margins appear consistently sized without modifying the original files.

Whole-glass kitchen images bypass ordinary trimming/sizing so their mug matches the counter glass. Placed art can differ from carried art. Use `KitchenItemArt` for SwiftUI kitchen food; it shares the lookup/trimming behavior rather than duplicating name logic.

The hand cursor intentionally uses a fixed anchor and pinch point within its artwork. New open/pinch art should be aligned to the same coordinate convention, or those constants must be recalibrated. Current cursor chirality assignments and some comments differ; see the hand guide.

## Orientation, safe areas and text

`PhoneSafeSides` uses a hosting controller on phone layouts to keep full-bleed content out of left/right obstruction areas. Environment injection occurs inside that wrapper. `requiresLandscape()` overlays a rotate prompt when the window is taller than wide; it does not mean every scene is locked to one immutable physical orientation.

Atkinson regular/bold files are declared in `Info.plist`, with shared font helpers. Most new UI colors come from the asset catalog. Custom raised buttons, paper texture, title plaques and popup frames form a reusable visual vocabulary.

## Current animation boundary

Story-report stars spring/light up one by one and play a chime. Flying-star nodes, their geometry preference keys and the extra report gauge are removed. The fuel gauge on the planet board still displays derived saved progress.

The current SpriteView call sites do not enable the earlier temporary FPS counter. Add a diagnostic deliberately when measuring performance; do not assume an old screenshot or previous experiment describes the current configuration.

## Source map and tests

- [Kitchen coordinates](../../PlayFeat/Scenes/KitchenScene/KitchenLayout.swift), [canvas/safe-area helpers](../../PlayFeat/Shared/DesignScale.swift)
- [Kitchen background](../../PlayFeat/UI/Components/Kitchen/KitchenBackdrop.swift), [classic scene host](../../PlayFeat/UI/Components/GameBoardView.swift)
- [Texture trimming](../../PlayFeat/Shared/TrimmedArt.swift), [item art lookup](../../PlayFeat/Data/Models/KitchenArt.swift)
- [Bubble node](../../PlayFeat/Scenes/Nodes/KitchenBubbleNode.swift), [cursor node](../../PlayFeat/Scenes/Nodes/HandCursorNode.swift), [target effects](../../PlayFeat/Scenes/KitchenScene/DropTargets.swift)
- [Layout tests](../../Testing/PlayFeatTests/Scenes/KitchenScene/KitchenLayoutTests.swift), [item-look tests](../../Testing/PlayFeatTests/Scenes/KitchenScene/KitchenItemLookTests.swift), [asset tests](../../Testing/PlayFeatTests/Resources/ArtAssetTests.swift)

Related: [camera coordinates](02-camera-and-coordinate-mapping.md), [items](06-kitchen-items-and-interactions.md), [debugging](18-testing-and-debugging.md). [Back to index](README.md).
