extends "res://scripts/interactable.gd"
## The Infinite Dungeon — an ominous portal for the end-game challenge.
##
## Visual: a larger, darker portal with swirling energy — looks more
## dangerous than the regular dungeon entrance.
##
## Cost to unlock: 10,000 gold (end-game content)
## Currently a PLACEHOLDER — shows "COMING SOON" when interacted with.

# ── Portal pixel art (14×18 grid, pixel_size=2) ──────────────────
const PIXEL_SIZE: int = 2

const PALETTE: Array = [
	Color(0, 0, 0, 0),              # 0: transparent
	Color(0.1, 0.05, 0.12, 1.0),    # 1: very dark stone
	Color(0.25, 0.15, 0.3, 1.0),    # 2: dark purple stone
	Color(0.4, 0.25, 0.45, 1.0),    # 3: medium purple stone
	Color(0.05, 0.02, 0.1, 1.0),    # 4: void black
	Color(0.2, 0.05, 0.35, 1.0),    # 5: dark swirl
	Color(0.5, 0.1, 0.7, 1.0),      # 6: bright energy
	Color(0.8, 0.4, 1.0, 1.0),      # 7: energy spark
]

const GRID: Array = [
	[0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0],
	[0, 0, 1, 3, 3, 2, 2, 2, 2, 3, 3, 1, 0, 0],
	[0, 1, 3, 2, 1, 1, 1, 1, 1, 1, 2, 3, 1, 0],
	[1, 2, 1, 4, 4, 5, 4, 4, 5, 4, 4, 1, 2, 1],
	[1, 2, 1, 4, 5, 6, 5, 5, 6, 5, 4, 1, 2, 1],
	[1, 2, 1, 5, 6, 7, 6, 6, 7, 6, 5, 1, 2, 1],
	[1, 2, 1, 4, 5, 6, 7, 7, 6, 5, 4, 1, 2, 1],
	[1, 2, 1, 4, 5, 6, 7, 7, 6, 5, 4, 1, 2, 1],
	[1, 2, 1, 5, 6, 7, 6, 6, 7, 6, 5, 1, 2, 1],
	[1, 2, 1, 4, 5, 6, 5, 5, 6, 5, 4, 1, 2, 1],
	[1, 2, 1, 4, 4, 5, 6, 6, 5, 4, 4, 1, 2, 1],
	[1, 2, 1, 4, 4, 4, 5, 5, 4, 4, 4, 1, 2, 1],
	[1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1],
	[1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
	[1, 2, 2, 3, 2, 2, 2, 2, 2, 2, 3, 2, 2, 1],
	[0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0],
	[0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
]

## Animation: the portal sparkles alternate every 0.4 seconds.
var _anim_timer: float = 0.0
var _anim_frame: int = 0


func _ready() -> void:
	unlock_cost = 10000
	unlock_meta_key = "unlocked_infinite_dungeon"
	super._ready()


func _process(delta: float) -> void:
	super._process(delta)
	# Animate the portal sparkle effect
	_anim_timer += delta
	if _anim_timer >= 0.4:
		_anim_timer -= 0.4
		_anim_frame = 1 - _anim_frame
		queue_redraw()


func _draw_station() -> void:
	var grid_h: int = GRID.size()
	var grid_w: int = GRID[0].size()
	var offset_x: float = -grid_w * PIXEL_SIZE / 2.0
	var offset_y: float = -grid_h * PIXEL_SIZE / 2.0

	for row in grid_h:
		for col in grid_w:
			var ci: int = GRID[row][col]
			if ci == 0:
				continue
			var color: Color = PALETTE[ci]
			# Swap sparkle colors on alternate frames for animation
			if ci == 7 and _anim_frame == 1:
				color = PALETTE[6]
			elif ci == 6 and _anim_frame == 1:
				color = PALETTE[7]
			draw_rect(Rect2(
				offset_x + col * PIXEL_SIZE,
				offset_y + row * PIXEL_SIZE,
				PIXEL_SIZE, PIXEL_SIZE
			), color)

	# Draw "ABYSS" label below (sounds more ominous than "INFINITE DUNGEON")
	_draw_label("ABYSS", -10, 22)


func on_interact() -> void:
	if not is_unlocked:
		var camp: Node = get_parent()
		if camp.has_method("show_unlock_prompt"):
			camp.show_unlock_prompt(self, "INFINITE DUNGEON", "Descend into an endless\ndungeon of infinite floors", unlock_cost)
		return
	# PLACEHOLDER — this feature isn't built yet!
	# For now, just print a message.  Later this will transition
	# to a procedurally generated dungeon scene.
	print("Infinite Dungeon: COMING SOON!")


func _draw_label(text: String, x_offset: int, y_offset: int) -> void:
	var letters: Dictionary = {
		"A": [[0,1,0],[1,0,1],[1,1,1],[1,0,1],[1,0,1]],
		"B": [[1,1,0],[1,0,1],[1,1,0],[1,0,1],[1,1,0]],
		"S": [[0,1,1],[1,0,0],[0,1,0],[0,0,1],[1,1,0]],
		"Y": [[1,0,1],[1,0,1],[0,1,0],[0,1,0],[0,1,0]],
		" ": [[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0]],
	}
	var cx: int = x_offset
	var color: Color = Color(0.6, 0.3, 0.8, 1.0)  # purple to match the portal
	for ch in text:
		if letters.has(ch):
			var glyph: Array = letters[ch]
			for row in range(glyph.size()):
				for col_idx in range(glyph[row].size()):
					if glyph[row][col_idx] == 1:
						draw_rect(Rect2(cx + col_idx, y_offset + row, 1, 1), color)
		cx += 4
