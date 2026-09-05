---
name: architecture-diagram
description: Regenerate the class diagram in docs/architecture.md (docs/architecture/class-diagram.drawio + .png). Use when asked to update, refresh or redo the architecture/class diagram, or after a change that adds, removes or renames engine/state classes, fields or methods.
---

The diagram documents `lib/game` and `lib/state` class by class; `lib/ui` stays a
coarse layer on purpose (detailing 21 Flutter widgets drowns the structure that
matters — they are structurally uniform, the engine carries the model).

Three files move together, and all three must end up consistent:

| File | Role |
|---|---|
| `docs/architecture/class-diagram.drawio` | the source, hand-authored XML |
| `docs/architecture/class-diagram.png` | the render, with the diagram embedded so it reopens in draw.io |
| `docs/architecture.md` | the prose that explains the diagram and embeds the PNG |

## 1. Read the code, never the memory of it

Every field and method in the diagram must come from the current source. Do not
carry figures over from the previous diagram — that is exactly how a diagram
starts lying. Useful sweeps:

```bash
grep -hn "^\(abstract \)\?class \|^enum " lib/game/*.dart lib/game/ai/*.dart lib/state/*.dart | sed 's/ {.*//'
grep -nE "^\s{2}final |^\s{2}[A-Za-z<>?, ]+ get " lib/game/player.dart
grep -nE "^\s{2}(void|Future|bool|int|GameEngine)[A-Za-z<>?, ]* [a-z][A-Za-z]*\(" lib/state/game_providers.dart
```

Free functions matter here: `rollTurn`, `applyKeepDecision`, `tryBank`,
`analyzeRoll`, `rollDice` are top-level, not methods. They get their own
«fonctions pures» box — folding them into a class box would misrepresent the
design.

## 2. Edit the .drawio

Hand-written `mxGraphModel` XML. Each class is one rectangle whose label is HTML:
`<b>Name</b>` + `<hr/>` + fields + `<hr/>` + methods. Colours carry meaning and
are listed in the diagram's own legend: blue = engine, green = state, orange =
UI, yellow = enum, purple = free functions.

Check it parses before exporting — a malformed file exports as a blank or
truncated image:

```bash
python3 -c "import xml.etree.ElementTree as ET; ET.parse('docs/architecture/class-diagram.drawio'); print('ok')"
```

## 3. Export

```bash
.claude/skills/architecture-diagram/export.sh
```

Wraps the flatpak/xvfb invocation and verifies the PNG really embeds the
diagram. Two traps it exists to absorb: draw.io needs a display (`xvfb`) or it
dies on GPU init writing nothing, and the flatpak sandbox cannot see the host's
`/tmp` — files must live under `$HOME`, or the export fails while printing what
looks like a success line.

## 4. Look at the PNG — this step is not optional

Valid XML says nothing about legibility. Read the exported PNG back and hunt for:
edge labels overlapping a box or a zone title, arrows starting from the wrong
class, labels stacking where several edges converge. Every one of those has
happened here and none was visible in the XML. Fix, re-export, look again.

When several edges converge, spread `exitX`/`entryX` widely and give labels an
explicit `offset`; `labelBackgroundColor=#FFFFFF` rescues a label that has to sit
near a border.

## 5. Update `docs/architecture.md`

The prose is the deliverable, not a caption. When a class appears or disappears,
say what it means for someone reading the code — a new invariant, a new
boundary — rather than restating the box. Keep the "Regenerating" section
pointing at this skill.
