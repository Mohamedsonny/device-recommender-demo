## Fixed-tick rules engine for Garage Misr. Pure logic: no Nodes, no signals, no timers.
## The view pushes commands and reads the events returned by step()/advance().
class_name GameEngine
extends RefCounted

const TICK_SEC := 0.05
const MAX_STEPS_PER_ADVANCE := 8

var level: Dictionary
var state: GameState
var command_log: Array = []  # accepted taps this attempt: {"tick", "queue"}

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


## Queues a command for the next step: {"type": "tap", "queue": n} or {"type": "restart"}.
func push_command(cmd: Dictionary) -> void:
	push_command_at(state.tick, cmd)


## Queues a command to be applied at the start of the given attempt tick.
func push_command_at(at_tick: int, cmd: Dictionary) -> void:
	var i := _pending.size()
	while i > 0 and _pending[i - 1]["tick"] > at_tick:
		i -= 1
	_pending.insert(i, {"tick": at_tick, "cmd": cmd})


## One tick: taps, arrived cars, finished trailers, call cars, win/loss. Order is fixed.
func step() -> Array:
	state.events = []
	while not _pending.is_empty() and _pending[0]["tick"] <= state.tick:
		var cmd: Dictionary = _pending.pop_front()["cmd"]
		match cmd.get("type"):
			"restart":
				_restart()
				return state.events
			"tap":
				var q := int(cmd.get("queue", -1))
				if Rules.apply_tap(state, q):
					command_log.append({"tick": state.tick, "queue": q})
	if state.phase != GameState.Phase.RUNNING:
		return state.events
	Rules.resolve_arrivals(state)
	Rules.remove_finished(state)
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


## How far real time is into the next tick (0..1), for the view to interpolate.
func tick_alpha() -> float:
	return clampf(_accum / TICK_SEC, 0.0, 1.0)


func is_finished() -> bool:
	return state.phase == GameState.Phase.WON or state.phase == GameState.Phase.LOST


## Everything that defines the attempt except level_rev, in a comparable form.
func snapshot() -> Dictionary:
	var s := state
	var trailers := []
	for t in s.trailers:
		trailers.append([t.id, t.color, t.count, t.state, t.inflight, t.bay, t.hidden])
	var queues := []
	for q in s.queues:
		queues.append(q.map(func(t): return t.id))
	var tasks := []
	for t in s.tasks:
		tasks.append([t.id, t.trailer_id, t.charge_id, t.cell, t.ticks_left])
	return {
		"tick": s.tick, "phase": s.phase, "next_task": s.next_task_id,
		"cells": s.grid.color.hex_encode(), "reserved": s.grid.reserved.hex_encode(),
		"free": s.grid.free.hex_encode(), "connected": s.grid.connected.hex_encode(),
		"trailers": trailers, "queues": queues,
		"bays": s.bays.map(func(t): return -1 if t == null else t.id),
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
	Rules.evaluate(state)  # an empty garage is won on load
