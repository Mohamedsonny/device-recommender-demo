## Original placeholder pixel art for every item, drawn from simple shapes in a normalized
## 0..1 space so the same design works on every grid size. Replaced later by real art
## through tools/image_to_level.gd. Layers are listed by importance: a level that needs n
## colors uses the first n layers (layer 0 is always the background).
class_name PlaceholderArt
extends RefCounted

const MIN_CARS := 8  # a color with fewer cars than this is merged into its neighbours

# Shapes: ["all"], ["e", cx, cy, rx, ry], ["r", x0, y0, x1, y1], ["p", [x, y, ...]],
# ["ring", cx, cy, rx, ry, thickness], ["dots", cx, cy, rx, ry, count, radius],
# ["hstripes"/"vstripes", x0, y0, x1, y1, count], ["eh", cx, cy, rx, ry] (lower half ellipse),
# ["et", cx, cy, rx, ry] (upper half ellipse).
const ITEMS := {
	# --- جراج الحارة ---------------------------------------------------------
	"ful": {"name": "فول", "layers": [
		["#E3C58F", [["all"]]],
		["#2BA39B", [["eh", 0.5, 0.52, 0.42, 0.3], ["r", 0.38, 0.8, 0.62, 0.86]]],
		["#7A4A2A", [["e", 0.5, 0.52, 0.38, 0.12]]],
		["#D9A520", [["e", 0.5, 0.5, 0.14, 0.05], ["dots", 0.5, 0.25, 0.25, 0.08, 3, 0.04]]]]},
	"taameya": {"name": "طعمية", "layers": [
		["#2BA39B", [["all"]]],
		["#F7F3EA", [["e", 0.5, 0.55, 0.45, 0.3]]],
		["#7A4A2A", [["e", 0.33, 0.5, 0.14, 0.11], ["e", 0.66, 0.5, 0.14, 0.11], ["e", 0.5, 0.66, 0.14, 0.11]]],
		["#4F8A3C", [["e", 0.66, 0.5, 0.07, 0.05], ["dots", 0.5, 0.25, 0.3, 0.07, 4, 0.04]]]]},
	"eish": {"name": "عيش بلدي", "layers": [
		["#B4472F", [["all"]]],
		["#E3C58F", [["e", 0.5, 0.48, 0.42, 0.32]]],
		["#A0622D", [["ring", 0.5, 0.48, 0.42, 0.32, 0.07]]],
		["#F4E6C8", [["dots", 0.5, 0.48, 0.25, 0.18, 6, 0.05]]]]},
	"shay": {"name": "كوباية شاي", "layers": [
		["#2BA39B", [["all"]]],
		["#F7F3EA", [["p", [0.28, 0.2, 0.72, 0.2, 0.64, 0.82, 0.36, 0.82]]]],
		["#B4472F", [["p", [0.31, 0.36, 0.69, 0.36, 0.63, 0.78, 0.37, 0.78]]]],
		["#4F8A3C", [["e", 0.6, 0.16, 0.12, 0.06], ["e", 0.42, 0.13, 0.08, 0.05]]]]},
	"beid": {"name": "بيض", "layers": [
		["#E3C58F", [["all"]]],
		["#2BA39B", [["e", 0.5, 0.52, 0.46, 0.34]]],
		["#F7F3EA", [["e", 0.36, 0.48, 0.18, 0.15], ["e", 0.64, 0.58, 0.18, 0.15]]],
		["#F2B01E", [["e", 0.36, 0.48, 0.08, 0.07], ["e", 0.64, 0.58, 0.08, 0.07]]]]},
	# --- جراج وسط البلد --------------------------------------------------------
	"koshari": {"name": "كشري", "layers": [
		["#E3C58F", [["all"]]],
		["#B4472F", [["eh", 0.5, 0.45, 0.44, 0.36]]],
		["#F4E6C8", [["e", 0.5, 0.45, 0.4, 0.14]]],
		["#C0392B", [["e", 0.5, 0.42, 0.26, 0.08]]],
		["#6B3E26", [["dots", 0.5, 0.38, 0.22, 0.06, 5, 0.04]]]]},
	"hawawshi": {"name": "حواوشي", "layers": [
		["#2BA39B", [["all"]]],
		["#D9A520", [["et", 0.5, 0.68, 0.44, 0.44]]],
		["#7A4A2A", [["et", 0.5, 0.68, 0.34, 0.33]]],
		["#3A2A1E", [["vstripes", 0.2, 0.35, 0.8, 0.66, 3]]],
		["#4F8A3C", [["r", 0.06, 0.68, 0.94, 0.74]]]]},
	"dora": {"name": "درة مشوية", "layers": [
		["#B4472F", [["all"]]],
		["#F2D14B", [["e", 0.5, 0.45, 0.16, 0.36]]],
		["#4F8A3C", [["p", [0.5, 0.86, 0.2, 0.5, 0.36, 0.84]], ["p", [0.5, 0.86, 0.8, 0.5, 0.64, 0.84]]]],
		["#6B3E26", [["dots", 0.5, 0.42, 0.1, 0.28, 6, 0.035]]],
		["#E3C58F", [["r", 0.46, 0.84, 0.54, 0.94]]]]},
	"arabeyet_ful": {"name": "عربية فول", "layers": [
		["#7FC4E8", [["all"]]],
		["#B4472F", [["r", 0.14, 0.4, 0.86, 0.72]]],
		["#3A2A1E", [["e", 0.3, 0.76, 0.1, 0.08], ["e", 0.7, 0.76, 0.1, 0.08]]],
		["#D9A520", [["e", 0.5, 0.36, 0.16, 0.1]]],
		["#2BA39B", [["r", 0.1, 0.16, 0.9, 0.26]]]]},
	"kebda": {"name": "كبدة", "layers": [
		["#D9A520", [["all"]]],
		["#E3C58F", [["e", 0.5, 0.5, 0.44, 0.22]]],
		["#6B3E26", [["e", 0.5, 0.48, 0.36, 0.1]]],
		["#4F8A3C", [["dots", 0.5, 0.46, 0.3, 0.06, 4, 0.045]]],
		["#F7F3EA", [["r", 0.16, 0.56, 0.84, 0.6]]]]},
	# --- جراج المول ------------------------------------------------------------
	"konafa": {"name": "كنافة", "layers": [
		["#2BA39B", [["all"]]],
		["#8C6A2F", [["e", 0.5, 0.5, 0.44, 0.34]]],
		["#F08A24", [["e", 0.5, 0.5, 0.38, 0.28]]],
		["#D9A520", [["ring", 0.5, 0.5, 0.3, 0.21, 0.06]]],
		["#4F8A3C", [["e", 0.5, 0.5, 0.12, 0.08]]],
		["#F7F3EA", [["dots", 0.5, 0.5, 0.26, 0.18, 4, 0.035]]]]},
	"basbousa": {"name": "بسبوسة", "layers": [
		["#B4472F", [["all"]]],
		["#9AA0A6", [["r", 0.08, 0.2, 0.92, 0.8]]],
		["#D9A520", [["r", 0.14, 0.26, 0.86, 0.74]]],
		["#A87A1F", [["vstripes", 0.14, 0.26, 0.86, 0.74, 3], ["hstripes", 0.14, 0.26, 0.86, 0.74, 2]]],
		["#F4E6C8", [["dots", 0.5, 0.5, 0.3, 0.2, 6, 0.03]]],
		["#7A4A2A", [["r", 0.08, 0.8, 0.92, 0.84]]]]},
	"qatayef": {"name": "قطايف", "layers": [
		["#7B4B94", [["all"]]],
		["#F7F3EA", [["e", 0.5, 0.55, 0.46, 0.32]]],
		["#E3C58F", [["et", 0.32, 0.6, 0.18, 0.2], ["et", 0.68, 0.6, 0.18, 0.2], ["et", 0.5, 0.44, 0.18, 0.2]]],
		["#F4E6C8", [["e", 0.32, 0.58, 0.08, 0.04], ["e", 0.68, 0.58, 0.08, 0.04], ["e", 0.5, 0.42, 0.08, 0.04]]],
		["#4F8A3C", [["dots", 0.5, 0.5, 0.3, 0.15, 5, 0.03]]],
		["#D9A520", [["ring", 0.5, 0.55, 0.46, 0.32, 0.04]]]]},
	"om_ali": {"name": "أم علي", "layers": [
		["#4F8A3C", [["all"]]],
		["#8B4A2B", [["e", 0.5, 0.52, 0.44, 0.32]]],
		["#F4E6C8", [["e", 0.5, 0.5, 0.36, 0.24]]],
		["#C07A3A", [["dots", 0.5, 0.5, 0.28, 0.18, 6, 0.04]]],
		["#3A2A1E", [["dots", 0.5, 0.5, 0.26, 0.16, 5, 0.025]]],
		["#F7F3EA", [["ring", 0.5, 0.52, 0.44, 0.32, 0.03]]]]},
	"ice_cream": {"name": "آيس كريم", "layers": [
		["#7FC4E8", [["all"]]],
		["#D9A520", [["p", [0.32, 0.48, 0.68, 0.48, 0.5, 0.92]]]],
		["#E87A8A", [["e", 0.5, 0.42, 0.2, 0.12]]],
		["#F4E6C8", [["e", 0.4, 0.3, 0.16, 0.1]]],
		["#4F8A3C", [["e", 0.6, 0.22, 0.15, 0.09]]],
		["#8C5A1E", [["vstripes", 0.36, 0.5, 0.64, 0.8, 2]]]]},
	# --- جراج ليالي رمضان --------------------------------------------------------
	"fanous": {"name": "فانوس", "layers": [
		["#1F2A44", [["all"]]],
		["#D9A520", [["p", [0.5, 0.06, 0.74, 0.3, 0.7, 0.8, 0.3, 0.8, 0.26, 0.3]]]],
		["#2BA39B", [["r", 0.33, 0.34, 0.47, 0.74]]],
		["#C0392B", [["r", 0.53, 0.34, 0.67, 0.74]]],
		["#F2D14B", [["e", 0.5, 0.56, 0.05, 0.1]]],
		["#3A2A1E", [["r", 0.36, 0.82, 0.64, 0.86], ["r", 0.46, 0.0, 0.54, 0.08]]],
		["#4F8A3C", [["r", 0.3, 0.28, 0.7, 0.32]]]]},
	"kahk": {"name": "كحك", "layers": [
		["#B4472F", [["all"]]],
		["#F7F3EA", [["e", 0.5, 0.55, 0.46, 0.34]]],
		["#E3C58F", [["e", 0.32, 0.46, 0.13, 0.1], ["e", 0.66, 0.46, 0.13, 0.1], ["e", 0.5, 0.66, 0.13, 0.1]]],
		["#C69A55", [["ring", 0.32, 0.46, 0.13, 0.1, 0.04], ["ring", 0.66, 0.46, 0.13, 0.1, 0.04], ["ring", 0.5, 0.66, 0.13, 0.1, 0.04]]],
		["#7A4A2A", [["e", 0.3, 0.72, 0.06, 0.04], ["e", 0.7, 0.7, 0.06, 0.04]]],
		["#2BA39B", [["ring", 0.5, 0.55, 0.46, 0.34, 0.03]]]]},
	"yamish": {"name": "ياميش", "layers": [
		["#1F2A44", [["all"]]],
		["#2BA39B", [["eh", 0.5, 0.45, 0.44, 0.36]]],
		["#6B3E26", [["dots", 0.5, 0.42, 0.34, 0.08, 4, 0.06]]],
		["#F08A24", [["dots", 0.5, 0.38, 0.3, 0.07, 3, 0.05]]],
		["#F4E6C8", [["dots", 0.5, 0.36, 0.3, 0.07, 4, 0.035]]],
		["#7B4B94", [["dots", 0.5, 0.4, 0.3, 0.07, 3, 0.04]]],
		["#D9A520", [["r", 0.06, 0.44, 0.94, 0.47]]]]},
	"helal": {"name": "هلال", "layers": [
		["#1F2A44", [["all"]]],
		["#3A2A1E", [["r", 0.0, 0.7, 1.0, 1.0], ["e", 0.5, 0.7, 0.16, 0.12], ["r", 0.78, 0.4, 0.84, 0.72]]],
		["#D9A520", [["e", 0.42, 0.3, 0.2, 0.15]]],
		["#1F2A44", [["e", 0.5, 0.27, 0.17, 0.13]]],
		["#F2D14B", [["dots", 0.5, 0.8, 0.3, 0.05, 4, 0.03]]],
		["#F7F3EA", [["dots", 0.5, 0.25, 0.45, 0.2, 5, 0.02]]],
		["#7B4B94", [["e", 0.78, 0.18, 0.16, 0.05]]]]},
	"madfaa": {"name": "مدفع الإفطار", "layers": [
		["#F08A24", [["all"]]],
		["#E3C58F", [["r", 0.0, 0.72, 1.0, 1.0]]],
		["#3A2A1E", [["p", [0.2, 0.6, 0.78, 0.36, 0.82, 0.44, 0.26, 0.68]]]],
		["#7A4A2A", [["e", 0.32, 0.7, 0.1, 0.08]]],
		["#F7F3EA", [["e", 0.86, 0.32, 0.1, 0.06], ["e", 0.78, 0.24, 0.07, 0.05]]],
		["#C0392B", [["r", 0.0, 0.0, 1.0, 0.12]]],
		["#F2D14B", [["e", 0.2, 0.22, 0.08, 0.06]]]]},
	# --- جراج الساحل --------------------------------------------------------------
	"batikh": {"name": "بطيخ", "layers": [
		["#7FC4E8", [["all"]]],
		["#E3C58F", [["r", 0.0, 0.82, 1.0, 1.0]]],
		["#2E6B30", [["eh", 0.5, 0.4, 0.44, 0.38]]],
		["#9BD07A", [["eh", 0.5, 0.4, 0.4, 0.34]]],
		["#D93A3A", [["eh", 0.5, 0.4, 0.36, 0.3]]],
		["#2B2B2B", [["dots", 0.5, 0.52, 0.2, 0.08, 5, 0.025]]],
		["#F2D14B", [["e", 0.85, 0.14, 0.08, 0.06]]],
		["#F7F3EA", [["e", 0.2, 0.15, 0.12, 0.04]]]]},
	"manga": {"name": "مانجا", "layers": [
		["#2BA39B", [["all"]]],
		["#F7F3EA", [["e", 0.5, 0.62, 0.46, 0.26]]],
		["#F2C12E", [["e", 0.5, 0.48, 0.28, 0.22]]],
		["#F08A24", [["e", 0.6, 0.52, 0.12, 0.1]]],
		["#4F8A3C", [["p", [0.5, 0.26, 0.74, 0.14, 0.62, 0.28]]]],
		["#6B3E26", [["r", 0.48, 0.2, 0.52, 0.27]]],
		["#FFF2B0", [["e", 0.4, 0.42, 0.06, 0.05]]],
		["#9AA0A6", [["ring", 0.5, 0.62, 0.46, 0.26, 0.03]]]]},
	"shamsiya": {"name": "شمسية", "layers": [
		["#7FC4E8", [["all"]]],
		["#E3C58F", [["r", 0.0, 0.7, 1.0, 1.0]]],
		["#1F6FA8", [["r", 0.0, 0.58, 1.0, 0.7]]],
		["#D93A3A", [["et", 0.46, 0.4, 0.38, 0.26]]],
		["#F7F3EA", [["vstripes", 0.08, 0.14, 0.84, 0.4, 3]]],
		["#6B3E26", [["r", 0.44, 0.4, 0.48, 0.86]]],
		["#F2D14B", [["e", 0.86, 0.12, 0.08, 0.06]]],
		["#4F8A3C", [["r", 0.56, 0.8, 0.9, 0.88]]]]},
	"asab": {"name": "قصب", "layers": [
		["#4F8A3C", [["all"]]],
		["#F7F3EA", [["p", [0.3, 0.24, 0.7, 0.24, 0.64, 0.86, 0.36, 0.86]]]],
		["#B7D86B", [["p", [0.32, 0.38, 0.68, 0.38, 0.63, 0.82, 0.37, 0.82]]]],
		["#F4E6C8", [["r", 0.32, 0.32, 0.68, 0.38]]],
		["#2E6B30", [["r", 0.08, 0.1, 0.14, 0.9], ["r", 0.84, 0.1, 0.9, 0.9]]],
		["#D93A3A", [["r", 0.52, 0.06, 0.56, 0.4]]],
		["#C9E8F2", [["dots", 0.5, 0.6, 0.1, 0.16, 3, 0.04]]],
		["#8C6A2F", [["hstripes", 0.08, 0.1, 0.14, 0.9, 3], ["hstripes", 0.84, 0.1, 0.9, 0.9, 3]]]]},
	"samaka": {"name": "سمكة", "layers": [
		["#1F6FA8", [["all"]]],
		["#E3C58F", [["r", 0.0, 0.84, 1.0, 1.0]]],
		["#F08A24", [["e", 0.46, 0.46, 0.28, 0.16]]],
		["#D93A3A", [["p", [0.72, 0.46, 0.92, 0.32, 0.92, 0.6]], ["p", [0.42, 0.32, 0.56, 0.24, 0.56, 0.34]]]],
		["#F7F3EA", [["e", 0.3, 0.42, 0.05, 0.04], ["dots", 0.3, 0.2, 0.15, 0.1, 3, 0.03]]],
		["#2B2B2B", [["e", 0.3, 0.42, 0.025, 0.02]]],
		["#4F8A3C", [["r", 0.08, 0.6, 0.12, 0.84], ["r", 0.86, 0.66, 0.9, 0.84]]],
		["#F2D14B", [["vstripes", 0.36, 0.32, 0.56, 0.6, 2]]]]},
}


