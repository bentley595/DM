extends "res://scripts/interactable.gd"
## The Dungeon Entrance — a stone archway that leads to the combat area.
##
## Visual: a dark stone arch with a glowing purple portal inside.
## When the player presses E, it transitions to game.tscn (the dungeon).
##
## This station is FREE — available from the start!

# ── Portal pixel art (14×18 grid, pixel_size=2) ──────────────────
const PIXEL_SIZE: int = 2

const PALETTE: Array = [
	Color(0, 0, 0, 0),              # 0: transparent
	Color(0.15, 0.12, 0.18, 1.0),   # 1: dark stone outline
	Color(0.35, 0.3, 0.38, 1.0),    # 2: medium stone
	Color(0.5, 0.45, 0.55, 1.0),    # 3: light stone highlight
	Color(0.15, 0.08, 0.25, 1.0),   # 4: dark portal
	Color(0.35, 0.15, 0.55, 1.0),   # 5: medium portal
	Color(0.6, 0.3, 0.8, 1.0),      # 6: bright portal glow
]

const GRID: Array = [
	[0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0],
	[0, 0, 0, 1, 3, 3, 2, 2, 3, 3, 1, 0, 0, 0],
	[0, 0, 1, 3, 2, 2, 2, 2, 2, 2, 3, 1, 0, 0],
	[0, 1, 2, 1, 4, 4, 4, 4, 4, 4, 1, 2, 1, 0],
	[0, 1, 2, 1, 4, 5, 5, 5, 5, 4, 1, 2, 1, 0],
	[0, 1, 2, 1, 4, 5, 6, 6, 5, 4, 1, 2, 1, 0],
	[0, 1, 2, 1, 4, 5, 6, 6, 5, 4, 1, 2, 1, 0],
	[0, 1, 2, 1, 4, 5, 6, 6, 5, 4, 1, 2, 1, 0],
	[0, 1, 2, 1, 4, 5, 5, 5, 5, 4, 1, 2, 1, 0],
	[0, 1, 2, 1, 4, 5, 6, 6, 5, 4, 1, 2, 1, 0],
	[0, 1, 2, 1, 4, 5, 5, 5, 5, 4, 1, 2, 1, 0],
	[0, 1, 2, 1, 4, 4, 5, 5, 4, 4, 1, 2, 1, 0],
	[0, 1, 2, 1, 4, 4, 4, 4, 4, 4, 1, 2, 1, 0],
	[0, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 0],
	[0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0],
	[0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0],
	[0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
]


func _ready() -> void:
	# This station is FREE — no unlock cost!
	unlock_cost = 0
	is_unlocked = true
	super._ready()


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
			draw_rect(Rect2(
				offset_x + col * PIXEL_SIZE,
				offset_y + row * PIXEL_SIZE,
				PIXEL_SIZE, PIXEL_SIZE
			), PALETTE[ci])

	# Draw "DUNGEON" label below
	_draw_label("DUNGEON", -14, 22)


func on_interact() -> void:
	# Open the dungeon crafting UI instead of going straight in.
	# The crafting UI lets the player choose WHAT kind of dungeon
	# they want by placing ingredients into slots!
	var camp: Node = get_parent()
	if camp.has_node("DungeonCraftUI"):
		var player: Node2D = _find_player()
		var gold: int = get_tree().get_meta("player_gold", 0)
		if player:
			camp.get_node("DungeonCraftUI").open(gold)


func _draw_label(text: String, x_offset: int, y_offset: int) -> void:
	var letters: Dictionary = {
		"D": [[1,1,0],[1,0,1],[1,0,1],[1,0,1],[1,1,0]],
		"E": [[1,1,1],[1,0,0],[1,1,0],[1,0,0],[1,1,1]],
		"G": [[0,1,1],[1,0,0],[1,0,1],[1,0,1],[0,1,1]],
		"N": [[1,0,1],[1,1,1],[1,1,1],[1,0,1],[1,0,1]],
		"O": [[0,1,0],[1,0,1],[1,0,1],[1,0,1],[0,1,0]],
		"U": [[1,0,1],[1,0,1],[1,0,1],[1,0,1],[0,1,0]],
		" ": [[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0]],
	}
	var cx: int = x_offset
	var color: Color = Color(0.7, 0.7, 0.8, 1.0)
	for ch in text:
		if letters.has(ch):
			var glyph: Array = letters[ch]
			for row in range(glyph.size()):
				for col_idx in range(glyph[row].size()):
					if glyph[row][col_idx] == 1:
						draw_rect(Rect2(cx + col_idx, y_offset + row, 1, 1), color)
		cx += 4
