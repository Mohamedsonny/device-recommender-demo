## Fixed-tick rules engine. Pure logic: no Nodes, no signals, no timers.
## The view pushes commands and reads the events returned by step()/advance().
class_name GameEngine
extends RefCounted

const TICK_SEC := 0.05
const MAX_STEPS_PER_ADVANCE := 8

var level: Dictionary
var state: GameState
var command_log: Array = []  # accepted taps this attempt: {"tick", "col"}

var _pending: Array = []  # {"tick", "cmd"} kept sorted by tick, stable
var _accum := 0.0
var _rev := 0


## Validates and loads a level. Returns the validation errors (empty on success).
func load_level(lv: Dictionary) -> PackedStringArray:
	var errs := LevelData.validate(lv)
	if not errs.is_empty():
		return errs
	level = lv
	_rev = 0
	_reset()
	return errs


## Queues a command for the next step: {"type": "tap", "col": n} or {"type": "restart"}.
func push_command(cmd: Dictionary) -> void:
	push_command_at(state.tick, cmd)


## Queues a command to be applied at the start of the given attempt tick.
func push_command_at(at_tick: int, cmd: Dictionary) -> void:
	var i := _pending.size()
	while i > 0 and _pending[i - 1]["tick"] > at_tick:
		i -= 1
	_pending.insert(i, {"tick": at_tick, "cmd": cmd})


## One tick: commands, arrivals, free boxes, dispatch, win/loss. Order is fixed.
func step() -> Array:
	state.events = []
	while not _pending.is_empty() and _pending[0]["tick"] <= state.tick:
		var cmd: Dictionary = _pending.pop_front()["cmd"]
		match cmd.get("type"):
			"restart":
				_restart()
				return state.events
			"tap":
				var col := int(cmd.get("col", -1))
				if Rules.apply_tap(state, col):
					command_log.append({"tick": state.tick, "col": col})
	if state.phase != GameState.Phase.RUNNING:
		return state.events
	Rules.resolve_arrivals(state)
	Rules.free_done_boxes(state)
	Dispatcher.dispatch(state)
	Rules.evaluate(state)
	state.tick += 1
	return state.events


## Real-time driver. speed only changes ticks per second, never the logic.
func advance(delta: float, speed := 1.0) -> Array:
	var out := []
	_accum += delta * speed
	var n := 0
	while _accum >= TICK_SEC and n < MAX_STEPS_PER_ADVANCE:
		_accum -= TICK_SEC
		out.append_array(step())
		n += 1
	if n == MAX_STEPS_PER_ADVANCE:
		_accum = minf(_accum, TICK_SEC)
	return out


func is_finished() -> bool:
	return state.phase == GameState.Phase.WON or state.phase == GameState.Phase.LOST


## Everything that defines the attempt except level_rev, in a comparable form.
func snapshot() -> Dictionary:
	var s := state
	var boxes := []
	for b in s.boxes:
		boxes.append([b.id, b.color, b.count, b.state, b.inflight, b.slot, b.hidden])
	var tray := []
	for col in s.tray:
		tray.append(col.map(func(b): return b.id))
	var tasks := []
	for t in s.tasks:
		tasks.append([t.id, t.box_id, t.cell, t.ticks_left])
	return {
		"tick": s.tick, "phase": s.phase, "next_task": s.next_task_id,
		"cells": s.board.color.hex_encode(), "reserved": s.board.reserved.hex_encode(),
		"exposed": s.board.exposed.hex_encode(), "connected": s.board.connected.hex_encode(),
		"boxes": boxes, "tray": tray,
		"slots": s.slots.map(func(b): return -1 if b == null else b.id),
		"tasks": tasks,
	}


func state_hash() -> String:
	return var_to_str(snapshot()).sha256_text()


func _restart() -> void:
	_rev += 1
	_reset()
	state.emit("restarted")


func _reset() -> void:
	state = LevelData.build_state(level, _rev)
	_pending.clear()
	command_log.clear()
	_accum = 0.0
	Rules.evaluate(state)  # a level with no pixels is won on load
