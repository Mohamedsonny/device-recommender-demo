# جراج مصر — Rules (v1)

This file is the source of truth for the engine (`engine/`). If a rule is missing, stop and
ask; never invent one. Anything not confirmed is a per-level setting, not hard-coded.

## Elements

- **Garage**: grid `W x H`, seen from above. Each cell holds a car of one color (palette
  index 0–8) or is empty asphalt.
- **Gate**: the bottom edge by default. A level may set `gate` to `bottom`, `top`, `left`,
  `right`, `all`, or a list (e.g. `["bottom", "top"]` for two gates in جراج الساحل).
- **Free car**: a car on a gate edge, or a 4-neighbour of asphalt connected to a gate
  (asphalt connected = reachable from a gate through asphalt, 4 directions). Every other
  car is locked. Diagonals never free a car.
- **Trailer (تريلا)**: a color + a number = how many cars it will carry.
- **Queues**: columns of trailers. Only the first trailer of a queue can be tapped. A tarp
  trailer (`hidden`, shown as "?") reveals its color when it becomes first.
- **Loading bays (أرصفة)**: 5 by default (`bays`).
- **Tow truck (ونش)**: a special queued trailer `{"tow": true, "n": 5-8}` from level 41.

## Tick

The engine runs a fixed tick of 50 ms. 2× speed only means more ticks per second. Each tick,
in this exact order:

1. **Taps**: apply queued taps in order. A tap moves the first trailer of the queue into the
   leftmost free bay at once (the bay is booked in logic before any animation). If no bay is
   free the tap is rejected (`tap_rejected`, reason `bays_full`: the attendant whistles,
   "الأرصفة كلها مليانة"). Taps on an empty queue or after win/loss are rejected too.
2. **Arrivals**: every driving car advances one tick; cars that reach the gate load. Their
   cell becomes asphalt (which may free cars behind it), and the trailer's number drops by 1.
3. **Finished trailers**: a bay trailer at 0 honks and leaves (`trailer_left`), freeing its
   bay. A queued trailer the tow truck brought to 0 is removed from its queue
   (`trailer_emptied`).
4. **Calls**: bays left to right, each trailer calls up to `cars_per_tick` (default 3) free
   cars of its color, never more than `number - inflight`. A called car is reserved
   immediately, so it can never load onto two trailers. Cars are called in the order they
   became free. Travel time = `travel_base_ticks + gate_distance / travel_cells_per_tick`.
5. **Win / loss** (below).

A trailer in a bay with no free car of its color just waits ("مستنية عربياتها…") and does not
affect anything else.

## Win and loss

- **Win**: the garage is empty.
- **Loss** ("الجراج اتقفل!"): every bay is full **and** no car is driving **and** no bay
  trailer has a free unreserved car of its color (a tow truck counts any color). No timers.
- Consequences: while a bay is free there is no loss. A non-empty garage always has at least
  one free car, so a tow truck in a bay prevents loss.

## Balance invariant

For every color C, at every tick:

    remaining cars of color C == sum of numbers of trailers of color C that are not done

The validator rejects any level that breaks it. A car's removal and its trailer's decrement
happen in the same step, so it holds every tick.

## Tow truck (ونش)

- Number 5–8; takes any free car, `cars_per_tick` per tick like a trailer.
- Color choice (deterministic): prefer colors no bay trailer is currently calling (stuck
  colors), then the color with the most free cars, then the lowest color index.
- Each towed car is **charged** to the colored trailer of that color with the most cars still
  to call (`number - inflight`, ties: lowest id), wherever it is (queue or bay). The charge
  counts as that trailer's inflight while the car drives; on arrival both the tow truck and
  the charged trailer drop by 1. This keeps the balance invariant.
- A queued trailer charged down to 0 leaves its queue.

## Restart

Restart rebuilds the attempt from the level file, increments `level_rev` and drops queued
taps. Every car task carries the `level_rev` of its attempt; a result with an old
`level_rev` is ignored.

## Level settings

| Key | Default | Note |
|---|---|---|
| `bays` | 5 | extra-bay booster adds 1 for the level |
| `gate` | `bottom` | two gates in some جراج الساحل levels |
| `cars_per_tick` | 3 | max cars a trailer calls per tick |
| `travel_base_ticks` | 4 | ticks for a car on the gate row |
| `travel_cells_per_tick` | 2 | extra tick per this many cells of distance |
| tarp trailers | none | from level 41 |
| cars block each other while driving | no | post-launch update |
