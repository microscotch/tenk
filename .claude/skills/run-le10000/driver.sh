#!/usr/bin/env bash
# Driver for running and driving the "Le 10000" Flutter Linux desktop app
# under a headless Xvfb display, for an agent with no real display attached.
#
# Usage:
#   driver.sh start                 # boots Xvfb + `flutter run -d linux`, blocks until ready
#   driver.sh screenshot <file.png> # captures the whole virtual screen to <file.png>
#   driver.sh click <x> <y>         # moves the mouse to (x,y) and left-clicks
#   driver.sh key <keysym>          # sends a key press, e.g. `Return`, `Escape`, `Tab`
#   driver.sh drag <x1> <y1> <x2> <y2>  # left-button drag (e.g. swipe-to-delete)
#   driver.sh status                # prints whether Xvfb/flutter are running
#   driver.sh stop                  # kills flutter run + Xvfb
#
# Coordinates are logical pixels within the 1280x800 virtual screen (the
# Flutter Linux desktop window opens at 1280x720 top-left, matching what
# `screenshot` captures).
set -euo pipefail

DISPLAY_NUM=97
export DISPLAY=":${DISPLAY_NUM}"
STATE_DIR="/tmp/le10000-run-skill"
XVFB_PID_FILE="$STATE_DIR/xvfb.pid"
FLUTTER_PID_FILE="$STATE_DIR/flutter.pid"
FLUTTER_LOG="$STATE_DIR/flutter_run.log"
XVFB_LOG="$STATE_DIR/xvfb.log"

# cd to the Flutter project root (parent of .claude/skills/run-le10000).
cd "$(dirname "${BASH_SOURCE[0]}")/../../.."

cmd_start() {
  mkdir -p "$STATE_DIR"

  if [ -f "$XVFB_PID_FILE" ] && kill -0 "$(cat "$XVFB_PID_FILE")" 2>/dev/null; then
    echo "Xvfb already running (PID $(cat "$XVFB_PID_FILE"))." >&2
  else
    rm -f "/tmp/.X${DISPLAY_NUM}-lock"
    Xvfb "$DISPLAY" -screen 0 1280x800x24 >"$XVFB_LOG" 2>&1 &
    echo $! >"$XVFB_PID_FILE"
    disown
    for _ in $(seq 1 20); do
      xdpyinfo >/dev/null 2>&1 && break
      sleep 0.5
    done
    xdpyinfo >/dev/null 2>&1 || { echo "Xvfb failed to start, see $XVFB_LOG" >&2; exit 1; }
  fi

  if [ -f "$FLUTTER_PID_FILE" ] && kill -0 "$(cat "$FLUTTER_PID_FILE")" 2>/dev/null; then
    echo "flutter run already running (PID $(cat "$FLUTTER_PID_FILE"))." >&2
  else
    # LIBGL_ALWAYS_SOFTWARE=1 is required: under Xvfb (no real GPU), the
    # default Impeller/EGL path silently renders an all-black window
    # (MESA-EGL "DRI3 error: Could not get DRI3 device" in the log) --
    # verified empirically, not documented anywhere obvious.
    LIBGL_ALWAYS_SOFTWARE=1 flutter run -d linux >"$FLUTTER_LOG" 2>&1 &
    echo $! >"$FLUTTER_PID_FILE"
    disown
    echo "Waiting for the app to build and start (can take ~30-60s)..." >&2
    for _ in $(seq 1 120); do
      grep -q "A Dart VM Service" "$FLUTTER_LOG" 2>/dev/null && break
      grep -qi "^Error " "$FLUTTER_LOG" 2>/dev/null && { echo "flutter run failed, see $FLUTTER_LOG" >&2; exit 1; }
      sleep 1
    done
    grep -q "A Dart VM Service" "$FLUTTER_LOG" 2>/dev/null || { echo "Timed out waiting for the app, see $FLUTTER_LOG" >&2; exit 1; }
    # The app opens on SplashScreen (lib/ui/screens/splash_screen.dart),
    # a ~6s animated intro (logo fade-in, hold, fade to the home screen)
    # BEFORE auto-navigating -- a screenshot taken too early just shows
    # this intro (solid black at first, then a fading logo), not a
    # rendering failure. Combined with slow first paint under software
    # rendering, total time after the VM service line is wildly
    # inconsistent on this host under load (21s one run, 32s the next,
    # both observed) -- a fixed sleep either wastes time or isn't
    # enough. Instead, poll a pixel that's only ever this exact amber
    # once the home screen (SetupScreen) has actually painted: (100,90)
    # sits inside the "New run..." button, which is amber (R>180) on
    # the home screen and dark green (R<50) on both the splash and any
    # other screen -- verified by sampling real screenshots of each.
    _wait_for_home_screen
  fi
  echo "Ready. DISPLAY=$DISPLAY" >&2
}

