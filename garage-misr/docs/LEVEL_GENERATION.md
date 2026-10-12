# How levels are generated

Everything runs on the same engine the player uses (`engine/`).

## 1. Art
`tools/placeholder_art.gd` draws an original placeholder picture for each item from simple
shapes (ellipses, polygons, stripes, dots) in a 0..1 space, so one design fits every grid
size. Each level jitters position/size with its own seed. Isolated cells are cleaned up and
colors with fewer than 8 cars are merged away. Real art later comes from
`tools/image_to_level.gd` (not written yet) with the same output shape.

**Floor lever.** A level can split the background: the bottom `floor` fraction of the
background becomes a separate floor color, the rest is the wall. The wall color is then
buried behind the floor, which creates trailers that wait. This lever alone moves RandomBot
loss from ~0% to 30-90% on pictures whose background dominates.

## 2. Solution trace (guaranteed solvable)
`LevelGenerator.trace()` plays the garage headless. Whenever a bay is free it invents a
trailer for a color that has spare free cars (free cars minus what bay trailers of that color
still need), weighted by that spare supply. Its number is random in the garage range, never
more than what is left of the color, and the last trailer of each color takes the exact
remainder. Every trailer is tapped at once; the `(tick, queue)` sequence is the solution.

## 3. Queues and the trap lever
`build_level(trap)` lays the trace out in the queues; order inside every queue follows the
solution, so the stored taps stay valid.
- `trap = 0`: round robin. Every queue front is a trailer needed soon.
- `trap = 1`: the solution is cut into one chunk per queue. All but one queue start with
  trailers whose colors are still locked deep inside the garage: a random tapper fills the
  bays with trailers that can only wait.
- Between: each trailer follows the chunk rule with probability `trap`.
- From level 41 a quarter of the non-front trailers get a tarp ("?"), and one tow truck
  (number 5-8) goes to the back of a queue, where it never blocks a solution trailer.
- Extreme levels use trailer numbers at 60% of the garage range (more trailers crowd the bays).

## 4. Acceptance (rejection sampling)
`LevelGenerator.generate()` tries up to 8 art variants (16 for Extreme) × 9 trap values.
Each candidate is screened with 40 RandomBot games; candidates inside the band get the full
measurement (200 RandomBot + 200 SmartBot games). A level is accepted when:
- RandomBot loss is inside the level's sawtooth target (lower half of the band for "easy",
  upper half for every 3rd level), else kept as a fallback if inside the band;
- SmartBot wins >= 90%;
- `LevelValidator.check()` passes (size, palette, balance, positive numbers, tow 5-8,
  solution replays to WIN).

## Bots
- **RandomBot**: whenever a bay is free, taps a random non-empty queue.
- **SmartBot**: taps a front whose color has spare free cars (random among the near-best);
  hesitates 30% of ticks; never fills the last free bay with a locked color unless nothing
  else can move; with 3+ free bays and no good choice it pre-places the locked color nearest
  the gate; uses the tow truck when stuck. The hint button uses it without hesitation.

## Deviation from the brief
The brief asks for "each color split into 3-5 trailers numbered 6-25". On the campaign grids
(320 to 1008 cars) that is arithmetically impossible: a 28x36 garage with 6 colors averages
~170 cars per color. Numbers therefore scale with the grid: الحارة 8-25, وسط البلد 10-30,
المول 12-35, ليالي رمضان 14-40, الساحل 15-45 (Extreme levels: 60% of that).

## Commands
    # generate (4 processes in parallel)
    for i in 1 2 3 4; do godot --headless -s tools/build_levels.gd -- --from=$i --to=100 --stride=4 & done; wait
    # old-style baseline for reports/before.csv
    godot --headless -s tools/build_levels.gd -- --before --from=1 --to=100
    # reports/after.csv + reports/summary.md
    godot --headless -s tools/report.gd
    # art preview sheet
    godot --headless -s tools/preview_art.gd
