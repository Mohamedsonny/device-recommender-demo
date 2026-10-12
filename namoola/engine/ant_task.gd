## One ant on its way to a reserved pixel. Travel time is counted in ticks, not seconds.
class_name AntTask
extends RefCounted

var id: int
var box_id: int
var cell: int
var level_rev: int   # attempt this ant belongs to; results from older attempts are ignored
var ticks_left: int


static func make(task_id: int, box: int, target: int, rev: int, ticks: int) -> AntTask:
	var t := AntTask.new()
	t.id = task_id
	t.box_id = box
	t.cell = target
	t.level_rev = rev
	t.ticks_left = ticks
	return t