# Floor colors for the two-tone background (floor below, wall above). The first one far
# enough from every color already in the picture is used.
const FLOORS := ["#8B5A2B", "#9AA0A6", "#E3C58F", "#2BA39B", "#B4472F", "#4F8A3C", "#1F2A44",
	"#D9A520", "#7B4B94", "#F7F3EA"]


## Draws an item on a w x h grid with n_colors colors. Returns {"cells", "palette", "colors"}.
## The rng jitters position and size so every level that reuses an item looks different.
## floor > 0 splits the background: the bottom `floor` fraction becomes a floor color and the
## rest stays the wall, which buries the wall behind the floor (one of the colors is the floor).
static func draw(key: String, w: int, h: int, n_colors: int, rng: RandomNumberGenerator,
		floor := 0.0) -> Dictionary:
	var layers: Array = ITEMS[key]["layers"]
	n_colors = mini(n_colors - (1 if floor > 0.0 else 0), layers.size())
	var j := {"dx": rng.randf_range(-0.04, 0.04), "dy": rng.randf_range(-0.03, 0.03),
		"s": rng.randf_range(0.92, 1.06)}
	var cells := PackedByteArray()
	cells.resize(w * h)
	cells.fill(0)
	var palette := []
	for li in n_colors:
		var c := palette.find(layers[li][0])  # a layer may reuse a color (cut-outs)
		if c < 0:
			c = palette.size()
			palette.append(layers[li][0])
		for shape in layers[li][1]:
			_shape(cells, w, h, shape, c, j, rng)
	if floor > 0.0:
		var fc := _floor_color(palette)
		if fc != "":
			var idx := palette.size()
			palette.append(fc)
			var y0 := int(round(h * (1.0 - floor)))
			for y in range(y0, h):
				for x in w:
					if cells[y * w + x] == 0:
						cells[y * w + x] = idx
	_clean(cells, w, h)
	return _compact(cells, w, h, palette)


