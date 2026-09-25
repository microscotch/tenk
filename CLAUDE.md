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

CI (`.github/workflows/build_apk.yaml`) has three jobs, on every push to `main` (plus
`pull_request` and `workflow_dispatch`, where `bump-build-number` is skipped):
- `bump-build-number` (`ubuntu-latest`) — CI-side safety net for the local `.githooks/pre-push` hook
  (see Git hooks below). The other two jobs depend on it and check out the commit it resolves, so
  both build the same, possibly corrected, tree.
- `build-android` (`ubuntu-latest`) — `pub get`, `analyze`, `test`, then `build apk --release` and
  `build appbundle --release`, signed with the release keystore restored from a repo secret. Both are
  uploaded as artifacts, and the AAB is sent to the Google Play `internal` track.
- `build-ios` (`macos-latest`) — imports the Apple **distribution and development** certificates and
  their provisioning profiles from repo secrets into a temporary keychain, then builds **two signed
  IPAs**: `--release` (Distribution, `ios/ExportOptions.plist`, method `app-store-connect`), which is
  uploaded to **TestFlight** with `fastlane pilot` using an App Store Connect API key; and
  `--profile` (Development, `ios/ExportOptions-dev.plist`), for direct USB install on a registered
  device. Both are kept as artifacts.

Both store-upload steps are deliberately `continue-on-error: true`, so **a green run does not mean
the build reached Google Play or TestFlight** — a failed upload still shows as a green step. The
TestFlight step writes its real outcome to the run summary (look for the "TestFlight" heading); the
Play step doesn't yet, so for that one read the step log rather than the job status.

## Environment constraint: no local Android or iOS build

The dev machine is Raspberry Pi / Linux ARM64. Flutter itself runs fine there, but:
- Google's Android build tooling (`aapt2`) is only published for x86_64, so **Android builds and
  emulators do not work on this machine**.
- iOS builds require Xcode/macOS, which don't exist on Linux at all — **iOS can't be built, run, or
  even smoke-tested locally, only via the `build-ios` CI job**. That job does produce real, signed,
  installable IPAs (see Commands above), but nothing here can *run* them: there is no simulator on
  Linux, so the only way to exercise an iOS build is TestFlight or a USB install on a real iPhone
  (`ideviceinstaller`).

The established workflow is:
- Local iteration and manual verification: `flutter run -d linux` (Linux desktop target) — the only
  platform this machine can actually run and interact with.
- Real Android/iOS builds: pushed to GitHub and built by CI, not built locally. Android CI verifies
  the whole test suite too, since `flutter test` runs fine on any host; the iOS job doesn't re-run
  the tests, it signs and ships.

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
  turn order: everyone rolls at once (`rollAll`), lowest die starts, ties at the lowest re-roll among
  only themselves; `playOrder` gives the seats in play order (see the order rule below). Old journals
  used per-player `rollFor` and always plain rotation — `simultaneous` tells the two apart, and must
  keep doing so, or archived games would silently replay with players on the wrong seats.
- `game/game_recording.dart` — the action journal (`GameAction`, `GameActionType`) and everything
  read from it: `replayGame` (rebuilds the exact engine state *and* the dice generator where the
  journal left it), `applyGameAction`, `replayTurnStarts` (where each turn begins — bounds the
  replay slider), `diceOffActionCount`, active-duration helpers. `ReplayResult.playOrder` maps each
  engine index back to its original seat (`GameStatistics` relies on it); a `diceOffRollAll` action in
  a journal is what marks it as using the current order rule.
- `game/game_statistics.dart`, `game/score_series.dart` — statistics of one game
  (`GameStatisticsCollector` only observes the engine through `replayGame`'s callback, it
  re-implements no rule) and the per-player score curve, both **derived from the journal**.
- `game/player_profile.dart`, `game/player_stats.dart` — a player's record (`displayName` is the
  nickname if any, else the name — the display rule everywhere) and its cumulated counters.
  Statistics are never migrated: they are recomputed from the archived games (see
  `syncPlayerStatistics` below).
