## Playable prototype screen: garage, gate, loading bays, trailer queues, HUD.
## Builds its UI in code. Drives the engine with real time and feeds events to the view.
extends Control

const SAVE_PATH := "user://progress.cfg"
const BG := Color("#F1E7D0")
const GATE := Color("#F2C230")
const BAY_EMPTY := Color("#4A4D52")

var engine := GameEngine.new()
var level: Dictionary = {}
var level_id := 1
var speed := 1.0

var view: GarageView
var _holder: Control
var _gate: ColorRect
var _gate_label: Label
var _title: Label
var _subtitle: Label
var _bays: Array = []      # [PanelContainer, Label number, Label status]
var _queues_box: HBoxContainer
var _queues: Array = []    # [Button, Label preview]
var _toast: Label
var _toast_time := 0.0
var _hint_queue := -1
var _hint_time := 0.0
var _overlay: PanelContainer
var _overlay_label: Label
var _overlay_next: Button
var _speed_btn: Button
var _palette: Array = []


func _ready() -> void:
	var th := Theme.new()
	th.default_font = load("res://fonts/Cairo.ttf")
	th.default_font_size = 26
	theme = th
	layout_direction = Control.LAYOUT_DIRECTION_RTL
	_build_ui()
	level_id = _load_progress()
	load_level(level_id)


func level_exists(id: int) -> bool:
	return FileAccess.file_exists(LevelLoader.path_for(id))


func load_level(id: int) -> void:
	if not level_exists(id):
		_show_toast("مفيش مرحلة %d" % id)
		return
	level_id = id
	level = LevelLoader.load_file(LevelLoader.path_for(id))
	var errs := engine.load_level(level)
	if not errs.is_empty():
		_show_toast(str(errs))
		return
	_palette = level.get("palette", [])
	view.setup(engine, _palette)
	_title.text = Strings.t("level") % id + " — " + str(level.get("garage_name", ""))
	var sub := str(level.get("item_name", ""))
	if level.get("extreme", false):
		sub = Strings.t("extreme") + " · " + sub
	elif id <= 5:
		sub = Strings.t("tutorial")
	_subtitle.text = sub
	_gate_label.text = Strings.t("gate") + " · " + str(level.get("garage_name", ""))
	_build_queues()
	_overlay.visible = false
	_layout_garage()
	_refresh()
	_save_progress()


func tap_queue(q: int) -> void:
	engine.push_command({"type": "tap", "queue": q})


func restart() -> void:
	engine.push_command({"type": "restart"})
	_overlay.visible = false


func show_hint() -> void:
	var q := Bots.choose_smart(engine.state)
	if q < 0:
		_show_toast(Strings.t("hint_wait"))
	else:
		_hint_queue = q
		_hint_time = 1.5


func _process(delta: float) -> void:
	if engine.state == null:
		return
	var events := engine.advance(delta, speed)
	view.apply_events(events)
	for ev in events:
		match ev["type"]:
			"tap_rejected":
				if ev["reason"] == "bays_full":
					_show_toast(Strings.t("bays_full"))
			"won":
				_show_overlay(true)
			"lost":
				_show_overlay(false)
	if level_id <= 5 and not engine.is_finished():
		_hint_queue = Bots.choose_smart(engine.state)  # tutorial: the attendant points
		_hint_time = 0.2
	if not events.is_empty() or _hint_time > 0.0:
		_refresh()
	_hint_time = maxf(0.0, _hint_time - delta)
	_toast_time = maxf(0.0, _toast_time - delta)
	_toast.visible = _toast_time > 0.0