_wait_for_home_screen() {
  local probe="$STATE_DIR/_ready_probe.png" r
  for _ in $(seq 1 90); do
    import -window root "$probe" 2>/dev/null || true
    if [ -s "$probe" ]; then
      r=$(convert "$probe" -crop 1x1+100+90 -format "%[fx:int(255*p{0,0}.r)]" info: 2>/dev/null || echo 0)
      [ "${r:-0}" -gt 180 ] 2>/dev/null && { rm -f "$probe"; return 0; }
    fi
    sleep 1
  done
  rm -f "$probe"
  echo "Warning: home screen not detected after 90s -- app may still be starting, or the button moved (see SKILL.md Gotchas)." >&2
}

cmd_screenshot() {
  local out="${1:?usage: driver.sh screenshot <file.png>}"
  import -window root "$out"
  echo "$out"
}

cmd_click() {
  local x="${1:?x}" y="${2:?y}"
  # A combined `mousemove X Y click 1` is silently swallowed here (no
  # window manager, so nothing sends the app an XEnterNotify before the
  # click lands) -- `--sync` plus a separate `click` call is what
  # actually registers, verified empirically.
  xdotool mousemove --sync "$x" "$y"
  xdotool click 1
}

cmd_key() {
  local key="${1:?keysym, e.g. Return}"
  xdotool key "$key"
}

cmd_drag() {
  local x1="${1:?x1}" y1="${2:?y1}" x2="${3:?x2}" y2="${4:?y2}"
  xdotool mousemove "$x1" "$y1" mousedown 1
  xdotool mousemove --sync "$x2" "$y2"
  xdotool mouseup 1
}

cmd_status() {
  if [ -f "$XVFB_PID_FILE" ] && kill -0 "$(cat "$XVFB_PID_FILE")" 2>/dev/null; then
    echo "Xvfb: running (PID $(cat "$XVFB_PID_FILE")) on $DISPLAY"
  else
    echo "Xvfb: not running"
  fi
  if [ -f "$FLUTTER_PID_FILE" ] && kill -0 "$(cat "$FLUTTER_PID_FILE")" 2>/dev/null; then
    echo "flutter run: running (PID $(cat "$FLUTTER_PID_FILE"))"
  else
    echo "flutter run: not running"
  fi
}

cmd_stop() {
  # `|| true` on every step: under `set -e`, a bare `kill` on an
  # already-dead PID (or a `[ -f ... ] &&` chain evaluating to a
  # non-zero last status) would otherwise abort the script before it
  # gets to clean up the rest -- verified empirically.
  [ -f "$FLUTTER_PID_FILE" ] && { kill -9 "$(cat "$FLUTTER_PID_FILE")" 2>/dev/null || true; }
  # `-x` (exact process-name match), NOT `-f` (full command line): `-f`
  # would also match this very script's own argv, since the script's
  # path (.claude/skills/run-le10000/driver.sh) contains "le10000" too
  # -- pkill -9 -f le10000 killed itself mid-run, verified empirically.
  pkill -9 -x le10000 2>/dev/null || true
  [ -f "$XVFB_PID_FILE" ] && { kill -9 "$(cat "$XVFB_PID_FILE")" 2>/dev/null || true; }
  rm -f "$XVFB_PID_FILE" "$FLUTTER_PID_FILE" "/tmp/.X${DISPLAY_NUM}-lock"
  echo "Stopped." >&2
}

case "${1:-}" in
  start) cmd_start ;;
  screenshot) shift; cmd_screenshot "$@" ;;
  click) shift; cmd_click "$@" ;;
  key) shift; cmd_key "$@" ;;
  drag) shift; cmd_drag "$@" ;;
  status) cmd_status ;;
  stop) cmd_stop ;;
  *)
    echo "Usage: driver.sh {start|screenshot <file>|click <x> <y>|key <keysym>|drag <x1> <y1> <x2> <y2>|status|stop}" >&2
    exit 1
    ;;
esac
