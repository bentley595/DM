extends CanvasLayer
## Dungeon Crafting UI — place ingredients into slots to generate a dungeon!
##
## This is inspired by Craftmine: instead of entering a random dungeon,
## you CHOOSE what goes in it by placing ingredients.  Enemy ingredients
## determine what you fight, modifiers change rewards/difficulty, and
## room ingredients change the dungeon's structure.
##
## Key concept: **recipe pattern**.
## The crafting slots build a "recipe" Dictionary that describes the
## dungeon.  This recipe is passed to the game scene via SceneTree
## metadata, where the dungeon manager reads it to generate rooms.
## It's the same data-passing pattern used for character index,
## player name, gold, and inventory throughout the project!
##
## The player starts with 3 ingredient slots and can buy more for
## 1,000G each (up to 6 max).

const IngredientData = preload("res://scripts/ingredient_data.gd")

# ── Layout ──────────────────────────────────────────────────────
const PANEL_X: int = 40
const PANEL_Y: int = 15
const PANEL_W: int = 240
const PANEL_H: int = 162

# Crafting slots (top section)
const SLOTS_X: int = PANEL_X + 16
const SLOTS_Y: int = PANEL_Y + 24
const SLOT_SIZE: int = 16
const SLOT_GAP: int = 4
const MAX_SLOTS: int = 6

# Buy slot button (the "+" next to the last slot)
const BUY_SLOT_COST: int = 1000

# Bag grid (player's ingredients, below the crafting slots)
const BAG_X: int = PANEL_X + 16
const BAG_Y: int = PANEL_Y + 58
const BAG_SLOT_W: int = 24
const BAG_SLOT_H: int = 18
const BAG_COLS: int = 4
const BAG_ROWS: int = 3
const BAG_GAP: int = 2

# Scroll arrows (right side of bag grid)
const SCROLL_X: int = BAG_X + BAG_COLS * (BAG_SLOT_W + BAG_GAP) + 2
const SCROLL_ARROW_W: int = 7
const SCROLL_ARROW_H: int = 4

# Effects preview (below bag grid)
const PREVIEW_Y: int = PANEL_Y + 122

# Enter button
const BTN_X: int = PANEL_X + PANEL_W - 72
const BTN_Y: int = PANEL_Y + PANEL_H - 18
const BTN_W: int = 64
const BTN_H: int = 12

# Close button
const CLOSE_X: int = PANEL_X + 8
const CLOSE_Y: int = BTN_Y
const CLOSE_W: int = 28
const CLOSE_H: int = 12

# ── Colors ──────────────────────────────────────────────────────
const COL_BG       := Color(0, 0, 0, 0.78)
const COL_PANEL    := Color(0.06, 0.06, 0.14, 1.0)
const COL_BORDER   := Color(0.55, 0.55, 0.75, 1.0)
const COL_SLOT     := Color(0.12, 0.12, 0.22, 1.0)
const COL_SLOT_HLT := Color(0.9, 0.75, 0.3, 1.0)
const COL_TITLE    := Color(1.0, 1.0, 1.0, 1.0)
const COL_LABEL    := Color(0.75, 0.75, 0.85, 1.0)
const COL_INGR     := Color(0.4, 0.8, 0.5, 1.0)
const COL_DIM      := Color(0.4, 0.4, 0.4, 1.0)
const COL_GOLD     := Color(0.9, 0.75, 0.3, 1.0)
const COL_BTN_OK   := Color(0.15, 0.35, 0.15, 1.0)
const COL_BTN_BRD  := Color(0.3, 0.7, 0.3, 1.0)
const COL_BTN_DIM  := Color(0.15, 0.15, 0.2, 1.0)
const COL_ERROR    := Color(1.0, 0.4, 0.4, 1.0)
const COL_PLUS     := Color(0.5, 0.5, 0.7, 1.0)