# --- UI construction ----------------------------------------------------------------

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	# RTL: the first child sits on the right, so "previous" points right.
	top.add_child(_button("›", func(): load_level(level_id - 1)))
	_title = _label("", 30)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(_title)
	top.add_child(_button("‹", func(): load_level(level_id + 1)))

	_subtitle = _label("", 20)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_subtitle)

	var tools := HBoxContainer.new()
	tools.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(tools)
	tools.add_child(_button(Strings.t("retry"), restart))
	_speed_btn = _button(Strings.t("speed_1"), _toggle_speed)
	tools.add_child(_speed_btn)
	tools.add_child(_button(Strings.t("hint"), show_hint))

	_holder = Control.new()
	_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_holder.clip_contents = true
	_holder.layout_direction = Control.LAYOUT_DIRECTION_LTR
	_holder.resized.connect(_layout_garage)
	root.add_child(_holder)
	view = GarageView.new()
	_holder.add_child(view)
	_gate = ColorRect.new()
	_gate.color = GATE
	_holder.add_child(_gate)
	_gate_label = _label("", 16)
	_gate_label.add_theme_color_override("font_color", Color("#3A2A1E"))
	_gate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gate.add_child(_gate_label)

	var bays := HBoxContainer.new()
	bays.alignment = BoxContainer.ALIGNMENT_CENTER
	bays.add_theme_constant_override("separation", 6)
	root.add_child(bays)
	for i in 6:
		var p := PanelContainer.new()
		p.custom_minimum_size = Vector2(108, 84)
		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		p.add_child(box)
		var n := _label("", 28)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(n)
		var st := _label("", 13)
		st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(st)
		bays.add_child(p)
		_bays.append([p, n, st])

	_queues_box = HBoxContainer.new()
	_queues_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_queues_box.add_theme_constant_override("separation", 10)
	_queues_box.custom_minimum_size = Vector2(0, 170)
	root.add_child(_queues_box)

	_toast = _label("", 24)
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.position.y = 150
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_color_override("font_color", Color.WHITE)
	_toast.add_theme_stylebox_override("normal", _box(Color(0.15, 0.1, 0.05, 0.85), 12))
	_toast.visible = false
	add_child(_toast)

	_overlay = PanelContainer.new()
	_overlay.set_anchors_preset(Control.PRESET_CENTER)
	_overlay.add_theme_stylebox_override("panel", _box(Color(1, 0.97, 0.88, 0.97), 24))
	var ov := VBoxContainer.new()
	ov.add_theme_constant_override("separation", 16)
	_overlay.add_child(ov)
	_overlay_label = _label("", 34)
	_overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ov.add_child(_overlay_label)
	var ob := HBoxContainer.new()
	ob.alignment = BoxContainer.ALIGNMENT_CENTER
	ov.add_child(ob)
	ob.add_child(_button(Strings.t("retry"), restart))
	_overlay_next = _button(Strings.t("next"), func(): load_level(level_id + 1))
	ob.add_child(_overlay_next)
	_overlay.visible = false
	add_child(_overlay)


func _build_queues() -> void:
	for c in _queues_box.get_children():
		c.queue_free()
	_queues.clear()
	for q in engine.state.queues.size():
		var col := VBoxContainer.new()
		col.custom_minimum_size = Vector2(110, 0)
		var b := Button.new()
		b.custom_minimum_size = Vector2(110, 96)
		b.add_theme_font_size_override("font_size", 34)
		var qi := q
		b.pressed.connect(func(): tap_queue(qi))
		col.add_child(b)
		var preview := _label("", 18)
		preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(preview)
		_queues_box.add_child(col)
		_queues.append([b, preview])


func _layout_garage() -> void:
	if engine.state == null or _holder == null:
		return
	var g := engine.state.grid
	var gw := g.w * GarageView.CELL
	var gh := (g.h + 1) * GarageView.CELL
	var avail := _holder.size
	if avail.x <= 0 or avail.y <= 0:
		return
	var sc := minf(avail.x / gw, avail.y / gh)
	view.scale = Vector2(sc, sc)
	view.position = Vector2((avail.x - gw * sc) / 2.0, (avail.y - gh * sc) / 2.0)
	_gate.position = view.position + Vector2(0, g.h * GarageView.CELL * sc)
	_gate.size = Vector2(gw * sc, GarageView.CELL * sc)
	_gate_label.size = _gate.size
	_gate_label.add_theme_font_size_override("font_size", int(clampf(GarageView.CELL * sc * 0.7, 10, 22)))


