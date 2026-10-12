## Renders every placeholder item (one per garage column) to reports/art_preview.png.
## Usage: godot --headless -s tools/preview_art.gd
extends SceneTree

const SCALE := 6


func _init() -> void:
	var tiles := []
	for gi in 5:
		var g: Dictionary = Campaign.GARAGES[gi]
		for ii in g["items"].size():
			var rng := RandomNumberGenerator.new()
			rng.seed = gi * 10 + ii
			var art := PlaceholderArt.draw(g["items"][ii], g["w"], g["h"], g["colors"][1], rng)
			tiles.append([gi, ii, g["w"], g["h"], art])
	var cw := 32 * SCALE + 8
	var ch := 40 * SCALE + 8
	var img := Image.create(cw * 5, ch * 5, false, Image.FORMAT_RGB8)
	img.fill(Color("#222222"))
	for t in tiles:
		var art: Dictionary = t[4]
		var cells: PackedByteArray = art["cells"]
		for y in t[3]:
			for x in t[2]:
				var col := Color(art["palette"][cells[y * t[2] + x]])
				img.fill_rect(Rect2i(t[0] * cw + 4 + x * SCALE, t[1] * ch + 4 + y * SCALE,
					SCALE - 1, SCALE - 1), col)
		print("%s: %d colors" % [Campaign.GARAGES[t[0]]["items"][t[1]], art["colors"]])
	img.save_png("res://reports/art_preview.png")
	quit()