# ── Bitmap font ─────────────────────────────────────────────────
const LETTERS: Dictionary = {
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
	"V": [[1,0,1],[1,0,1],[1,0,1],[0,1,0],[0,1,0]],
	"W": [[1,0,1],[1,0,1],[1,1,1],[1,1,1],[1,0,1]],
	"X": [[1,0,1],[1,0,1],[0,1,0],[1,0,1],[1,0,1]],
	"Y": [[1,0,1],[1,0,1],[0,1,0],[0,1,0],[0,1,0]],
	" ": [[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0]],
	"0": [[0,1,0],[1,0,1],[1,0,1],[1,0,1],[0,1,0]],
	"1": [[0,1,0],[1,1,0],[0,1,0],[0,1,0],[1,1,1]],
	"2": [[1,1,0],[0,0,1],[0,1,0],[1,0,0],[1,1,1]],
	"3": [[1,1,0],[0,0,1],[0,1,0],[0,0,1],[1,1,0]],
	"4": [[1,0,1],[1,0,1],[1,1,1],[0,0,1],[0,0,1]],
	"5": [[1,1,1],[1,0,0],[1,1,0],[0,0,1],[1,1,0]],
	"6": [[0,1,1],[1,0,0],[1,1,0],[1,0,1],[0,1,0]],
	"7": [[1,1,1],[0,0,1],[0,1,0],[0,1,0],[0,1,0]],
	"8": [[0,1,0],[1,0,1],[0,1,0],[1,0,1],[0,1,0]],
	"9": [[0,1,0],[1,0,1],[0,1,1],[0,0,1],[0,1,0]],
	"+": [[0,0,0],[0,1,0],[1,1,1],[0,1,0],[0,0,0]],
	"%": [[1,0,1],[0,0,1],[0,1,0],[1,0,0],[1,0,1]],
	",": [[0,0,0],[0,0,0],[0,0,0],[0,1,0],[1,0,0]],
}

# ── State ───────────────────────────────────────────────────────
var is_open: bool = false
var _inventory: Dictionary = {}
var _gold: int = 0

## How many crafting slots the player currently has (starts at 3).
var _slot_count: int = 3

## The ingredients placed in each crafting slot.
## Each entry is either {} (empty) or {"id": "...", "level": 1}.
var _slots: Array = []

## How many rows the bag grid is scrolled down.
## 0 = showing the first BAG_ROWS rows, 1 = shifted down one row, etc.
var _bag_scroll: int = 0

## Flash feedback timer (brief color flash when buying a slot or entering).
var _flash_timer: float = 0.0
var _flash_msg: String = ""
var _flash_col: Color = COL_INGR

var _canvas: Node2D


func _ready() -> void:
	layer = 10
	visible = false
	_canvas = Node2D.new()
	_canvas.draw.connect(_on_draw)
	add_child(_canvas)


func open(inv: Dictionary, gold: int) -> void:
	_inventory = inv
	_gold = gold
	_slot_count = get_tree().get_meta("dungeon_slot_count", 3)
	# Initialize empty crafting slots
	_slots = []
	for i in range(_slot_count):
		_slots.append({})
	_bag_scroll = 0
	_flash_timer = 0.0
	_flash_msg = ""
	is_open = true
	visible = true
	_canvas.queue_redraw()


func close() -> void:
	# Return any placed ingredients back to the player's bag
	for i in range(_slots.size()):
		if not _slots[i].is_empty():
			IngredientData.add_to_bag(_inventory["bag"], _slots[i].get("id", ""))
			_slots[i] = {}
	is_open = false
	visible = false


func _process(delta: float) -> void:
	if _flash_timer > 0:
		_flash_timer -= delta
		if _flash_timer <= 0:
			_flash_msg = ""
		_canvas.queue_redraw()


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	get_viewport().set_input_as_handled()

	if event is InputEventKey and event.is_pressed():
		if event.physical_keycode == KEY_ESCAPE or event.physical_keycode == KEY_E:
			close()
			return

	if event is InputEventMouseButton and event.pressed:
		var mp: Vector2 = get_viewport().get_mouse_position()

		# Mouse wheel scrolls the ingredient bag grid
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_bag_scroll = maxi(_bag_scroll - 1, 0)
			_canvas.queue_redraw()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_bag_scroll = mini(_bag_scroll + 1, _max_scroll())
			_canvas.queue_redraw()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_handle_click(mp)


