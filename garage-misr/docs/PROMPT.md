# جراج مصر (Garage Misr) — project brief

Source: "جراج مصر — مواصفات اللعبة والبرومبت الكامل", 12 Oct 2026, @mohamed ismail.
The Arabic spec's design decisions are summarised first; the full English work prompt follows.

## Key decisions (from the Arabic spec)
1. A locked car does not leave. That is what creates difficulty, and players get it without a tutorial.
2. Balance is mandatory: per color, the sum of trailer numbers == the cars of that color.
3. Every level is generated together with its solution, and rejected if a random player wins it easily.
4. Launch with 120 levels in 6 garages, then 20 new levels every two weeks.
5. Clear Egyptian identity: the attendant (السايس), trailers, horns, art of Egyptian food and landmarks.

Why the old version is easy: any trailer that enters finds free cars of its color, so it
finishes fast and the bay frees. Real difficulty must come from trailers sitting in a bay
waiting for a color still locked inside the garage.

---

You are working on my existing Godot 4 Android puzzle game. Today it is an ant game: the
player taps colored boxes, ants eat exposed pixels of a pixel-art picture. Keep the same
core logic but convert the game into "جراج مصر" (Garage Misr), a car-parking puzzle with
an Egyptian identity, fix the difficulty, and ship 120 launch levels.

PROBLEM TO FIX: the game is far too easy. I finished 100 levels tapping random boxes and
almost never lost.

GROUND RULES
- Do NOT rewrite from scratch. Inspect the project first and report: Godot version, scenes,
  scripts, how levels are stored and generated, how targets are chosen, how win/loss works.
- Remove every ant-related name, asset, text and sound. Nothing from Food Hunt or any other
  game: no names, art, levels or logos.
- Work phase by phase, in order. After each phase report files changed, tests run with real
  output, known issues. Continue only if that phase's acceptance check passes.
- Never claim something works without a test or simulator numbers. One git commit per phase.

THEME MAPPING
- Pixel -> a parked car seen from above (colored rounded rectangle with a light windshield).
- Empty pixel -> dark grey asphalt with yellow parking lines.
- Board entry -> the garage gate (bottom edge, yellow, with the garage name).
- Box -> a car-carrier trailer (تريلا) with a color and a big number = cars it carries.
- Waiting slot -> loading bay (رصيف تحميل), 5 by default.
- Tray columns -> trailer queues; hidden box -> trailer covered with a tarp, shows "?".
- Wildcard -> tow truck (ونش) with a yellow rotating light.

CORE RULES (write them to docs/RULES.md and follow them exactly)
- Garage W x H; each cell is a car of a color or empty asphalt.
- A car is free if it is on the gate row or 4-neighbour to empty asphalt connected to the gate.
- Only the first trailer of each queue can be tapped. Tap with no free bay = rejected, the
  attendant whistles, text "الأرصفة كلها مليانة".
- Each tick, every trailer in a bay calls up to 3 free cars of its color. A called car is
  reserved, drives to the gate, loads, and the trailer number drops by 1. Its cell becomes
  asphalt, which may free cars behind it.
- Trailer at 0 honks and leaves; the bay frees. A trailer with no free car of its color
  waits and shows "مستنية عربياتها…".
- Balance invariant per color: remaining cars of color C == sum of remaining numbers of
  trailers of color C. Must hold at every tick.
- Win = garage empty. Loss = all bays full AND no car driving AND no bay trailer has a free
  car of its color. Loss text "الجراج اتقفل!". No timers in loss detection.
- Tow truck (from level 41): number 5-8, takes any free car; each car it takes is deducted
  from the largest remaining trailer of that car's color so the invariant holds.

PHASE 1 - ENGINE HARDENING
- Pure RefCounted logic classes (no Nodes) on a fixed 50 ms tick. Tick order: apply queued
  taps, resolve arrived cars, remove finished trailers, dispatch new cars, check win/loss.
- Reserve a car when called; a trailer never has more cars on the way than number - inflight.
- Every car task carries level_rev; restart increments it and stale results are ignored.
- 1x and 2x speed only change ticks per second.
- Freedom: one BFS from the gate at load, then incremental flood when a car leaves; keep a
  list of free unreserved cars per color.
- Draw the whole garage with one MultiMesh (or ImageTexture), never one Node per car.
  Visible driving cars pooled, max 150.
- GUT tests: determinism (same taps -> same final state, also at 2x), no car loaded twice in
  1000 random ticks, numbers never negative, double tap in one tick, restart mid-loading,
  balance invariant every tick, loss only by the rule above, tow truck keeps the invariant.
Acceptance: all tests pass.

PHASE 2 - MEASURE THE PROBLEM
- tools/simulator.gd runs the real engine headless with two bots:
  RandomBot taps any tappable trailer at random.
  SmartBot prefers trailers whose color has free cars now and never fills the last free bay
  with a color that has no free cars unless forced.
- 200 games per bot on every current level -> reports/before.csv: level, random loss %,
  smart win %.
Acceptance: table produced (random loss near 0% is the bug).

PHASE 3 - GUARANTEED-SOLVABLE GENERATOR WITH REAL DIFFICULTY
- The generator plays the level on the real engine while inventing trailers: whenever a bay
  frees, create a trailer for a color that has free cars (or will soon), number within the
  level range and never more than what is left of that color; the last trailer of each color
  takes the exact remainder. Record the order as "solution", then distribute trailers into
  queues so each queue keeps solution order.
- Difficulty levers: buried colors (whole colors locked behind others), single gate,
  each color split into 3-5 trailers numbered 6-25, trap ordering (trailers of locked colors
  at the front of queues early), tarp "?" trailers from level 41, more colors than bays from
  level 81, decoy queues in hard levels.
