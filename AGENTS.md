# AGENTS.md

## Project

**Street** is a Godot 4.7 portrait 2D mobile tycoon game.

- The repository root is the Godot project root.
- Runtime source lives under `srcs/`.
- `docs/` contains the confirmed product design, MVP scope, balance targets, and acceptance criteria.
- The current implementation includes the `srcs/main.tscn` bootstrap, GDScript screen switching in `Main`, `LoadingScreen`, the code-built `DayScreen`, JSON save loading, tap movement, target selection, a repeating customer loop, ordered mackerel preparation, matching-order serving, eating, payment collection, exit, the mackerel station Lv.2 upgrade, the second-seat purchase, and GUT coverage for this foundation.

Treat `docs/` as the source of truth for confirmed gameplay behavior. Do not infer behavior only from names or introduce features outside the documented MVP.

## Commands

```bash
# Confirm the local engine version
./godot --version

# Open the project in the editor
./godot --editor --path "$PWD"

# Refresh imports and validate scripts/resources
./godot --headless --editor --path "$PWD" --quit

# Run all GUT tests
./godot --headless -s --path "$PWD" addons/gut/gut_cmdln.gd \
  -gdir=res://tests -gexit

# Run one GUT test file
./godot --headless -s --path "$PWD" addons/gut/gut_cmdln.gd \
  -gtest=res://tests/test_example.gd -gexit
```

GUT is configured to discover project tests under `tests/`. Do not report a test pass when no tests were discovered. `gdlint` is not currently installed, so the Godot headless editor check is the available script validation command.
Manual helpers under `tests/manual/` are excluded from automated discovery.

## Architecture

- `srcs/main.tscn` is the existing bootstrap scene.
- `project.godot` autoloads `GameManager` and `SaveManager`.
- `Main` owns screen creation and replacement. Screens change `GameManager.state`, then emit the no-argument `screen_change_requested` signal; `Main` reads the state to choose the next screen.
- `LoadingScreen` reads `user://save.json`, applies it to `GameManager.state`, or creates the first-day default state when no save exists.
- `DayScreen` builds the gray Stage 01 map, tap-to-move input, player collision, fixed HUD, bounded drag camera, interaction selection, the mackerel station, and its Lv.2 purchase pad entirely from GDScript.
- `DayInteractionController` chooses one nearby target by explicit priority and then distance. `MackerelStation` owns only its local craft progress; orders, ingredient counts, preparation steps, and the player's carried item remain in `GameManager.state`.
- `DayCustomerManager` creates customers, assigns every unlocked seat, and creates a mackerel order after arrival. Customer, seat, and order records are authoritative in `GameManager.state`; node position and movement remain screen-local.
- While every unlocked seat is occupied, `DayCustomerManager` spawns at the tunable interval into three fixed queue positions. On exit or second-seat purchase it promotes FIFO heads before allowing a new customer to fill the queue.
- A finished plate keeps its customer ID. Only that customer can receive it; serving clears the player's carried item and advances the customer through eating to payment waiting.
- Each order captures the station's sale price when it is created: 6 mon at Lv.1 and 7 mon at Lv.2. Collecting that payment records the sale, starts customer exit, and releases the seat only after exit completes. `DayCustomerManager` then promotes the queue.
- The mackerel upgrade pad charges 12 mon after a one-second stay, cannot charge twice, and immediately changes the station duration from 3.2 to 3.0 seconds. Upgrade ownership and currency remain authoritative in `GameManager.state`.
- The second-seat pad charges 24 mon after a one-second stay. Only then does `DayScreen` install Seat 2, update collision and navigation, and let `DayCustomerManager` assign its next waiting customer.
- Daytime mackerel production is strict: accept one customer order, collect one mackerel at the ingredient box, collect one rice at the rice pot, then work at the mackerel station. Approaching the station without those steps must not craft anything.
- `GameManager` owns authoritative game-wide runtime state, including the current day, day phase, service time and timers, currency, inventory, unlocks, upgrades, and stage progression.
- Screens and gameplay systems must not keep competing copies of state owned by `GameManager`. Update shared state through explicit `GameManager` methods and signals.
- `SaveManager` serializes and restores the confirmed `GameManager` state at the save boundaries defined in `docs/`. Keep gameplay rules out of `SaveManager`.
- Feature-local behavior such as movement, customer flow, station interaction, animation, and rendering belongs in focused scripts under `srcs/`, not in the autoloads.
- Gameplay movement is touch-only. A tap sets a world destination and a drag moves the camera. Desktop testing uses mouse clicks and drags; do not add keyboard movement.

## Code-First Rules

- Implement gameplay logic, UI, node composition, and tuning data in `.gd` files first.
- Build runtime node and UI trees from GDScript.
- Do not create a new `.tscn` file without asking the user first. The existing `srcs/main.tscn` remains the bootstrap exception.
- Do not introduce an xlsx, JSON, or `.tres` game-database pipeline without approval. The approved exception is the single local save file at `user://save.json`.
- Until a different data pipeline is approved, keep catalog and balance values in typed GDScript constants, classes, or dictionaries.
- Asset files may remain in their native formats under `assets/`; the code-first rule applies to game structure and data, not imported art and audio.

## Workflow

- Inspect the relevant source, tests, `docs/`, and project configuration before editing.
- Prefer the smallest correct change that satisfies the documented acceptance criteria.
- Preserve the fixed MVP scope in `docs/07_mvp_scope.md`.
- When confirmed gameplay behavior changes, update every affected design document listed in the README change-management section.
- Keep temporary manual test helpers separate from canonical gameplay data.
- Never claim that a planned directory, test, screen, or system already exists.

## GDScript Notes

- Do not redeclare the same `var` name in one function scope.
- Treat `Could not preload resource script` as a likely parser or scope error in the most recently edited script.
- Keep long state machines explicit.
- When adding a new UI state, update the state definition, input dispatch, state-specific input handling, visibility rules, refresh/render logic, and tests together.
- Use typed variables, parameters, return values, and signals for shared gameplay state.

## Testing

- Run the Godot headless editor check after changing `.gd` files or resources.
- Add focused GUT coverage for gameplay behavior once the project test structure is introduced.
- After every Godot or GUT run, check for `SCRIPT ERROR`, `Parser Error`, `Could not preload resource script`, `[Failed]`, and zero-test discovery.
- Report resource leak warnings separately from test failures.
