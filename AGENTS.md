# AGENTS.md

## Project

**Street** is a Godot 4.7 portrait 2D mobile tycoon game.

- The repository root is the Godot project root.
- Runtime source lives under `srcs/`.
- `docs/` contains the confirmed product design, MVP scope, balance targets, and acceptance criteria.
- The current implementation includes the `srcs/main.tscn` bootstrap, GDScript screen switching in `Main`, a Day-screen-only top-left pause menu with confirmed single-slot new-game replacement, 30-second Day autosaves, `LoadingScreen`, the code-built `DayScreen` and `DawnScreen`, JSON save loading, the complete P0 Day 1 loop through settlement, dawn market purchase/refund, ordered batch preparation, the Day 2 transition, purchasable Seats 3–4, the egg unlock and Lv.1–3 production loop, four fixed kitchen stations, chef/service hiring with weekly wages, and GUT coverage for this foundation.
- `tests/test_p0_loop.gd` runs the state-authoritative Day 1 growth, 20 sales, settlement, dawn purchase/preparation, Day 2 transition, save, and reload three consecutive times.

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
- `Main` owns screen creation and replacement plus the Day-screen menu, pause/resume, and periodic autosave. The menu and save timer are disabled throughout the dawn market. Screens change `GameManager.state`, then emit the no-argument `screen_change_requested` signal; `Main` reads the state to choose the next screen.
- `LoadingScreen` reads `user://save.json`, applies it to `GameManager.state`, or creates the first-day default state when no save exists.
- `DawnScreen` owns only its code-built market/preparation presentation, tap movement, station interaction, and UI. Purchases, spending, raw and ready inventory, preparation steps, prepared amounts, and phase remain authoritative in `GameManager.state`.
- `DayScreen` builds the gray Stage 01 map, tap-to-move input, player collision, fixed HUD, bounded drag camera, interaction selection, the four fixed kitchen stations, the bottom-left employee UI, and the bottom-right unlock/upgrade UI entirely from GDScript.
- The daytime kitchen always has exactly four station categories: fish, rice, other cooking, and the final counter. Menus add routes through these stations rather than adding new station nodes. Mackerel uses fish → rice → counter; egg uses other → rice → counter; a recipe with no intermediate preparation may use only the counter.
- `DayInteractionController` chooses one nearby target by explicit priority and then distance. The shared counter node owns only its local player craft progress; menu routes, orders, ingredient counts, preparation steps, employee work, and the player's carried item remain in `GameManager.state`.
- `DayCustomerManager` creates customers, assigns every unlocked seat, and creates an inventory-valid mackerel or egg order after arrival. Customer, seat, and order records are authoritative in `GameManager.state`; node position and movement remain screen-local.
- While every unlocked seat is occupied, `DayCustomerManager` spawns at the tunable interval into three fixed queue positions. On exit or a new-seat purchase it promotes FIFO heads before allowing a new customer to fill the queue.
- A finished plate keeps its customer ID. Only that customer can receive it; serving clears the player's carried item and advances the customer through eating to payment waiting.
- Each order captures its menu's sale price when it is created. Collecting that payment records the matching menu sale, starts customer exit, and releases the seat only after exit completes. `DayCustomerManager` then promotes the queue.
- The bottom-right upgrade UI charges 12 mon for mackerel Lv.2 and immediately changes the menu's final-counter duration from 3.2 to 3.0 seconds. Upgrade ownership and currency remain authoritative in `GameManager.state`.
- The same UI charges 24, 65, and 140 mon for Seats 2–4. A successful purchase immediately installs the seat, updates collision and navigation, and lets `DayCustomerManager` assign its next waiting customer. Seats 3–4 are available from Day 2.
- The right-bottom upgrade UI makes the egg menu available from Day 2 for 80 mon, then charges 40 and 90 mon for Lv.2 and Lv.3. Once unlocked, new customers immediately choose egg at the documented 30% ratio whenever ready inventory is available; egg ingredients become purchasable and preparable at the following dawn.
- The bottom-left employee UI hires at most one chef and one service employee. The chef costs a prepaid 60 mon weekly wage and automatically follows the menu route, finishing food at the shared counter. The service employee costs a prepaid 45 mon weekly wage and handles orders, counter pickup, serving, and payment. Wages recur every seven in-game days; an unpaid employee leaves.
- `GameManager.tick_service_time()` owns the authoritative countdown. At zero, `DayCustomerManager` stops spawning, dismisses only customers who have not ordered, and leaves existing orders playable through payment and exit.
- Settlement begins only after the timer is zero and customers, orders, payments, carried plates, and station plates are all cleared. `GameManager` snapshots sales and departures, discards remaining ready and raw inventory once, calculates waste cost, and changes the day phase to `settlement`; `DayScreen` only renders that state.
- Dawn market pads buy fixed five-portion bundles every second while occupied. Before preparation is confirmed, `GameManager.refund_market_purchases()` must restore both the exact currency spent and all raw quantities bought in that market session.
- Dawn preparation processes the whole purchased batch in four ordered one-second stations per material, including egg after its unlock. It may start the next day only after at least five rice and five mackerel portions are ready and every purchased batch has been prepared. Dawn has no menu or save checkpoint; saving resumes after the next `DayScreen` is created.
- Daytime production is strict: accept one customer order, follow that menu's fixed station route, and finish it at the shared counter. Approaching a station outside the route or skipping a step must not craft anything.
- `GameManager` owns authoritative game-wide runtime state, including the current day, day phase, service time and timers, currency, inventory, unlocks, upgrades, and stage progression.
- Screens and gameplay systems must not keep competing copies of state owned by `GameManager`. Update shared state through explicit `GameManager` methods and signals.
- `SaveManager` serializes and restores the confirmed `GameManager` state in the single `user://save.json` slot. `Main` saves every 30 seconds during Day play and at Day phase boundaries. It does not save during dawn market or preparation. Keep gameplay rules out of `SaveManager`.
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