static func _floor_color(palette: Array) -> String:
	for hex in FLOORS:
		var c := Color(hex)
		var ok := true
		for p in palette:
			var q := Color(p)
			if Vector3(c.r - q.r, c.g - q.g, c.b - q.b).length() < 0.35:
				ok = false
				break
		if ok:
			return hex
	return ""


static func _shape(cells: PackedByteArray, w: int, h: int, sh: Array, c: int, j: Dictionary,
		rng: RandomNumberGenerator) -> void:
	match sh[0]:
		"all":
			cells.fill(c)
		"e", "eh", "et":
			var cx: float = _x(sh[1], j); var cy: float = _y(sh[2], j)
			var rx: float = sh[3] * j["s"]; var ry: float = sh[4] * j["s"]
			_each(cells, w, h, c, func(u, v):
				var d := pow((u - cx) / rx, 2) + pow((v - cy) / ry, 2)
				return d <= 1.0 and (sh[0] == "e" or (sh[0] == "eh" and v >= cy) or (sh[0] == "et" and v <= cy)))
		"ring":
			var cx: float = _x(sh[1], j); var cy: float = _y(sh[2], j)
			var rx: float = sh[3] * j["s"]; var ry: float = sh[4] * j["s"]; var t: float = sh[5]
			_each(cells, w, h, c, func(u, v):
				var o := pow((u - cx) / rx, 2) + pow((v - cy) / ry, 2)
				var i := pow((u - cx) / maxf(0.01, rx - t), 2) + pow((v - cy) / maxf(0.01, ry - t), 2)
				return o <= 1.0 and i > 1.0)
		"r":
			var x0: float = _x(sh[1], j); var y0: float = _y(sh[2], j)
			var x1: float = _x(sh[3], j); var y1: float = _y(sh[4], j)
			_each(cells, w, h, c, func(u, v): return u >= x0 and u <= x1 and v >= y0 and v <= y1)
		"p":
			var pts := PackedVector2Array()
			var flat: Array = sh[1]
			for k in range(0, flat.size(), 2):
				pts.append(Vector2(_x(flat[k], j), _y(flat[k + 1], j)))
			_each(cells, w, h, c, func(u, v): return Geometry2D.is_point_in_polygon(Vector2(u, v), pts))
		"dots":
			var cx: float = _x(sh[1], j); var cy: float = _y(sh[2], j)
			for k in int(sh[5]):
				var a := rng.randf() * TAU
				var r := sqrt(rng.randf())
				var px: float = cx + cos(a) * r * sh[3]
				var py: float = cy + sin(a) * r * sh[4]
				var rad: float = sh[6]
				_each(cells, w, h, c, func(u, v):
					return pow(u - px, 2) + pow((v - py) * float(h) / w, 2) <= rad * rad)
		"hstripes", "vstripes":
			var x0: float = _x(sh[1], j); var y0: float = _y(sh[2], j)
			var x1: float = _x(sh[3], j); var y1: float = _y(sh[4], j)
			var n: int = sh[5]
			var vertical: bool = sh[0] == "vstripes"
			_each(cells, w, h, c, func(u, v):
				if u < x0 or u > x1 or v < y0 or v > y1:
					return false
				var f: float = (u - x0) / maxf(0.001, x1 - x0) if vertical \
					else (v - y0) / maxf(0.001, y1 - y0)
				var k := f * (2 * n + 1)
				return int(k) % 2 == 1)