- `game/ai/` — `AiStrategy` interface plus three difficulty profiles (`ai_profiles.dart`) built on a
  shared `bustProbability()` calculation.

### State layer (`lib/state/`)

- `game_providers.dart` — `GameNotifier` (`gameProvider`) wraps `GameEngine`. Notable: `bank()` leaves
  `activeTurn` null when the next player inherits fewer than 5 dice, until they choose full-hand vs.
  inherited-hand via `startTurn()`. `playAiTurnStep()` drives one AI action per call; the UI schedules
  repeated calls with a delay to simulate "thinking". `debugLoadState()` is a `@visibleForTesting` seam
  used throughout the test suite to inject a specific `GameEngine` state without relying on real RNG.
  Every transition goes through `_commit`, which **appends the action to the journal BEFORE assigning
  `state`** (listeners run inside the assignment and read the journal — the game-over screen would
  otherwise see a game missing its winning move, i.e. "unfinished": all statistics at 0), then persists.
  `gameRecord` is the single answer to "which game is on screen" (played or replayed).
  Replay: `startReplay(saved)` opens straight on the game (the roll-off is not replayed, only its
  result is kept), `seekReplay(turn)` rebuilds the exact state at a turn start, `replayProgress`
  gives the turn on screen; `isReplay` makes a played game's screen, left stacked underneath, ignore
  the engine. Pause/speed/progress providers live in `replay_*_provider.dart`.
- `dice_off_providers.dart` — `DiceOffNotifier` drives the roll-off screen (`rollRound()` plays a
  whole round) and, once resolved, `buildOrderedSetup()` reorders players into `playOrder` for the
  real game (winner at index 0). The roll-off saves from its first round, so a paused game may not
  have started: `resumeSavedGame` (`lib/ui/navigation.dart`) reopens an unresolved roll-off via
  `DiceOffNotifier.resumeFromSave`, and `GameNotifier.resumeFromSave` starts the first turn itself
  when the roll-off was resolved but the game never began.
- `player_store.dart`, `player_providers.dart`, `player_statistics.dart` — the player database (one
  file per profile), the nickname resolution (`displayNamesFor(setup, profiles)` works from the
  config of the game **being shown**, linking by profile id, never by name — so an archived game
  shows nicknames with no game in progress), and `syncPlayerStatistics`, which recomputes every
  profile's statistics from the archived journals.

### UI layer (`lib/ui/`)

- **Every screen's top bar is `AppTopBar` (`lib/ui/widgets/app_top_bar.dart`), never a raw `AppBar`.**
  It drops the automatic back arrow on Android, where the system back button/gesture does the job,
  and keeps it where there is no system back (iOS, desktop). This applies to every new screen;
  `test/ui/app_top_bar_test.dart` fails on any `AppBar(` written elsewhere in `lib/ui`. The home
  screen (`SetupScreen`) has no top bar at all: rules, settings and about are buttons in its list.

- `game_screen.dart` (also the spectator replay, `replayMode`, with its controls pinned in a bottom bar
  outside the inert body) is the densest file: it renders different sub-views depending on
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

## Design documents — keep them current

`docs/architecture.md` and its class diagram (`docs/architecture/class-diagram.drawio` + `.png`)
document `lib/game` and `lib/state` class by class. **Whenever a change adds, removes or renames a
class, field or method in those two layers, or moves a responsibility between layers, update them in
the same batch** — run the `architecture-diagram` skill (`/architecture-diagram`), look at the
exported PNG, and update the prose. `docs/screen-flow.drawio` does the same for the screens. A diagram
that is a few batches late is how the documents ended up three weeks behind the code once already.

The rest of the UML set lives in `docs/uml/` and is indexed by `docs/uml.md` (use cases, components,
deployment, the game-lifecycle and roll-off state machines, five sequence diagrams). The same rule
applies: a change to a call chain, a state transition, a storage location or the CI pipeline updates the
matching diagram in the same batch. Export each one with
`.claude/skills/architecture-diagram/export.sh <file.drawio>` and look at the PNG.

## Game rules reference (non-obvious, load-bearing — don't reinterpret from first principles)