func _handle_click(mp: Vector2) -> void:
	# ── Click scroll arrows ──────────────────────────────────────
	if _rect_scroll_up().has_point(mp):
		_bag_scroll = maxi(_bag_scroll - 1, 0)
		_canvas.queue_redraw()
		return
	if _rect_scroll_down().has_point(mp):
		_bag_scroll = mini(_bag_scroll + 1, _max_scroll())
		_canvas.queue_redraw()
		return

	# ── Click on a crafting slot → remove ingredient back to bag ──
	for i in range(_slots.size()):
		var r: Rect2 = _rect_craft_slot(i)
		if r.has_point(mp) and not _slots[i].is_empty():
			IngredientData.add_to_bag(_inventory["bag"], _slots[i].get("id", ""))
			_slots[i] = {}
			_canvas.queue_redraw()
			return

	# ── Click the "+" button to buy a new slot ───────────────────
	if _slots.size() < MAX_SLOTS:
		var plus_r: Rect2 = _rect_plus_button()
		if plus_r.has_point(mp):
			if _gold >= BUY_SLOT_COST:
				_gold -= BUY_SLOT_COST
				get_tree().set_meta("player_gold", _gold)
				_slot_count += 1
				get_tree().set_meta("dungeon_slot_count", _slot_count)
				_slots.append({})
				# Update gold HUD
				var camp: Node = get_parent()
				if camp.has_node("HUD"):
					camp.get_node("HUD").update_gold(_gold)
				_flash_msg = "SLOT ADDED"
				_flash_col = COL_INGR
				_flash_timer = 1.0
			else:
				_flash_msg = "NOT ENOUGH GOLD"
				_flash_col = COL_ERROR
				_flash_timer = 1.0
			_canvas.queue_redraw()
			return

	# ── Click on a bag ingredient → place into first empty slot ──
	var ingredients: Array = _get_bag_ingredients()
	var visible_start: int = _bag_scroll * BAG_COLS
	for vi in range(BAG_COLS * BAG_ROWS):
		var fi: int = visible_start + vi
		if fi >= ingredients.size():
			break
		var r: Rect2 = _rect_bag_slot(vi)
		if r.has_point(mp):
			var entry: Dictionary = ingredients[fi]
			# Find first empty crafting slot
			var placed: bool = false
			for si in range(_slots.size()):
				if _slots[si].is_empty():
					# Put a single copy into the craft slot
					_slots[si] = {"id": entry.item.get("id", ""), "level": 1}
					# Decrement the stack (or remove if last one)
					IngredientData.remove_one(_inventory["bag"], entry.actual_i)
					placed = true
					break
			if not placed:
				_flash_msg = "ALL SLOTS FULL"
				_flash_col = COL_ERROR
				_flash_timer = 1.0
			_canvas.queue_redraw()
			return

	# ── Click ENTER DUNGEON button ───────────────────────────────
	var enter_r: Rect2 = Rect2(BTN_X, BTN_Y, BTN_W, BTN_H)
	if enter_r.has_point(mp):
		_try_enter_dungeon()
		return

	# ── Click CLOSE button ───────────────────────────────────────
	var close_r: Rect2 = Rect2(CLOSE_X, CLOSE_Y, CLOSE_W, CLOSE_H)
	if close_r.has_point(mp):
		close()


func _try_enter_dungeon() -> void:
	# Build the recipe from placed ingredients
	var recipe: Dictionary = _build_recipe()

	# Must have at least 1 enemy ingredient
	if recipe["enemy_types"].is_empty():
		_flash_msg = "NEED ENEMY INGREDIENT"
		_flash_col = COL_ERROR
		_flash_timer = 1.5
		_canvas.queue_redraw()
		return

	# Consume the placed ingredients (don't return to bag)
	# Clear the slots without returning items
	_slots = []

	# Save recipe to metadata
	get_tree().set_meta("dungeon_recipe", recipe)

	# Save player state
	var camp: Node = get_parent()
	if camp.has_method("_save_player_state"):
		camp._save_player_state()

	# Stop music
	if camp.has_node("MusicPlayer"):
		camp.get_node("MusicPlayer").stop_song()

	is_open = false
	visible = false
	get_tree().change_scene_to_file("res://scenes/game.tscn")


