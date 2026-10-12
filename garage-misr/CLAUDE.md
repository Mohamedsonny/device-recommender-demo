# Garage Misr (جراج مصر)

Original car-parking color-sort puzzle for Android, Godot 4.3, GDScript.
Full brief: docs/PROMPT.md. Rules: docs/RULES.md — follow exactly; if a rule is missing,
stop and ask, never invent one.

## Architecture
- `engine/` is pure logic: RefCounted classes only, no Node, no signals to UI, no timers.
- Fixed 50 ms tick. Each tick in order: apply queued taps, resolve arrived cars, remove
  finished trailers, call cars, evaluate win/loss.
- Cars reserved when called; a trailer calls at most number - inflight cars.
- Every CarTask carries level_rev; restart increments it and stale results are ignored.
- Loss = all bays full AND no car driving AND no bay trailer has a free car of its color.
- `view/` only reads engine events. The garage is drawn with one MultiMesh, never a Node per car.
- Same engine runs the game, the generator (tools/) and the tests.

## Running tests
    GODOT=/path/to/godot4 ./run_tests.sh
run_tests.sh also fails on script/parse errors (GUT alone silently skips broken scripts).

## Work style
One phase at a time (docs/PROMPT.md); inspect files before editing; run tests after every
change and paste the real output; never claim something works without a test or simulator
numbers. One commit per phase. End each phase with: files changed, tests run + results,
known issues, next step. No ant/Food Hunt names, art or sounds anywhere.
