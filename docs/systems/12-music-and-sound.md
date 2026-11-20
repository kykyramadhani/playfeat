# Music and sound

## Ownership

`PlayFeatApp` owns one `AudioManager`. SwiftUI reads it from the environment;
SpriteKit scenes receive `SoundPlaying`. Classic rule events still go through
`GameAudio`. `KitchenSoundscape` translates kitchen customer and cooking changes
into cues without replaying them every frame. Tests use `SoundRecorder`.

`EffectPlayer` decodes effect resources with `AVAudioFile`, caches PCM buffers,
and plays overlapping voices through `AVAudioEngine`. Each voice has its own
`AVAudioUnitTimePitch`; every playback chooses a random pitch from -1 to +2
semitones (-100 to +200 cents). Speed and pitch are independent. A loop chooses
its pitch when it starts. Music uses its own streaming `AVAudioPlayer` and does
not inherit random effect pitch. At most 16 one-shot voices can overlap.

## Resources and tracks

Selected supplied assets live in `PlayFeat/Resources/Sounds/AstroFeast`.
The shared resource lookup accepts WAV, MP3, M4A and CAF. Existing `bubble_grab`
and `bubble_put` are identical to the supplied versions and are not duplicated.
Neither the alternate `music buffet` nor the deleted `dry-fart` is bundled.

| Context | Track |
|---|---|
| Galaxy after START, planet board, and Buffet home | `bgm_menu` |
| Story kitchens on both planets | `bgm_story` |
| Buffet gameplay | `music_buffet` (retained underscore filename) |
| Legacy classic gameplay | `gameplay_getcooking` |

`ContentView` starts menu music when the launch screen closes and the galaxy
map appears. Entering a story level or starting a Buffet run fades out the
menu track immediately. The gameplay track starts after the countdown.
Returning to the menu starts its track again, and outgoing gameplay screens
stop only their own track during teardown.

Buffet's music rate rises with customer-arrival pressure, capped at 1.5x.
Story music stays at normal speed. Re-entering the same playing track does not
restart it. Music and effects retain independent volume controls in Settings.
The effect slider also updates existing loop and one-shot voices immediately.

## Effects and event timing

`SoundEffect` maps semantic cases to supplied filenames. The shared
`ClickButton` uses `sfx_button` with randomized pitch; callers can override the
sound or pass nil. Back/close controls use `sfx_back`. Card selection suppresses
the generic click and uses `sfx_card_picked` instead.

| Event | Resource / behavior |
|---|---|
| Successful grab/catch | `bubble_grab` |
| Intentional release / bubble pop | Existing `bubble_put` |
| Accepted tool/vessel placement | `sfx_place` |
| Regular / angry arrival | `sfx_customer_arrive` / `sfx_angry_arrive` |
| Correct serve / refusal / positive tip | `sfx_serve_ok` / `sfx_wrong_dish` / `sfx_tip` |
| Customer first enters red patience | `sfx_patience_red`, once per customer |
| Customer gives up | `sfx_customer_leaves`, story and Buffet |
| Grill / pot is cooking | Quiet keyed `sfx_bake_loop` / `sfx_boiling_pot` loop |
| Cooking becomes ready / ruined | `sfx_bake_ready` / `sfx_bake_burnt`, once per transition |
| Tool's food is overcooking | Keyed `sfx_bake_warning` loop |
| Final 10 seconds | Keyed `sfx_time_warning`, story day or Buffet round |
| Story clock reaches zero | `sfx_day_end`, **5x speed**; remaining customers can still be served |
| Story level report appears | `sfx_round_over` (`storyReport`) |
| Results stars / zero stars | Corresponding `sfx_star_1`, `sfx_star_2`, `sfx_star_3` / `sfx_no_star` |
| New star reaches fuel gauge | `sfx_gas_collected`, fitted to the 0.25-second gauge-fill animation |
| Introduction / planet or station unlock | `sfx_hint` / `sfx_unlock` |
| Buffet upgrade break / pick / actual purchase | `sfx_card_reveal` / `sfx_card_picked` / `sfx_coin_spent_buffet` |
| Buffet final report | `sfx_run_over`, with the temporary fallback below |
| New Buffet personal best | `sfx_best_score`; records are points per planet, separate from classic dish counts |

**Asset handoff note:** `sfx_round_over` is for STORY reports only. The distinct
Buffet `sfx_run_over` file has not been supplied. `SoundEffect.runOver` looks for
that filename first, then temporarily falls back to `lose_heart`. Add the new
file to the app resources to replace the fallback; the TODO is beside the enum
case. Do not redirect Buffet to the story report file.

The angry-arrival clip runs at **2x speed**. Gas playback rate is calculated
from the decoded clip duration; changing the source clip still fits the same
animation. All three speed adjustments preserve the randomized pitch range.

Cooking cues use each tool's actual `CookTiming`, including Planet 2 and faster
Buffet tools. Taking ready food off and putting it back does not play another
ready ding. New bubbles entering the screen remain silent. There are no new
invented files for release-whoosh, missed-item, topping or stage-up sounds.

## Pause and background

Kitchen loops stop when the day pauses, a Buffet round ends, the player leaves,
or the app backgrounds. Backgrounding stops volatile effect voices; returning
allows effects again. Music fades/pauses and resumes separately.

`sfx_hand_found` plays after the initial seat check.

## Verification

- `EffectPlaybackTests`: resource decoding (including MP3), exact rate
  overrides, fuel duration, report separation, random pitch bounds, voice cap,
  simultaneous loop idempotence and graph cleanup.
- `KitchenSoundscapeTests`: arrival/patience/loss deduplication, cooking
  transitions, both tool loops and pause cleanup.
- `MarathonRecordTests`: independent per-planet records and new-best detection.
- Existing `GameAudioTests` cover classic gameplay audio.

A real-camera playtest is still needed to tune tracking tolerance and audition
booth-speaker balance. Simulator tests do not establish that a player can hold
the calibration pose reliably in exhibition lighting.