## Builds a dungeon recipe Dictionary from the currently placed ingredients.
func _build_recipe() -> Dictionary:
	var recipe: Dictionary = {
		"enemy_types": [],
		"room_count": 3,
		"enemy_hp_bonus": 0,
		"gold_multiplier": 1.0,
		"loot_bonus": false,
		"has_boss": false,
	}

	for slot in _slots:
		if slot.is_empty():
			continue
		var data: Dictionary = IngredientData.INGREDIENTS.get(slot.get("id", ""), {})
		if data.is_empty():
			continue

		# Enemy ingredients add to the enemy pool
		if data.has("enemy_type"):
			var etype: String = data["enemy_type"]
			if not recipe["enemy_types"].has(etype):
				recipe["enemy_types"].append(etype)

		# Modifier ingredients change stats
		if data.has("gold_multiplier"):
			recipe["gold_multiplier"] *= data["gold_multiplier"]
		if data.has("enemy_hp_bonus"):
			recipe["enemy_hp_bonus"] += data["enemy_hp_bonus"]
		if data.has("loot_bonus"):
			recipe["loot_bonus"] = true

		# Room ingredients change structure
		if data.has("extra_rooms"):
			recipe["room_count"] += data["extra_rooms"]
		if data.has("boss_room"):
			recipe["has_boss"] = true

	return recipe


## Returns bag items that are ingredients, with their actual bag index.
func _get_bag_ingredients() -> Array:
	var bag: Array = _inventory.get("bag", [])
	var result: Array = []
	for i in range(bag.size()):
		var item: Dictionary = bag[i]
		var id: String = item.get("id", "")
		if IngredientData.INGREDIENTS.has(id):
			result.append({"actual_i": i, "item": item})
	return result


# ── Hit-test rectangles ─────────────────────────────────────────

func _rect_craft_slot(i: int) -> Rect2:
	return Rect2(SLOTS_X + i * (SLOT_SIZE + SLOT_GAP), SLOTS_Y, SLOT_SIZE, SLOT_SIZE)

func _rect_plus_button() -> Rect2:
	return Rect2(SLOTS_X + _slots.size() * (SLOT_SIZE + SLOT_GAP), SLOTS_Y, SLOT_SIZE, SLOT_SIZE)

func _rect_bag_slot(vi: int) -> Rect2:
	var col: int = vi % BAG_COLS
	var row: int = vi / BAG_COLS
	return Rect2(BAG_X + col * (BAG_SLOT_W + BAG_GAP), BAG_Y + row * (BAG_SLOT_H + BAG_GAP), BAG_SLOT_W, BAG_SLOT_H)


# ── Drawing ─────────────────────────────────────────────────────