- Rejection sampling: regenerate until RandomBot loss % is inside the level band, SmartBot
  wins >= 90%, and the stored solution replays to WIN on the real engine.
- tools/validator.gd checks size, palette, per-color balance, positive numbers, solution
  replay. Every level file must pass.
Acceptance: reports/after.csv shows all 120 levels in band.

DIFFICULTY BANDS (RandomBot loss %)
- 1-5 tutorial: 0% with forced first taps and the attendant pointing.
- 6-20: 5-15%  | 21-40: 20-35% | 41-60: 30-45%
- 61-80: 40-55% | 81-100: 50-65% | 101-120: 55-70%
- Every 10th level is "جراج المعلم" (Extreme): 75-85%, double reward.
- Sawtooth inside each band: easy, easy, harder. Never two Extreme in a row.

PHASE 4 - EGYPTIAN IDENTITY
Garages (20 levels each), grid, colors, queues, and the car art each level forms:
1 جراج الحارة (1-20) 16x20, 3-4 colors, 3 queues: فول، طعمية، عيش بلدي، كوباية شاي، بيض
2 جراج وسط البلد (21-40) 20x26, 4-5 colors, 4 queues: كشري، حواوشي، درة مشوية، عربية فول، كبدة
3 جراج المول (41-60) 24x30, 5-6 colors, 4-5 queues: كنافة، بسبوسة، قطايف، أم علي، آيس كريم
4 جراج ليالي رمضان (61-80) 26x32, 6-7 colors, 5 queues: فانوس، كحك، ياميش، هلال، مدفع الإفطار
5 جراج الساحل (81-100) 28x36, 6-8 colors, 5 queues, some levels with 2 gates:
  بطيخ، مانجا، شمسية، قصب، سمكة
6 جراج الجيزة (101-120) 32x40, 7-9 colors, 5-6 queues: الأهرامات، أبو الهول، برج القاهرة،
  فلوكة، توكتوك
- Art pipeline: tools/image_to_level.gd converts a PNG in art/source/ to a grid with a
  k-means palette (3-9 colors) and removes isolated cells. Until I give final art, make
  simple original placeholder pixel art for each item. ~80 images may cover 120 levels by
  reusing an image with different queues and difficulty.
- Characters: عم سعيد السايس (galabeya, cap, whistle; tutorial and rejected taps),
  الأسطى حمدي (trailer driver, appears on win), المعلم عبده (garage owner, unlocks each
  garage), the tow truck helper.
- UI fully Arabic RTL with an Arabic font, all strings in one translation file:
  play "يلا نشتغل", win "الجراج فضي! عاش يا أسطى", lose "الجراج اتقفل!", retry "تاني؟",
  continue with ad "كمّل بإعلان", extreme "جراج المعلم — صعب جدًا",
  waiting trailer "مستنية عربياتها…", rejected tap "الأرصفة كلها مليانة".
- Audio: light engine sound per leaving car, horn when a trailer leaves, attendant whistle
  on reject, "خلاص يا أسطى!" on win, light original shaabi loop. Original or free-licensed
  audio only.
- Progress meta: each finished garage upgrades the player's business (new gate, shade,
  attendant kiosk, neon sign). Cosmetic rewards: old black-and-white taxi skin, trailer with
  Egyptian truck-art patterns.
Acceptance: all 120 levels load with their garage theme and pass the validator.

PHASE 5 - FEEL AND FEEDBACK
- Locked cars dim slightly; free cars of a waiting trailer's color pulse softly.
- 4 of 5 bays full -> bays glow orange; 5 full with no progress -> red pulse.
- Hint button highlights SmartBot's next tap.
- Stars: 3 if no booster used and bays never reached 5.
Acceptance: 60 fps on a low-end Android phone with 3 GB RAM.

PHASE 6 - BOOSTERS, ECONOMY, SAVE
- Boosters: extra bay (6th bay this level, removed only when empty), undo (returns the last
  trailer to its queue with its remaining number after its cars land), shuffle queues (apply
  only if the simulator finds a solution after shuffling), tow truck. Each must keep the
  invariant and have a test.
- Coins from wins (more for Extreme). Start with 3 of each booster.
- Save progress, coins, boosters, settings and a "rewarded" flag per level so a reward is
  never given twice. Mid-level resume = level id + list of taps replayed on load.
Acceptance: killing the app mid-level or on the win screen loses and duplicates nothing.

PHASE 7 - ADS AND RELEASE PREP
- AdMob: rewarded ad for continue-after-loss and boosters; interstitial only after level
  15, max once every 3 levels, never right after a loss. Fully playable offline.
- Android AAB under 40 MB. Store text in Arabic and English.
Acceptance: offline play works; ad failures never block the game.

FINAL REPORT
- before.csv vs after.csv summary per garage.
- All 120 levels: garage, art item, grid, colors, RandomBot loss %, SmartBot win %.
- Remaining issues and what you need from me (final art, audio, AdMob ids).

## Release checklist (tick only with a passing test or simulator report behind it)
- [ ] No ant name, image or sound left in the project
- [ ] docs/RULES.md written and agreed
- [ ] Determinism test passes at 1x and 2x
- [ ] No car loads onto two trailers in 1000 random ticks
- [ ] Restart mid-loading resets everything
- [ ] Loss happens only by the defined rule
- [ ] All 120 levels pass the validator and solution replay
- [ ] after.csv: every level in band, SmartBot wins >= 90%
- [ ] Tow truck and every booster keep the balance
- [ ] Killing the app loses no progress and duplicates no reward
- [ ] 60 fps on a low-end Android phone
- [ ] Plays offline
- [ ] Name available on Google Play; art and audio original
- [ ] Privacy policy published, age rating set
- [ ] Closed test on Google Play, >= 12 testers for 14 days (new personal accounts)
