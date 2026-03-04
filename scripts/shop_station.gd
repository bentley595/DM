extends "res://scripts/interactable.gd"
## The Weapon Shop — a merchant NPC where the player buys gear.
##
## Visual: a hooded merchant behind a small counter with coins.
## When the player presses E, it opens the Shop UI overlay
## (or shows the unlock prompt if still locked).
##
## Cost to unlock: 1,000 gold

# ── Merchant pixel art (12×18 grid, pixel_size=2) ────────────────
const PIXEL_SIZE: int = 2

const PALETTE: Array = [
	Color(0, 0, 0, 0),              # 0: transparent
	Color(0.15, 0.1, 0.2, 1.0),     # 1: dark outline
	Color(0.3, 0.2, 0.45, 1.0),     # 2: robe dark purple
	Color(0.45, 0.35, 0.6, 1.0),    # 3: robe light purple
	Color(0.85, 0.7, 0.5, 1.0),     # 4: skin
	Color(0.5, 0.35, 0.18, 1.0),    # 5: counter wood dark
	Color(0.7, 0.5, 0.25, 1.0),     # 6: counter wood light
	Color(0.9, 0.75, 0.3, 1.0),     # 7: gold coins
]

const GRID: Array = [
	[0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0],
	[0, 0, 0, 1, 2, 2, 2, 2, 1, 0, 0, 0],
	[0, 0, 0, 1, 2, 3, 3, 2, 1, 0, 0, 0],
	[0, 0, 0, 0, 1, 4, 4, 1, 0, 0, 0, 0],
	[0, 0, 0, 1, 2, 4, 4, 2, 1, 0, 0, 0],
	[0, 0, 1, 2, 2, 2, 2, 2, 2, 1, 0, 0],
	[0, 0, 1, 2, 3, 2, 2, 3, 2, 1, 0, 0],
	[0, 0, 1, 2, 2, 2, 2, 2, 2, 1, 0, 0],
	[0, 0, 0, 1, 2, 2, 2, 2, 1, 0, 0, 0],
	[0, 0, 0, 1, 2, 2, 2, 2, 1, 0, 0, 0],
	[0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0],
	[0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
	[0, 1, 6, 6, 6, 6, 6, 6, 6, 6, 1, 0],
	[0, 1, 5, 6, 7, 6, 6, 7, 6, 5, 1, 0],
	[0, 1, 5, 5, 5, 5, 5, 5, 5, 5, 1, 0],
	[0, 1, 5, 5, 5, 5, 5, 5, 5, 5, 1, 0],
	[0, 1, 1, 5, 5, 5, 5, 5, 5, 1, 1, 0],
	[0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
]


func _ready() -> void:
	unlock_cost = 1000
	unlock_meta_key = "unlocked_shop"
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

	# Draw "SHOP" label below
	_draw_label("SHOP", -8, 22)


func on_interact() -> void:
	if not is_unlocked:
		var camp: Node = get_parent()
		if camp.has_method("show_unlock_prompt"):
			camp.show_unlock_prompt(self, "WEAPON SHOP", "Buy new weapons and armor\nfrom the merchant", unlock_cost)
		return
	# Open the shop UI
	var camp: Node = get_parent()
	if camp.has_node("ShopUI"):
		var player: Node2D = _find_player()
		var gold: int = get_tree().get_meta("player_gold", 0)
		camp.get_node("ShopUI").open(player.inventory, gold)


func _draw_label(text: String, x_offset: int, y_offset: int) -> void:
	var letters: Dictionary = {
		"A": [[0,1,0],[1,0,1],[1,1,1],[1,0,1],[1,0,1]],
		"D": [[1,1,0],[1,0,1],[1,0,1],[1,0,1],[1,1,0]],
		"E": [[1,1,1],[1,0,0],[1,1,0],[1,0,0],[1,1,1]],
		"H": [[1,0,1],[1,0,1],[1,1,1],[1,0,1],[1,0,1]],
		"N": [[1,0,1],[1,1,1],[1,1,1],[1,0,1],[1,0,1]],
		"O": [[0,1,0],[1,0,1],[1,0,1],[1,0,1],[0,1,0]],
		"P": [[1,1,0],[1,0,1],[1,1,0],[1,0,0],[1,0,0]],
		"S": [[0,1,1],[1,0,0],[0,1,0],[0,0,1],[1,1,0]],
		"W": [[1,0,1],[1,0,1],[1,1,1],[1,1,1],[1,0,1]],
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
