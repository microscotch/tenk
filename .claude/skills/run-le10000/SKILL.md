---
name: run-le10000
description: Build, run, and drive the "Le 10000" Flutter Linux desktop app. Use when asked to start le10000, launch the app, take a screenshot of its UI, click through a screen, or otherwise verify a UI change actually works (not just `flutter test`/`flutter analyze`).
---

This is a Flutter app; the only locally-runnable target on this ARM64/Pi
host is Linux desktop (see the "Environment constraint" section of
`CLAUDE.md` — Android/iOS can't build or run here). Drive it via
`.claude/skills/run-le10000/driver.sh` under a headless Xvfb display —
there is no real display attached to this container.

All paths below are relative to the repo root.

## Prerequisites

```bash
sudo apt-get update
sudo apt-get install -y xvfb xdotool imagemagick
```

These were already present on this host when this skill was authored;
install them if `driver.sh start` fails with "command not found."

## Build

No separate build step — `flutter run -d linux` (invoked by `driver.sh
start`) builds and launches in one step. `flutter pub get` runs
automatically as part of that if dependencies changed.

## Run (agent path)

```bash
.claude/skills/run-le10000/driver.sh start
.claude/skills/run-le10000/driver.sh screenshot /tmp/shot.png
.claude/skills/run-le10000/driver.sh click 640 90
.claude/skills/run-le10000/driver.sh screenshot /tmp/shot2.png
# ^ if shot2 looks unchanged from shot, this was the session's first
#   click and it got swallowed (see Gotchas) -- click again:
.claude/skills/run-le10000/driver.sh click 640 90
.claude/skills/run-le10000/driver.sh screenshot /tmp/shot3.png
.claude/skills/run-le10000/driver.sh stop
```

`start` boots Xvfb on `DISPLAY=:97` at 1280x800, then `flutter run -d
linux` inside it, waits for the Dart VM service (~30-60s build), then
polls screenshots until the home screen has actually painted (see
Gotchas — this can itself take anywhere from ~20s to 60s+ depending on
host load, hence polling instead of a fixed sleep) — by the time it
returns "Ready.", the app is genuinely sitting on the home screen
(`SetupScreen`), not mid-animation.

Screenshots are full 1280x800 PNGs of the virtual screen (the Flutter
window fills the top-left 1280x720 of it) — pass any output path.

| command | what it does |
|---|---|
| `start` | boot Xvfb + `flutter run -d linux`, wait until ready |
| `screenshot <file.png>` | capture the whole virtual screen |
| `click <x> <y>` | move mouse to (x,y) and left-click |
| `key <keysym>` | send a key press, e.g. `Return`, `Escape`, `Tab` |
| `drag <x1> <y1> <x2> <y2>` | left-button drag (e.g. swipe-to-delete on a list row) |
| `status` | print whether Xvfb / flutter run are currently up |
| `stop` | kill flutter run + Xvfb, clean up pidfiles/lockfile |

Coordinates are logical pixels in the 1280x800 screenshot. Read the
button/text position straight off a screenshot you just took — the app
uses Material widgets with no fixed pixel grid worth hardcoding beyond
that.

## Run (human path)

`flutter run -d linux` directly, from a real desktop session (this repo
is normally developed that way — see `CLAUDE.md`). Useless headless:
without a display it fails immediately with `Gtk-WARNING: cannot open
display`. `q` in the running terminal quits.

## Test

```bash
flutter analyze   # must be clean
flutter test      # full suite; currently 166 tests, all pass
```

Neither of these launches the actual app — they don't substitute for
`driver.sh` when the change is UI/UX-shaped.

---

## Gotchas

- **`LIBGL_ALWAYS_SOFTWARE=1` is required**, or the window renders
  solid black forever under Xvfb (log shows `MESA-EGL: ... DRI3 error:
  Could not get DRI3 device`, no crash, just a black window) — there's
  no real GPU in this container. `driver.sh` already sets this.
- **The app opens on an animated splash screen** (`lib/ui/screens/
  splash_screen.dart`, ~6s logo fade-in/hold/fade-out) before
  auto-navigating to the home screen. A screenshot taken too early
  shows solid black (pre-first-paint) or the splash logo — not a
  rendering failure. Combined with slow first paint under software
  rendering, the total wait after the Dart VM service line is wildly
  inconsistent on this host under load — anywhere from ~20s to over a
  minute, observed directly (21s one run, 32s another, 70s+ a third,
  all on the same command). A fixed sleep either wastes time or isn't
  enough either way, so `driver.sh start` instead polls a screenshot
  pixel at (100,90) — inside the "New run..." button, which is amber
  (R>180) only once the home screen has actually painted, dark green
  everywhere else — until it's ready (90s timeout). If you're driving
  the app some other way than this script, replicate that check rather
  than a fixed sleep.
- **A combined `xdotool mousemove X Y click 1` is silently swallowed.**
  There's no window manager in this bare Xvfb session, so nothing
  sends the app an `XEnterNotify` before an immediate click. Use
  `mousemove --sync X Y` followed by a separate `click 1` (what
  `driver.sh click` does) — verified empirically, the combined form
  just does nothing.
- **The very first `click` of a session is reliably swallowed too**,
  even through `driver.sh click` (`--sync` + separate `click`), and
  even after waiting several extra seconds first — verified across
  multiple fresh `start`s, 0-3s of extra delay before the first click
  all still ate exactly one click; the very next click at the same
  spot always worked immediately. A throwaway click on empty
  background right after `start` does *not* fix it (also verified) —
  only a click on a real tappable widget seems to "count," which makes
  baking a silent fix into `start` itself risky (it would have to
  actually activate something to work, with no way to guarantee that
  doesn't leave the app in an unexpected screen). Simplest safe
  handling: screenshot after your first click and, if nothing changed,
  click again — see the Run section example.
- **`pkill -f le10000` kills the driver script too.** `-f` matches the
  full command line, and this script's own path
  (`.claude/skills/run-le10000/driver.sh`) contains "le10000" as a
  substring — it self-SIGKILLs mid-`stop`, silently, before it can
  clean up Xvfb. `driver.sh` uses `pkill -x le10000` (exact process
  name) instead.
- **A stale `/tmp/.X97-lock` from a previous ungracefully-killed run**
  makes a fresh `Xvfb :97` fail to bind while silently leaving the old
  one running underneath — `xdpyinfo` on the new attempt then reports
  whatever resolution the *old* Xvfb has, not the one just requested.
  `driver.sh start`/`stop` both `rm -f` this lockfile; if you ever kill
  Xvfb by hand outside the driver, remove it too.
- **`flutter run -d linux` needs GStreamer dev/runtime packages** for
  `audioplayers` (sound effects) to even compile the Linux target — see
  `CLAUDE.md`. Already installed on this host; if a fresh container
  fails on a `gstreamer-1.0` CMake error, that's the cause.

## Troubleshooting

- **`Gtk-WARNING: cannot open display:` / `Error waiting for a debug
  connection`**: `DISPLAY` isn't set to the Xvfb display, or Xvfb isn't
  running. Run `driver.sh status` first.
- **Screenshot is solid black right after `start` returns**: shouldn't
  happen (`start` polls until the home screen is actually painted —
  see Gotchas), but if it does, check
  `/tmp/le10000-run-skill/flutter_run.log` for the `MESA-EGL DRI3`
  warning — means `LIBGL_ALWAYS_SOFTWARE` didn't take effect.
- **`start` prints the "home screen not detected after 90s" warning**:
  either the app crashed after the VM service came up (check
  `flutter_run.log`), or the button moved/was restyled and the
  (100,90) amber-pixel probe no longer matches — re-sample a real
  screenshot's pixel color at that point and adjust the threshold in
  `_wait_for_home_screen`.
- **A click does nothing**: almost always the missing `--sync` /
  separate-`click` issue above, if you're not going through
  `driver.sh click`.
- **`driver.sh stop` exits without printing "Stopped."`**: was the
  `pkill -f` self-kill bug (fixed — see Gotchas); if it recurs, check
  what pattern `pkill` is using.