- 5 dice. Entry into the game requires ≥500 in one turn; once entered, ≥200/turn. A score can never
  end in a bare 50 while stopping voluntarily — that forces another roll.
- Dice inheritance between turns: only happens after a *successful* bank, carrying over both the
  leftover (un-rolled) dice count **and** the banked score/kept-dice/extended-values as a starting
  base for whichever player inherits them (their choice: take it, or start fresh with 5). A bust
  always resets the next player to 5 fresh dice with nothing inherited. Taking it is only offered
  when the inherited base still leaves room to bank: since resuming a hand always forces at least one
  roll (`notRolledYet`), a base that already *reaches* 10000 is a guaranteed bust, not a win — so
  `inheritedHandCannotBank` is `>=`, not `>`, and such a hand is refused exactly like one that
  overshoots.
- Extension rule: once a brelan/carré of value N is banked within a turn, any further isolated die of
  value N later in the *same turn* is worth 100 points (including 5, which is otherwise 50 isolated).
  This resets whenever hot dice occurs (all dice scored → forced reroll of a fresh 5).
- Tiret/barré: a bust marks the player's current score-grid line with a tiret if it doesn't have one;
  if it already does, the line is barred and the current line moves back onto the nearest non-barred
  earlier line (never a duplicate of the same score). The tiret belongs to the *line*, not to the
  player's visit to it (`Player.hasTiret` is exactly `currentEntry.hasTiret`, no separate flag): being
  barred back down onto a line that was tiretted earlier leaves the player one bust from being barred
  again, and keeps the game screen's warning icon in step with the grid's mark. A score
  collision bars that line the same way, tiret or not — checked against *every* non-barred line in
  every other player's grid, not just their current total: if another player ever had this exact score
  at any earlier point in the game (since superseded by a later successful turn), that historical line
  alone gets barred with no effect on their current score; only a collision on their *current* line
  drops them back to their previous score. Barring the current line back down to 0 also revokes
  "entered" status.
- Overshooting 10000 busts the turn, and that is decided at *roll* time, not after the keep decision:
  as soon as a roll's minimum unavoidable gain (mandatory groups + the 5s the player isn't allowed to
  decline, see `minimumUnavoidableGain`) would take them past 10000, the turn busts with the roll
  still on screen. Keep counts that would overshoot are never offered either, to human or AI
  (`maxKeepableFives`). `TurnState.bustReason` says which bust cause applied.
- A full hand (hot dice) forces a reroll with almost no exception, not even to claim victory: landing
  a full hand exactly on 10000 is a dead end — stopping is forbidden, and any scoring reroll overshoots
  — so `GameEngine.roll` busts the turn at the roll itself (`BustReason.fullHandAtTarget`, the roll still on
  screen, exactly like an overshoot) rather than making the player tap through "Main pleine !" into a
  foregone bust. `applyKeep` keeps the same check as a safety net, for journals recorded before this.
  `tryBank` therefore checks `mustContinue` *before* the exact-10000 shortcut; that shortcut still overrides the minimum-per-turn and ends-in-50 rules. The one
  traditional exception is the ace quint (`quinte d'as`, five 1s in a single roll, worth 10000 outright):
  it always wins on the spot, full hand or not — the only combination able to total exactly 10000 in one
  roll of 5 dice (any other quint tops out at 6000), so `applyKeep` detects it by inspecting that roll's
  scoring groups rather than reopening the rule generally.
- Turn order (roll-off): everyone rolls one die at once; the lowest starts, ties at the lowest
  re-roll among themselves. Play then follows the player list as set up on the new-game screen
  (reorderable by drag) — **except** when the last roll-off round was a duel between two
  neighbours (the list is circular: last and first are neighbours) won by the one that comes
  *second* in list order: then play runs backwards from the winner (duel J2/J3 won by J3 in a
  5-player game → J3, J2, J1, J5, J4). A tie between three or more that resolves in one round, or a
  duel between non-neighbours, keeps the normal direction.
- Victory: first exact 10000 triggers a final round giving every other player one more turn to match
  it; if another player also reaches exactly 10000 during that round, they bar the previous holder and
  a fresh final round starts around them.