func _on_draw() -> void:
	if not is_open:
		return

	var mp: Vector2 = get_viewport().get_mouse_position()

	# Background overlay
	_canvas.draw_rect(Rect2(0, 0, 320, 180), COL_BG)

	# Main panel
	_canvas.draw_rect(Rect2(PANEL_X, PANEL_Y, PANEL_W, PANEL_H), COL_PANEL)
	_draw_border(PANEL_X, PANEL_Y, PANEL_W, PANEL_H, COL_BORDER)

	# Title
	_draw_text(PANEL_X + 4, PANEL_Y + 4, "CRAFT DUNGEON", COL_TITLE)

	# Gold display (top right of panel)
	var gold_str: String = _format_gold(_gold) + "G"
	var gold_x: int = PANEL_X + PANEL_W - 4 - gold_str.length() * 4
	_draw_text(gold_x, PANEL_Y + 4, gold_str, COL_GOLD)

	# Section label
	_draw_text(SLOTS_X, SLOTS_Y - 8, "INGREDIENTS", COL_LABEL)

	# ── Crafting slots ──────────────────────────────────────────
	for i in range(_slots.size()):
		var r: Rect2 = _rect_craft_slot(i)
		var is_hovered: bool = r.has_point(mp)
		_canvas.draw_rect(r, COL_SLOT)
		var border: Color = COL_SLOT_HLT if (is_hovered and not _slots[i].is_empty()) else COL_BORDER
		_draw_border(int(r.position.x), int(r.position.y), int(r.size.x), int(r.size.y), border)

		# Draw ingredient icon if slot is filled
		if not _slots[i].is_empty():
			var id: String = _slots[i].get("id", "")
			var data: Dictionary = IngredientData.INGREDIENTS.get(id, {})
			var icon: Array = data.get("icon", [])
			var ix: int = int(r.position.x) + 4
			var iy: int = int(r.position.y) + 4
			for row in range(icon.size()):
				for col in range(icon[row].size()):
					if icon[row][col] == 1:
						_canvas.draw_rect(Rect2(ix + col, iy + row, 1, 1), COL_INGR)

	# ── "+" button to buy more slots ────────────────────────────
	if _slots.size() < MAX_SLOTS:
		var pr: Rect2 = _rect_plus_button()
		var plus_hovered: bool = pr.has_point(mp)
		_canvas.draw_rect(pr, COL_SLOT)
		var plus_border: Color = COL_SLOT_HLT if plus_hovered else COL_BORDER
		_draw_border(int(pr.position.x), int(pr.position.y), int(pr.size.x), int(pr.size.y), plus_border)
		# Draw "+" in center
		_draw_text(int(pr.position.x) + 6, int(pr.position.y) + 5, "+", COL_PLUS)
		# Cost label below
		_draw_text(int(pr.position.x) - 2, int(pr.position.y) + SLOT_SIZE + 2, _format_gold(BUY_SLOT_COST) + "G", COL_DIM)

	# ── Bag grid (ingredients only) ─────────────────────────────
	_draw_text(BAG_X, BAG_Y - 8, "YOUR INGREDIENTS", COL_LABEL)
	var ingredients: Array = _get_bag_ingredients()
	var visible_start: int = _bag_scroll * BAG_COLS
	for vi in range(BAG_COLS * BAG_ROWS):
		var fi: int = visible_start + vi
		var r: Rect2 = _rect_bag_slot(vi)
		var is_hovered: bool = r.has_point(mp)
		_canvas.draw_rect(r, COL_SLOT)
		var border: Color = COL_SLOT_HLT if (is_hovered and fi < ingredients.size()) else COL_BORDER
		_draw_border(int(r.position.x), int(r.position.y), int(r.size.x), int(r.size.y), border)

		if fi < ingredients.size():
			var item: Dictionary = ingredients[fi].item
			var id: String = item.get("id", "")
			var data: Dictionary = IngredientData.INGREDIENTS.get(id, {})
			var icon: Array = data.get("icon", [])
			# Draw icon
			var ix: int = int(r.position.x) + 2
			var iy: int = int(r.position.y) + 3
			for row in range(icon.size()):
				for col in range(icon[row].size()):
					if icon[row][col] == 1:
						_canvas.draw_rect(Rect2(ix + col, iy + row, 1, 1), COL_INGR)
			# Draw short name to the right of icon
			var short_name: String = data.get("name", "").to_upper().split(" ")[0]
			if short_name.length() > 5:
				short_name = short_name.substr(0, 5)
			_draw_text(ix + 9, iy + 1, short_name, COL_LABEL)
			# Draw stack count below the name text
			var stack_count: int = item.get("count", 1)
			if stack_count > 1:
				var count_str: String = "x" + str(stack_count)
				_draw_text(ix + 9, iy + 7, count_str, COL_GOLD)

	# ── Scroll arrows ──────────────────────────────────────────
	_draw_scroll_arrows()

	# ── Effects preview ─────────────────────────────────────────
	var recipe: Dictionary = _build_recipe()
	var preview: String = str(recipe["room_count"]) + " ROOMS"
	for etype in recipe["enemy_types"]:
		preview += "  " + etype.to_upper()
	if recipe["gold_multiplier"] > 1.0:
		preview += "  +GOLD"
	if recipe["enemy_hp_bonus"] > 0:
		preview += "  +HP"
	if recipe["loot_bonus"]:
		preview += "  +LOOT"
	if recipe["has_boss"]:
		preview += "  BOSS"
	_draw_text(PANEL_X + 8, PREVIEW_Y, preview, COL_INGR)

	# ── Enter Dungeon button ────────────────────────────────────
	var has_enemies: bool = not recipe["enemy_types"].is_empty()
	var btn_bg: Color = COL_BTN_OK if has_enemies else COL_BTN_DIM
	var btn_border: Color = COL_BTN_BRD if has_enemies else COL_DIM
	var btn_text_col: Color = COL_TITLE if has_enemies else COL_DIM
	_canvas.draw_rect(Rect2(BTN_X, BTN_Y, BTN_W, BTN_H), btn_bg)
	_draw_border(BTN_X, BTN_Y, BTN_W, BTN_H, btn_border)
	_draw_text(BTN_X + 6, BTN_Y + 3, "ENTER", btn_text_col)

	# ── Close button ────────────────────────────────────────────
	_canvas.draw_rect(Rect2(CLOSE_X, CLOSE_Y, CLOSE_W, CLOSE_H), COL_SLOT)
	_draw_border(CLOSE_X, CLOSE_Y, CLOSE_W, CLOSE_H, COL_BORDER)
	_draw_text(CLOSE_X + 4, CLOSE_Y + 3, "BACK", COL_LABEL)

	# ── Flash message ───────────────────────────────────────────
	if _flash_timer > 0 and _flash_msg != "":
		var fx: int = PANEL_X + PANEL_W / 2 - _flash_msg.length() * 2
		_draw_text(fx, PREVIEW_Y + 8, _flash_msg, _flash_col)


