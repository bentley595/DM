extends "res://scripts/interactable.gd"
## The Forge — an anvil station where the player upgrades equipment.
##
## Visual: a pixel-art anvil with a glowing ember underneath.
## When the player presses E, it opens the Forge UI overlay
## (or shows the unlock prompt if still locked).
##
## Cost to unlock: 2,000 gold (late-game upgrade station)

# ── Anvil pixel art (12×14 grid, pixel_size=2) ──────────────────
const PIXEL_SIZE: int = 2

const PALETTE: Array = [
	Color(0, 0, 0, 0),              # 0: transparent
	Color(0.2, 0.18, 0.16, 1.0),    # 1: dark iron outline
	Color(0.45, 0.42, 0.38, 1.0),   # 2: medium iron body
	Color(0.65, 0.62, 0.58, 1.0),   # 3: light iron highlight
	Color(0.95, 0.55, 0.15, 1.0),   # 4: ember orange
	Color(0.85, 0.25, 0.1, 1.0),    # 5: ember red
]

const GRID: Array = [
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0],
	[0, 0, 1, 3, 3, 3, 3, 3, 3, 1, 0, 0],
	[0, 1, 3, 3, 3, 3, 3, 3, 3, 3, 1, 0],
	[1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
	[0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0],
	[0, 0, 1, 1, 2, 2, 2, 2, 1, 1, 0, 0],
	[0, 0, 0, 0, 1, 2, 2, 1, 0, 0, 0, 0],
	[0, 0, 0, 0, 1, 2, 2, 1, 0, 0, 0, 0],
	[0, 0, 0, 0, 1, 2, 2, 1, 0, 0, 0, 0],
	[0, 0, 0, 1, 1, 2, 2, 1, 1, 0, 0, 0],
	[0, 0, 1, 2, 2, 2, 2, 2, 2, 1, 0, 0],
	[0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
	[0, 0, 0, 4, 5, 0, 0, 5, 4, 0, 0, 0],
]


func _ready() -> void:
	unlock_cost = 2000
	unlock_meta_key = "unlocked_forge"
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
			var color: Color = PALETTE[ci]
			draw_rect(Rect2(
				offset_x + col * PIXEL_SIZE,
				offset_y + row * PIXEL_SIZE,
				PIXEL_SIZE, PIXEL_SIZE
			), color)

	# Draw "FORGE" label below the station
	_draw_label("FORGE", -10, 16)


func on_interact() -> void:
	if not is_unlocked:
		# Tell the camp scene to show the unlock prompt
		var camp: Node = get_parent()
		if camp.has_method("show_unlock_prompt"):
			camp.show_unlock_prompt(self, "FORGE", "Upgrade your equipped items\nto become more powerful", unlock_cost)
		return
	# Open the forge UI
	var camp: Node = get_parent()
	if camp.has_node("ForgeUI"):
		var player: Node2D = _find_player()
		var gold: int = get_tree().get_meta("player_gold", 0)
		camp.get_node("ForgeUI").open(player.inventory, gold)


func _draw_label(text: String, x_offset: int, y_offset: int) -> void:
	## Draws a small text label below the station using the inventory
	## screen's bitmap font pattern.
	var letters: Dictionary = {
		"A": [[0,1,0],[1,0,1],[1,1,1],[1,0,1],[1,0,1]],
		"B": [[1,1,0],[1,0,1],[1,1,0],[1,0,1],[1,1,0]],
		"C": [[0,1,1],[1,0,0],[1,0,0],[1,0,0],[0,1,1]],
		"D": [[1,1,0],[1,0,1],[1,0,1],[1,0,1],[1,1,0]],
		"E": [[1,1,1],[1,0,0],[1,1,0],[1,0,0],[1,1,1]],
		"F": [[1,1,1],[1,0,0],[1,1,0],[1,0,0],[1,0,0]],
		"G": [[0,1,1],[1,0,0],[1,0,1],[1,0,1],[0,1,1]],
		"H": [[1,0,1],[1,0,1],[1,1,1],[1,0,1],[1,0,1]],
		"I": [[1,1,1],[0,1,0],[0,1,0],[0,1,0],[1,1,1]],
		"K": [[1,0,1],[1,0,1],[1,1,0],[1,0,1],[1,0,1]],
		"L": [[1,0,0],[1,0,0],[1,0,0],[1,0,0],[1,1,1]],
		"M": [[1,0,1],[1,1,1],[1,1,1],[1,0,1],[1,0,1]],
		"N": [[1,0,1],[1,1,1],[1,1,1],[1,0,1],[1,0,1]],
		"O": [[0,1,0],[1,0,1],[1,0,1],[1,0,1],[0,1,0]],
		"P": [[1,1,0],[1,0,1],[1,1,0],[1,0,0],[1,0,0]],
		"R": [[1,1,0],[1,0,1],[1,1,0],[1,0,1],[1,0,1]],
		"S": [[0,1,1],[1,0,0],[0,1,0],[0,0,1],[1,1,0]],
		"T": [[1,1,1],[0,1,0],[0,1,0],[0,1,0],[0,1,0]],
		"U": [[1,0,1],[1,0,1],[1,0,1],[1,0,1],[0,1,0]],
		"W": [[1,0,1],[1,0,1],[1,1,1],[1,1,1],[1,0,1]],
		"X": [[1,0,1],[1,0,1],[0,1,0],[1,0,1],[1,0,1]],
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
