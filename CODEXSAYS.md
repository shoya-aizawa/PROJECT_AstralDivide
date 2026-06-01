# Astral Divide Options Design / Implementation Handoff

This document is for the next agent working on the `Options` screen.

The current project state is not "greenfield UI work". A rendering foundation has already been built while fixing `MainMenuModule` (`MMM`) and `SaveDataSelector` (`SDS`). Any new `Options` implementation must respect that foundation, otherwise it will regress the cross-environment work that has already been done.

## 1. Current Direction

The display architecture is now intentionally hybrid.

- `HIGH`
  - Static-art-first mode.
  - Large title assets / AA / carefully composed layouts are allowed.
  - We preserve visual assets where possible.

- `MIDDLE / LOW`
  - Variable-width-first modes.
  - UI should adapt to actual `CONSOLE_COLS` / `CONSOLE_ROWS`.
  - Fixed tiny templates centered inside a larger console are no longer acceptable.

The key design decision:

- Do **not** treat `HIGH/MIDDLE/LOW` as three hardcoded screen canvases.
- Treat them as **density / layout presets**.

That means:

- `HIGH` may remain partly static.
- `MIDDLE/LOW` should prefer dynamic layout.
- Future screens should follow this model.

## 2. What Has Already Been Built

Two systems already reflect this direction:

### MainMenuModule (`MMM`)

- `HIGH`
  - still uses static template rendering.
- `MIDDLE/LOW`
  - now uses dynamic rendering driven by real console size.

Dynamic pieces already exist:

- outer frame
- centered title/subtitle
- menu box
- help box
- footer
- right-aligned footer text

Relevant file:

- `Src/Systems/Display/MainMenuModule.bat`

### SaveDataSelector (`SDS`)

- `HIGH`
  - still mostly static-template-based
- `MIDDLE`
  - now has dynamic frame / title / help / footer / slot-grid positioning
- `LOW`
  - currently left as static fallback on purpose

Relevant files:

- `Src/Systems/SaveSys/SaveDataSelector.bat`
- `Src/Systems/Display/Templates/StaticUIProfileSelector.bat`

## 3. Non-Negotiable Rules For Options

If you implement `Options`, follow these rules.

### Rule A: Do not restart from absolute coordinates everywhere

Bad:

- hand-writing dozens of fixed coordinates directly inside the screen code
- scattering `echo [row;colH` literals everywhere
- creating a totally separate coordinate philosophy from `MMM/SDS`

Good:

- define core layout values in `StaticUIProfileSelector.bat`
- keep screen-specific placement derived from anchors / frame dimensions
- allow profile-only tuning where possible

### Rule B: Do not add a new fixed tiny `MIDDLE` or `LOW` template unless absolutely necessary

This was the original failure mode.

Example of what we do **not** want:

- `OptionsDisplay_MIDDLE.txt` designed for 90x35
- then simply centered inside a 160x45 or similar environment

That creates a technically "working" UI that looks spatially wrong.

### Rule C: Separate art from interaction

For `Options`, think in layers:

1. Frame / stage layer
2. Safe interaction area
3. Widgets inside the safe area

`Options` is primarily an interaction screen, not an art screen.
That means it should behave more like `SDS` than like a large AA splash.

### Rule D: Preserve font tolerance

The project must continue to work with at least:

- `MSGothic`
- `Consolas`
- `SimSun`

Do not assume one exact glyph width appearance beyond what the current console environment gives.

### Rule E: Do not introduce new PowerShell direct-attach dependencies

There is already a known font-timing / attachment sensitivity, especially around `Consolas`.
Do not "improve" `Options` by inserting new PowerShell-based drawing tricks unless strictly necessary.

## 4. Preferred Structure For Options

### Recommended screen structure

For `MIDDLE/LOW`, build `Options` dynamically with this shape:

1. Outer frame
2. Title area
3. Main options panel in center
4. Context/help line or help box
5. Footer

### Recommended content structure

Keep the first `Options` pass simple.

Suggested categories:

- Display
- Audio
- Language
- Save Data Path / Mode
- Back

Within each category, prefer a vertical list with:

- label
- current value
- selection highlight

If submenus are needed, open them as centered child panels rather than rebuilding the whole screen.

## 5. Strong Recommendation On Scope

Do **not** design the final, giant, fully featured options system in one pass.

Instead:

### Phase 1

Build a stable shell:

- title
- selectable list
- current values
- back navigation
- one or two editable settings

### Phase 2

Add richer editing behaviors:

- left/right value cycling
- confirmation dialogs
- perhaps category pages

### Phase 3

Integrate with eventual full settings coverage

This keeps the screen aligned with the current rendering work, rather than turning `Options` into a parallel architecture project.

## 6. Technical Integration Guidance

### Use `StaticUIProfileSelector.bat`

If `Options` needs positioning values, add them there.

Examples of acceptable exported values:

- `OPT_USE_DYNAMIC`
- `OPT_FRAME_LEFT`
- `OPT_FRAME_TOP`
- `OPT_FRAME_RIGHT`
- `OPT_FRAME_BOTTOM`
- `OPT_TITLE_ROW`
- `OPT_LIST_LEFT`
- `OPT_LIST_TOP`
- `OPT_LIST_WIDTH`
- `OPT_HELP_ROW`
- `OPT_FOOTER_ROW_1`
- `OPT_FOOTER_ROW_2`

### Match existing patterns

Reuse the same style already established in:

- `MainMenuModule.bat`
- `SaveDataSelector.bat`

In particular:

- `Render_*_Dynamic`
- `Draw_Box`
- `Print_Centered`
- `Print_Right`
- dynamic footer alignment