static func _x(v: float, j: Dictionary) -> float:
	return 0.5 + (v - 0.5) * j["s"] + j["dx"]


static func _y(v: float, j: Dictionary) -> float:
	return 0.5 + (v - 0.5) * j["s"] + j["dy"]


static func _each(cells: PackedByteArray, w: int, h: int, c: int, inside: Callable) -> void:
	for y in h:
		for x in w:
			if inside.call((x + 0.5) / w, (y + 0.5) / h):
				cells[y * w + x] = c


## Removes isolated cells (no same-color 4-neighbour) by giving them their neighbours'
## most common color.
static func _clean(cells: PackedByteArray, w: int, h: int) -> void:
	for _pass in 2:
		for y in h:
			for x in w:
				var i := y * w + x
				var counts := {}
				var same := false
				for d in [[0, -1], [0, 1], [-1, 0], [1, 0]]:
					var nx: int = x + d[0]; var ny: int = y + d[1]
					if nx < 0 or ny < 0 or nx >= w or ny >= h:
						continue
					var nc := cells[ny * w + nx]
					if nc == cells[i]:
						same = true
					counts[nc] = int(counts.get(nc, 0)) + 1
				if not same and not counts.is_empty():
					var best := cells[i]
					var best_n := 0
					for k in counts:
						if counts[k] > best_n:
							best = k
							best_n = counts[k]
					cells[i] = best


## Merges colors with fewer than MIN_CARS cells into neighbours and renumbers the palette.
static func _compact(cells: PackedByteArray, w: int, h: int, palette: Array) -> Dictionary:
	for _pass in 3:
		var counts := {}
		for c in cells:
			counts[c] = int(counts.get(c, 0)) + 1
		var small := counts.keys().filter(func(k): return counts[k] < MIN_CARS)
		if small.is_empty():
			break
		for i in cells.size():
			if cells[i] in small:
				var x := i % w
				@warning_ignore("integer_division")
				var y := i / w
				for d in [[0, 1], [0, -1], [1, 0], [-1, 0]]:
					var nx: int = x + d[0]; var ny: int = y + d[1]
					if nx >= 0 and ny >= 0 and nx < w and ny < h and not cells[ny * w + nx] in small:
						cells[i] = cells[ny * w + nx]
						break
	var remap := {}
	var out_palette := []
	for i in cells.size():
		var c := cells[i]
		if not remap.has(c):
			remap[c] = out_palette.size()
			out_palette.append(palette[c])
		cells[i] = remap[c]
	return {"cells": cells, "palette": out_palette, "colors": out_palette.size()}
