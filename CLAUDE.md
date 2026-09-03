# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Flutter port of "Le 10000", a regional French dice game (Farkle-like) with a specific non-standard
ruleset. Target platforms are Android and iOS; local development happens on Linux desktop (see
Environment constraints below).

## Commands

```bash
flutter pub get              # install dependencies
flutter analyze              # static analysis (must be clean before committing)
flutter test                 # run the full test suite
flutter test test/game/combination_test.dart   # run a single test file
flutter test --plain-name "un craque affiche"  # run tests matching a name
flutter run -d linux         # run the app locally (see below — this is the only viable local target)
```

CI (`.github/workflows/build_apk.yaml`) has two jobs: `build-android` (`ubuntu-latest`) runs
`pub get`, `analyze`, `test`, then `build apk --release`; `build-ios` (`macos-latest`) runs `pub get`
then an unsigned `build ios --release --no-codesign` (no Apple signing is configured, so this only
proves the Xcode build compiles — it can't produce an installable IPA or run on a device/simulator).
Both run on every push/PR to `main`.

## Environment constraint: no local Android or iOS build

The dev machine is Raspberry Pi / Linux ARM64. Flutter itself runs fine there, but:
- Google's Android build tooling (`aapt2`) is only published for x86_64, so **Android builds and
  emulators do not work on this machine**.
- iOS builds require Xcode/macOS, which don't exist on Linux at all — **iOS can't be built, run, or
  even smoke-tested locally, only via the `build-ios` CI job** (and even there, only as an unsigned
  compile check, not a real device/simulator run).

The established workflow is:
- Local iteration and manual verification: `flutter run -d linux` (Linux desktop target) — the only
  platform this machine can actually run and interact with.
- Real Android/iOS builds: pushed to GitHub and built by CI, not built locally. Android CI verifies
  the whole test suite too, since `flutter test` runs fine on any host; iOS CI is build-only.

Do not attempt `flutter build apk`, `flutter build ios`, `flutter run -d android`, or any iOS-targeted
command locally — they will fail on this host.

`audioplayers` (sound effects) needs GStreamer to build the Linux desktop target:
`libgstreamer1.0-dev`, `libgstreamer-plugins-base1.0-dev`, plus runtime plugin packs
(`gstreamer1.0-plugins-good/bad/ugly`, `gstreamer1.0-libav`) for actual playback. These are installed
on this machine already; if `flutter run -d linux` ever fails with a `gstreamer-1.0` CMake error again
(e.g. after a fresh machine/container), reinstall via apt before assuming it's a code problem.

## Git hooks

`.githooks/pre-push` auto-bumps the `pubspec.yaml` build number before a push to `main` whenever
it hasn't already increased past what's on the remote — CI attempts a Google Play upload on
*every* push to `main` (`.github/workflows/build_apk.yaml`), and Google Play rejects any reused
`versionCode`, which is exactly the recurring failure this hook exists to prevent. It cannot inject
a commit into the push already in flight (git resolves which refs to push before invoking
`pre-push` — verified empirically, not just per docs), so instead it commits the bump locally and
**blocks that push** (exit 1) with a message asking to run `git push` again; the retry then goes
through cleanly since the local build number is now ahead of the remote's.

This hook is tracked in the repo but, like all git hooks, never activates on its own — after a
fresh clone, run once:
```bash
git config core.hooksPath .githooks
```

## Architecture

### Strict engine/UI separation

`lib/game/**` is pure Dart with zero Flutter imports. This is deliberate: the ruleset has many
non-standard, easy-to-get-wrong edge cases, so the engine is exhaustively unit-tested in isolation
from widgets. `lib/state/**` (Riverpod notifiers) is the only layer allowed to bridge engine and UI;
`lib/ui/**` should never import engine internals it doesn't need to render.

- `game/dice_roll.dart` — `rollDice(count, [Random?])`, RNG injectable for deterministic tests.
- `game/combination.dart` — `analyzeRoll(faces, {extendedValues})` scores a single roll (brelan/carré/
  quinte/suite/isolated 1s and 5s, plus the "extension" rule — see Rules below). This is the core
  scoring algorithm; almost every rule subtlety lives here or in `turn_state.dart`.
- `game/turn_state.dart` — `TurnState` (immutable) models one player's turn across multiple rolls:
  dice to roll, banked score so far, `extendedValues` accumulated this turn, `keptDiceThisTurn` (for
  permanent on-screen display), hot-dice/must-continue flag. `rollTurn()` and `applyKeepDecision()`
  are the pure transition functions; `tryBank()` decides if stopping is currently legal.
  `KeptDie.isExtended` marks a die whose value came from the extension rule (100 "temporary" points)
  rather than its normal value — used to highlight it in red in the UI.
- `game/player.dart` — `Player` holds a full `List<ScoreEntry> grid`, not a scalar score. This is
  intentional: a "tiret" (warning mark) or "barré" (struck-through) status attaches to the specific
  grid line that received it and stays there even after later successful turns add new lines. Only
  the *current* (last) line can ever receive a new tiret or be barred. `_bar()` is the single
  mechanism behind both a second consecutive bust and a score collision with another player; when it
  drops a player back to 0 it also resets `hasEntered` to false (they must clear the entry threshold
  again).
- `game/game_engine.dart` — `GameEngine` orchestrates the whole game: player rotation, dice
  inheritance between turns (`nextTurnDice`, plus `inheritedScore`/`inheritedKeptDice`/
  `inheritedExtendedValues` — only ever populated after a *successful* bank, never after a bust), and
  the win condition (exact 10000, then a final round for other players; the "crown" can change hands
  mid-final-round if someone else reaches 10000, via `triggeringWinnerIndex`/`remainingFinalTurns`).
  `startTurn(useFullHand:)` is where a player either continues an inherited hand (score + kept dice
  carried over as a bonus base) or starts fresh with 5 dice.
- `game/dice_off.dart` — separate mini state machine for the pre-game 1-die roll-off that decides
  turn order (lowest single die starts; ties re-roll among only the tied players).
- `game/ai/` — `AiStrategy` interface plus three difficulty profiles (`ai_profiles.dart`) built on a
  shared `bustProbability()` calculation.

### State layer (`lib/state/`)

- `game_providers.dart` — `GameNotifier` (`gameProvider`) wraps `GameEngine`. Notable: `bank()` leaves
  `activeTurn` null when the next player inherits fewer than 5 dice, until they choose full-hand vs.
  inherited-hand via `startTurn()`. `playAiTurnStep()` drives one AI action per call; the UI schedules
  repeated calls with a delay to simulate "thinking". `debugLoadState()` is a `@visibleForTesting` seam
  used throughout the test suite to inject a specific `GameEngine` state without relying on real RNG.
- `dice_off_providers.dart` — `DiceOffNotifier` drives the roll-off screen and, once resolved,
  `buildRotatedSetup()` reorders players so the winner becomes index 0 for the real game.

### UI layer (`lib/ui/`)

- `game_screen.dart` is the densest file: it renders different sub-views depending on
  `GameEngine.activeTurn` state (hand-choice / pending-roll-with-decision / idle-ready-to-roll-or-bank
  / busted / AI-thinking), and drives **automatic turn advancement** for the human player when there
  is no real decision to make:
  - `_scheduleAutoAdvanceIfNeeded()` auto-applies a keep decision when there's no choice of 5s to
    decline, and auto-rolls when banking is currently impossible (below minimum, ends in 50, or hot
    dice) — the player is never forced to click through a state with only one legal action.
  - When there *is* a real choice (how many 5s to keep), the keep-decision UI directly offers
    "Lancer les dés" / "S'arrêter" (computed via a hypothetical `applyKeepDecision` + `tryBank`), not a
    separate "Valider" step followed by a second screen.
  - These auto-advances use `Timer` (not bare `Future.delayed`) stored in fields and cancelled in
    `dispose()` — this matters for widget tests, since flutter_test's fake-clock `pumpAndSettle()` can
    otherwise fire disconnected timers and/or fail on "Timer still pending" at teardown.
  - Widget test states are built with `debugLoadState` snapshots; because of the auto-advance behavior,
    tests that land on a human "idle, can't bank yet" state should expect it to progress on its own
    rather than staying static.

## Game rules reference (non-obvious, load-bearing — don't reinterpret from first principles)

- 5 dice. Entry into the game requires ≥500 in one turn; once entered, ≥200/turn. A score can never
  end in a bare 50 while stopping voluntarily — that forces another roll.
- Dice inheritance between turns: only happens after a *successful* bank, carrying over both the
  leftover (un-rolled) dice count **and** the banked score/kept-dice/extended-values as a starting
  base for whichever player inherits them (their choice: take it, or start fresh with 5). A bust
  always resets the next player to 5 fresh dice with nothing inherited.
- Extension rule: once a brelan/carré of value N is banked within a turn, any further isolated die of
  value N later in the *same turn* is worth 100 points (including 5, which is otherwise 50 isolated).
  This resets whenever hot dice occurs (all dice scored → forced reroll of a fresh 5).
- Tiret/barré: a bust marks the player's current score-grid line with a tiret if it doesn't have one;
  if it already does, the line is barred and a fresh line is added at the previous value. A score
  collision bars that line the same way, tiret or not — checked against *every* non-barred line in
  every other player's grid, not just their current total: if another player ever had this exact score
  at any earlier point in the game (since superseded by a later successful turn), that historical line
  alone gets barred with no effect on their current score; only a collision on their *current* line
  drops them back to their previous score. Barring the current line back down to 0 also revokes
  "entered" status.
- Victory: first exact 10000 triggers a final round giving every other player one more turn to match
  it; if another player also reaches exactly 10000 during that round, they bar the previous holder and
  a fresh final round starts around them.