# --- refresh ---------------------------------------------------------------------------

func _refresh() -> void:
	var s := engine.state
	for i in _bays.size():
		var p: PanelContainer = _bays[i][0]
		p.visible = i < s.bays.size()
		if not p.visible:
			continue
		var t = s.bays[i]
		if t == null:
			p.add_theme_stylebox_override("panel", _box(BAY_EMPTY, 10))
			_bays[i][1].text = ""
			_bays[i][2].text = ""
			continue
		var col := _trailer_color(t)
		p.add_theme_stylebox_override("panel", _box(col, 10))
		_bays[i][1].text = Strings.t("tow") + " " + str(t.count) if t.is_tow else str(t.count)
		_bays[i][1].add_theme_color_override("font_color", _ink(col))
		_bays[i][2].add_theme_color_override("font_color", _ink(col))
		var waiting: bool = t.inflight == 0 and t.count > 0 and \
			not (s.any_free_car() if t.is_tow else s.grid.has_free(t.color))
		_bays[i][2].text = Strings.t("waiting") if waiting else ""
	var full := s.bays.count(null) == 0
	for q in _queues.size():
		var b: Button = _queues[q][0]
		var queue: Array = s.queues[q]
		if queue.is_empty():
			b.text = Strings.t("queue_empty")
			b.disabled = true
			_style_button(b, Color("#BDB3A0"))
			_queues[q][1].text = ""
			continue
		b.disabled = false
		var front: Trailer = queue[0]
		var col := _trailer_color(front)
		b.text = (Strings.t("tow") + "\n" if front.is_tow else "") + str(front.count)
		_style_button(b, col, q == _hint_queue and _hint_time > 0.0)
		var rest := []
		for k in range(1, mini(4, queue.size())):
			rest.append("?" if queue[k].hidden else str(queue[k].count))
		_queues[q][1].text = " · ".join(rest) + (" +%d" % (queue.size() - 4) if queue.size() > 4 else "")
		b.modulate = Color(1, 1, 1, 0.75) if full else Color.WHITE


func _show_overlay(won: bool) -> void:
	_overlay_label.text = Strings.t("win") if won else Strings.t("lose")
	_overlay_next.visible = won and level_exists(level_id + 1)
	_overlay.visible = true
	_overlay.reset_size()
	_overlay.position = (size - _overlay.size) / 2.0


func _show_toast(text: String) -> void:
	_toast.text = "  " + text + "  "
	_toast_time = 1.4
	_toast.visible = true
	_toast.reset_size()
	_toast.position.x = (size.x - _toast.size.x) / 2.0


func _toggle_speed() -> void:
	speed = 2.0 if speed == 1.0 else 1.0
	_speed_btn.text = Strings.t("speed_2") if speed == 2.0 else Strings.t("speed_1")


# --- helpers -----------------------------------------------------------------------------

func _trailer_color(t: Trailer) -> Color:
	if t.is_tow:
		return Color("#F2C230")
	return Color(_palette[t.color]) if t.color < _palette.size() else Color.GRAY


func _ink(c: Color) -> Color:
	return Color("#1E1A14") if c.get_luminance() > 0.55 else Color.WHITE


func _style_button(b: Button, col: Color, highlight := false) -> void:
	var sb := _box(col, 14)
	if highlight:
		sb.border_color = Color("#FF3B30")
		sb.set_border_width_all(6)
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(st, sb)
	for fc in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(fc, _ink(col))


func _box(col: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb


func _label(text: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color("#3A2A1E"))
	return l


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(72, 56)
	b.pressed.connect(cb)
	return b


func _load_progress() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		return int(cfg.get_value("progress", "level", 1))
	return 1


func _save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "level", level_id)
	cfg.save(SAVE_PATH)
