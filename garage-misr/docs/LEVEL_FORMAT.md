# Level file format (schema 1)

One JSON file per level in `levels/NNN.json`.

```json
{
  "id": 37, "w": 24, "h": 30,
  "palette": ["#C8A165", "#2BA39B", "#B4472F"],
  "cells": "<base64 of w*h bytes: color index, 255 = asphalt>",
  "queues": [
    [{"c": 0, "n": 12}, {"c": 2, "n": 9, "hidden": true}],
    [{"c": 1, "n": 20}, {"tow": true, "n": 6}]
  ],
  "bays": 5, "gate": "bottom", "cars_per_tick": 3,
  "solution": [[0, 1], [0, 0], [14, 1]],
  "schema": 1
}
```

- Cells are row-major, top row first. Hand-made levels (tests) may use `"rows"` instead of
  `"cells"`: one string per row, one char per cell, `0-9a-z` = color, `.` = asphalt.
- `queues[i][0]` is the front of queue i (the tappable trailer).
- `n` must be positive. Tow trucks have no `c` and are not part of the balance.
- `solution` is the tap sequence the generator played: `[tick, queue]` pairs (ticks counted
  from the start of the attempt). The validator replays it on the real engine and requires
  a WIN.
- Campaign levels also carry metadata the engine ignores: `garage`, `garage_name`, `item`,
  `item_name`, `extreme`, `band`, `floor`, `trap`, `stats` (`random_loss`, `smart_win` over
  200 games each) and `in_target`.
- `LevelData.validate()` checks size, palette, colors, positive numbers, known gates and the
  per-color balance; `GameEngine.load_level()` refuses invalid levels.
