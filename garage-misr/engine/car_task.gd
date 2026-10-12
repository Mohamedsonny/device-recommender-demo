## One car driving from its parking cell to the gate. Travel time is in ticks, not seconds.
class_name CarTask
extends RefCounted

var id: int
var trailer_id: int   # trailer the car loads onto (the tow truck, for towed cars)
var charge_id: int    # trailer whose number drops; == trailer_id unless towed
var cell: int
var color: int
var level_rev: int    # attempt this car belongs to; results from older attempts are ignored
var ticks_left: int


static func make(task_id: int, trailer: int, charged: int, target: int, car_color: int,
		rev: int, ticks: int) -> CarTask:
	var t := CarTask.new()
	t.id = task_id
	t.trailer_id = trailer
	t.charge_id = charged
	t.cell = target
	t.color = car_color
	t.level_rev = rev
	t.ticks_left = ticks
	return t