If code duplication is unavoidable for now, keep it small and intentional.
Do not invent a completely different micro-framework just for `Options`.

### Anchor mindset

Even if `Options` is mostly dynamic, think in terms of:

- frame bounds
- inner box bounds
- rows/columns derived from those bounds

That keeps future refactoring possible.

## 7. Known Pitfalls

The following mistakes have already caused real bugs in this project.
Avoid them.

### Batch expansion pitfalls

Inside `if (...)` blocks:

- `%VAR%` may expand too early
- values assigned earlier in the same block may still appear empty

Safer approaches:

- `call set /a ... %%VAR%% ...`
- or break calculations into separate statements outside problematic block structure

### `call if` is dangerous here

This caused `'if' is not recognized as an internal or external command`.

Do not use:

- `call if ...`

Prefer:

- safe `for /f` helper expressions
- or simpler non-`call` control flow

### Unescaped special characters in block echoes

Inside batch blocks:

- `|`
- `(`
- `)`

must be handled carefully.

Examples:

- vertical box lines needed `^|`
- literal `(c)` needed `^(c^)`

If you see errors like:

- `was unexpected at this time`
- `The syntax of the command is incorrect`

check literal punctuation inside `echo` within blocks first.

## 8. Quality-Specific Expectations

### HIGH

Goal:

- premium visual composition
- can remain more static
- should still not regress current working appearance

### MIDDLE

Goal:

- fully usable on notebook-like environments
- should visibly use the full screen better than old centered-mini-template behavior

### LOW

Goal:

- reliable fallback
- may intentionally be simpler
- does not need to match `HIGH` aesthetics one-for-one

## 9. What Success Looks Like

An acceptable first `Options` implementation should satisfy all of these:

- launches from `MMM` without layout corruption
- works in `HIGH`
- works in forced `MIDDLE`
- does not create a tiny centered static panel on larger notebook-class consoles
- does not regress known font behavior
- can be tuned mostly through exported layout values

## 10. Recommendation To The Next Agent

If you are starting `Options` from scratch, do this in order:

1. Decide whether `HIGH` is static/hybrid and `MIDDLE/LOW` are dynamic
2. Add only the minimum `OPT_*` variables to `StaticUIProfileSelector.bat`
3. Build a dynamic `Options` shell first
4. Add list navigation
5. Add value editing
6. Add confirmation boxes last

Do not begin with visual perfection.
Begin with structural compatibility with the rendering foundation already established.

## 11. Summary In One Sentence

Build `Options` as a new screen on top of the current hybrid rendering architecture, not as a disconnected one-off screen with fresh hardcoded coordinates.

## 12. Current Completion Status

`Settings Phase 1` is now considered complete.

What is already working:

- Transition from `MMM` to `Settings`
- Transition back from `Settings` to `MMM`
- Dynamic `Settings` layout in current implementation
- `W / S / A / D / F / Q` input handling
- `Confirm & Save`
- `Cancel & Back`
- `user_config.env` persistence for current Phase 1 items
- `Sound Effects` playback restored
- Differential redraw for item rows
- Footer / help box / title rendering stabilized

Known accepted limitations at the end of Phase 1:

- `Settings` is dynamic even in `HIGH`
- marquee / flowing help text is **not** implemented
- `Settings` still uses `choice`-based blocking input
- long help text is truncated to fit the help area

## 13. Important Next-Session Boundary

Do **not** casually continue from here by mixing unrelated work.

The next session should treat the current state as:

- `Settings Phase 1 = complete`
- next work = either `Settings Phase 1.5` or `Polling Input Phase`

These are different tracks and should not be blurred together.

### Track A: Settings Phase 1.5

Recommended additions that fit the current architecture well:

- `BGM Volume`
- `SE Volume`
- `Tutorial`
- `Auto Save`

Potentially later in the same family:

- `Credits`
- `BGM Soundtrack`

These should extend the existing table-driven structure with richer option kinds.

Recommended option kinds:

- `toggle`
- `range`
- `action`

Recommended future metadata:

- `OPT_KIND_n`
- `OPT_MIN_n`
- `OPT_MAX_n`
- `OPT_STEP_n`
- `OPT_VALUE_n`
- `OPT_ACTION_n`
- `OPT_DESC_n`
- `OPT_VISIBLE_n`

### Track B: Polling Input Phase

This is the correct phase for:

- marquee help text
- animations while idle
- non-blocking UI updates
- future name-entry UI reuse

Important:

- The current `choice`-based input loop cannot animate help text while waiting for input.
- A right-to-left flowing help description requires non-blocking polling input.
- Therefore marquee should **not** be hacked into the current blocking `choice` loop.

If marquee is implemented in the future, it should be done only after introducing a polling-based input loop for `Settings`.

## 14. Explicit Defer List

The following items should be treated as separate later work, not immediate next-step work inside the current session:

- `Text Speed`
- anything that directly touches `RenderControl`
- anything that directly touches `RenderMarkup`

Reason:

- these reach beyond simple settings persistence
- they affect runtime rendering behavior and need a separate focused session

## 15. Recommended Next Session Order

Recommended order for the next agent:

1. Confirm `Settings Phase 1` is stable
2. Decide whether next work is `Phase 1.5` or `Polling Input Phase`
3. If choosing `Phase 1.5`, implement:
   - `SE Volume`
   - `BGM Volume`
   - `Tutorial`
   - `Auto Save`
4. If choosing `Polling Input Phase`, first replace blocking `choice` input with safe non-blocking polling
5. Only after polling is in place, implement marquee help text
