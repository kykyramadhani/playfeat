# Prompt template: Planet 2 (K2-332 b) art from Figma

Copy everything below the line into Claude Code. Paste a Figma link after
each item you have art for. Leave the rest empty; Claude will skip them and
keep the current stand-in art. One link can cover several items if they sit
in the same frame. Just say which ones.

---

Implement the Planet 2 (K2-332 b) art from the Figma links below.

**Read first, in this order:**
1. `CLAUDE.md` and the `new-screen` and `clean-code` skills.
2. `docs/systems/06-kitchen-items-and-interactions.md`,
   `docs/systems/08-planets-and-progression.md` and
   `docs/systems/16-rendering-assets-and-layout.md`.
   These docs are partly out of date (for example, they still say Planet 2
   doesn't exist). Where a doc and the code disagree, the code is right.
3. The code that holds the stand-ins, all marked `ponytail`:
   - `PlayFeat/Data/Models/Level/Planet/K2332b.swift`: the planet, its
     kitchen, backdrop layers and Buffet.
   - `PlayFeat/Data/Models/KitchenArt.swift`: the item → image names, where
     Planet 2 food borrows Planet 1 pictures, and the pot uses the shop's.
   - `PlayFeat/Scenes/KitchenScene/KitchenLayout.swift`: the pot's stand-in
     spot on the counter.
   - `PlayFeat/Game/Level/AssemblyStation.swift`: the bowl and cookie plate.

**How to work:**
- Make a branch `feature/planet-two-art` from an up-to-date `main` before
  editing.
- For each link, load the `figma:figma-design-to-code` skill, read the node
  with the Figma tools, and download its images. If the Figma tools say they
  need sign-in, stop and tell me to run `/mcp`.
- Import each picture as an imageset named for its role in UpperCamelCase,
  matching Planet 1's names (`Pepper` → `Coral`, `FlatbreadRaw` →
  `NoodlesRaw`). Lookups are case-sensitive.
- Swap the stand-in name in `KitchenArt` (or wherever it's used) for the new
  one, delete its `ponytail` note, and add the name to `ArtAssetTests`.
- Positions and sizes come from the Figma frame, in the 1366 × 1024 art
  space, through `KitchenLayout`. Never guess a number; ask if a frame is
  missing one.
- Any new on-screen text goes in `Localizable.xcstrings` with Indonesian,
  and in `LocalizationTests`. Edit that file as text: Xcode re-sorts it.
- Moving art respects Reduce Motion. Decorative art is
  `accessibilityHidden(true)`.

**Check before you finish:**
- Run all unit tests (⌘U, or `xcodebuild test … -only-testing:PlayFeatTests`).
  Only the 9 known `HandCursor` failures are allowed.
- Show me each new picture in place. The simulator draws the kitchen grey,
  so render it with a temporary `ImageRenderer` test, then delete the test.
- Tell me which items still use stand-in art.
- Don't commit until I ask.

**The art** (paste links; leave empty to skip):

*Food in bubbles and in the hand*
- Raw noodles (`rawNoodles`, now borrows raw flatbread):
- Boiled noodles (`boiledNoodles`, now baked flatbread):
- Mushy noodles, overcooked (`mushyNoodles`, now burnt flatbread):
- Coral (`coral`, now the shop's `CoralLettuce`):
- Urchin (`urchin`, now the glowy mushroom):
- Raw clam (`rawClam`, now the tentacle):
- Grilled clam (`grilledClam`, now the premium tentacle):
- Burnt clam (`burntClam`, now burnt flatbread):
- Sea cookie (`seaCookie`, now a coin):
- Starfish sugar (`starfishSugar`, now the fuel gauge star):

*Finished dishes (order sheets, recipe book, served)*
- Coral noodles (`coralNoodles`, now pepper flatbread):
- Urchin noodles (`urchinNoodles`, now mushroom flatbread):
- Clam noodles (`clamNoodles`, now premium baked flatbread):
- Star cookie (`starCookie`, now the level star):

*Toppings as drawn once placed on the bowl or cookie plate (if different)*
- Placed versions:

*Premium looks (after a shop or marathon upgrade)*
- Premium ingredients and dishes:

*Kitchen tools and stations*
- Pot, on the counter (now the shop's `CookingPot`):
- Pot position on the counter (frame with the counter layout):
- Bowl (main station):
- Cookie plate (dessert station):
- Planet 2 truck wall, counter or chains (if not the Planet 1 truck):

*Planet screens*
- Separate bubble layer for the sea backdrop (now painted into the water):
- Planet 2 landed spaceship and fuel gauge (if not Planet 1's):
- New planet popup with K2-332 b's name:

*Planet 2 pages and cards*
- "New Tools" / "New Menu" introduction popups for 2-1 to 2-6:
- Recipe book pages for the Planet 2 dishes and ingredients:
- Shop ingredient upgrade cards:
- Marathon ingredient cards:

*Anything else*
-