# ── Drawing helpers ─────────────────────────────────────────────

func _draw_border(x: int, y: int, w: int, h: int, col: Color) -> void:
	_canvas.draw_rect(Rect2(x, y, w, 1), col)
	_canvas.draw_rect(Rect2(x, y + h - 1, w, 1), col)
	_canvas.draw_rect(Rect2(x, y, 1, h), col)
	_canvas.draw_rect(Rect2(x + w - 1, y, 1, h), col)


func _draw_text(x: int, y: int, text: String, col: Color) -> void:
	var cx: int = x
	for ch in text:
		if LETTERS.has(ch):
			var glyph: Array = LETTERS[ch]
			for row in range(glyph.size()):
				for col_idx in range(glyph[row].size()):
					if glyph[row][col_idx] == 1:
						_canvas.draw_rect(Rect2(cx + col_idx, y + row, 1, 1), col)
		cx += 4


## Returns the maximum scroll offset (0 = no scrolling needed).
func _max_scroll() -> int:
	var total_rows: int = ceili(float(_get_bag_ingredients().size()) / BAG_COLS)
	return maxi(0, total_rows - BAG_ROWS)


func _rect_scroll_up() -> Rect2:
	return Rect2(SCROLL_X, BAG_Y, SCROLL_ARROW_W, SCROLL_ARROW_H)


func _rect_scroll_down() -> Rect2:
	var bag_bottom: int = BAG_Y + BAG_ROWS * (BAG_SLOT_H + BAG_GAP) - SCROLL_ARROW_H
	return Rect2(SCROLL_X, bag_bottom, SCROLL_ARROW_W, SCROLL_ARROW_H)


## Draws small triangle arrows on the right side of the bag grid.
## Bright when scrollable, dim when at the limit — gives the player
## a visual hint that there's more to see!
func _draw_scroll_arrows() -> void:
	var can_up: bool   = _bag_scroll > 0
	var can_down: bool = _bag_scroll < _max_scroll()
	var col_up: Color   = COL_SLOT_HLT if can_up   else COL_DIM
	var col_down: Color = COL_SLOT_HLT if can_down else COL_DIM

	# Up arrow (small triangle pointing up)
	var up_r: Rect2 = _rect_scroll_up()
	var ux: int = int(up_r.position.x)
	var uy: int = int(up_r.position.y)
	_canvas.draw_rect(Rect2(ux + 3, uy,     1, 1), col_up)
	_canvas.draw_rect(Rect2(ux + 2, uy + 1, 3, 1), col_up)
	_canvas.draw_rect(Rect2(ux + 1, uy + 2, 5, 1), col_up)
	_canvas.draw_rect(Rect2(ux,     uy + 3, 7, 1), col_up)

	# Down arrow (small triangle pointing down)
	var dn_r: Rect2 = _rect_scroll_down()
	var dx: int = int(dn_r.position.x)
	var dy: int = int(dn_r.position.y)
	_canvas.draw_rect(Rect2(dx,     dy,     7, 1), col_down)
	_canvas.draw_rect(Rect2(dx + 1, dy + 1, 5, 1), col_down)
	_canvas.draw_rect(Rect2(dx + 2, dy + 2, 3, 1), col_down)
	_canvas.draw_rect(Rect2(dx + 3, dy + 3, 1, 1), col_down)


func _format_gold(amount: int) -> String:
	var s: String = str(amount)
	if amount >= 1000:
		var left: String = s.substr(0, s.length() - 3)
		var right: String = s.substr(s.length() - 3)
		return left + "," + right
	return s
