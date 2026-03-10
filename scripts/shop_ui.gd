extends CanvasLayer
## Weapon Shop overlay — buy new weapons and armor with gold.
##
## Follows the same CanvasLayer overlay pattern as inventory_screen.gd:
## - Opens on top of the game world (layer 10)
## - Uses _draw() for all pixel-art rendering
## - Filter tabs to browse by item type
## - Click an item to buy it (adds to inventory bag at Level 1)
##
## Key concept: **reusing existing patterns**.
## This script copies the tab system, click detection, and drawing
## helpers directly from inventory_screen.gd.  When you find a pattern
## that works well, use it again!  Consistency makes code easier to
## understand and maintain.

const WeaponData     = preload("res://scripts/weapon_data.gd")
const ArmorData      = preload("res://scripts/armor_data.gd")
const ShopData       = preload("res://scripts/shop_data.gd")
const IngredientData = preload("res://scripts/ingredient_data.gd")

# ── Layout ──────────────────────────────────────────────────────
const PANEL_X: int = 50
const PANEL_Y: int = 25
const PANEL_W: int = 220
const PANEL_H: int = 130

# Item grid
const GRID_X: int = PANEL_X + 8
const GRID_Y: int = PANEL_Y + 30
const ITEM_W: int = 48
const ITEM_H: int = 24
const GRID_COLS: int = 4
const GRID_ROWS: int = 3
const ITEM_GAP: int = 2

# Filter tabs
const TAB_Y: int = PANEL_Y + 16
const TAB_DEFS: Array = [
	{"id": "all",        "label": "ALL",    "w": 16},
	{"id": "melee",      "label": "MELEE",  "w": 24},
	{"id": "ranged",     "label": "RANGED", "w": 28},
	{"id": "armor",      "label": "ARMOR",  "w": 24},
	{"id": "ingredient", "label": "INGR",   "w": 20},
]

# Info/buy panel (at the bottom)
const INFO_Y: int = PANEL_Y + PANEL_H - 22
const INFO_H: int = 18

# ── Colors ──────────────────────────────────────────────────────
const COL_BG       := Color(0, 0, 0, 0.72)
const COL_PANEL    := Color(0.06, 0.06, 0.14, 1.0)
const COL_BORDER   := Color(0.55, 0.55, 0.75, 1.0)
const COL_SLOT     := Color(0.12, 0.12, 0.22, 1.0)
const COL_SLOT_HLT := Color(0.9, 0.75, 0.3, 1.0)
const COL_TITLE    := Color(1.0, 1.0, 1.0, 1.0)
const COL_LABEL    := Color(0.75, 0.75, 0.85, 1.0)
const COL_GOLD     := Color(0.9, 0.75, 0.3, 1.0)
const COL_DIM      := Color(0.4, 0.4, 0.4, 1.0)
const COL_ICON     := Color(0.8, 0.75, 0.3, 1.0)
const COL_INGR     := Color(0.4, 0.8, 0.5, 1.0)    # green — ingredient icons
const COL_BUY_OK   := Color(0.15, 0.35, 0.15, 1.0)
const COL_BUY_BORDER := Color(0.3, 0.7, 0.3, 1.0)

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
}

# ── State ───────────────────────────────────────────────────────
var is_open: bool = false
var _inventory: Dictionary = {}
var _gold: int = 0
var _filter: String = "all"
var _scroll: int = 0
var _selected_idx: int = -1   # index in filtered list, -1 = nothing selected
var _canvas: Node2D
var _buy_flash_timer: float = 0.0  # brief green flash on successful buy


func _ready() -> void:
	layer = 10
	visible = false
	_canvas = Node2D.new()
	_canvas.draw.connect(_on_draw)
	add_child(_canvas)


func open(inv: Dictionary, gold: int) -> void:
	_inventory = inv
	_gold = gold
	_filter = "all"
	_scroll = 0
	_selected_idx = -1
	is_open = true
	visible = true
	_canvas.queue_redraw()


func close() -> void:
	is_open = false
	visible = false
	_selected_idx = -1


func _process(delta: float) -> void:
	if _buy_flash_timer > 0:
		_buy_flash_timer -= delta
		if _buy_flash_timer <= 0:
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
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mp: Vector2 = get_viewport().get_mouse_position()
			_handle_click(mp)

	if event is InputEventMouseMotion:
		_canvas.queue_redraw()


func _handle_click(mp: Vector2) -> void:
	# Check filter tabs
	var tab_id: String = _tab_at(mp)
	if tab_id != "":
		_filter = tab_id
		_scroll = 0
		_selected_idx = -1
		_canvas.queue_redraw()
		return

	# Check item grid
	var filtered: Array = _filtered_items()
	var visible_start: int = _scroll * GRID_COLS
	for vi in range(GRID_COLS * GRID_ROWS):
		var fi: int = visible_start + vi
		if fi >= filtered.size():
			break
		if _rect_item(vi).has_point(mp):
			if _selected_idx == fi:
				# Already selected — try to buy
				_try_buy(filtered[fi])
			else:
				_selected_idx = fi
			_canvas.queue_redraw()
			return

	# Check buy button (if item selected)
	if _selected_idx >= 0 and _selected_idx < filtered.size():
		if _rect_buy_btn().has_point(mp):
			_try_buy(filtered[_selected_idx])
			return

	# Clicked elsewhere — deselect
	_selected_idx = -1
	_canvas.queue_redraw()


func _try_buy(shop_item: Dictionary) -> void:
	var price: int = shop_item.get("price", 0)
	if _gold < price:
		return  # Can't afford

	# Deduct gold
	_gold -= price
	get_tree().set_meta("player_gold", _gold)

	# Add item to inventory bag at Level 1
	# Ingredients stack automatically via add_to_bag!
	var item_id: String = shop_item["id"]
	if IngredientData.INGREDIENTS.has(item_id):
		IngredientData.add_to_bag(_inventory["bag"], item_id)
	else:
		_inventory["bag"].append({"id": item_id, "level": 1})

	# Update the camp HUD
	var camp: Node = get_parent()
	if camp.has_node("HUD"):
		camp.get_node("HUD").update_gold(_gold)

	# Visual feedback — brief flash
	_buy_flash_timer = 0.3
	_canvas.queue_redraw()


func _filtered_items() -> Array:
	var result: Array = []
	for item in ShopData.SHOP_ITEMS:
		if _filter == "all":
			result.append(item)
		else:
			var data: Dictionary = _get_item_data(item["id"])
			if data.get("type", "") == _filter:
				result.append(item)
	return result


func _get_item_data(id: String) -> Dictionary:
	if WeaponData.WEAPONS.has(id):
		return WeaponData.WEAPONS[id]
	if ArmorData.ARMOR.has(id):
		return ArmorData.ARMOR[id]
	if IngredientData.INGREDIENTS.has(id):
		return IngredientData.INGREDIENTS[id]
	return {}


func _rect_item(visual_i: int) -> Rect2:
	var col: int = visual_i % GRID_COLS
	var row: int = visual_i / GRID_COLS
	return Rect2(
		GRID_X + col * (ITEM_W + ITEM_GAP),
		GRID_Y + row * (ITEM_H + ITEM_GAP),
		ITEM_W, ITEM_H
	)


func _rect_buy_btn() -> Rect2:
	return Rect2(PANEL_X + PANEL_W - 48, INFO_Y + 2, 40, 14)


func _tab_at(mp: Vector2) -> String:
	var x: int = GRID_X
	for tab in TAB_DEFS:
		var r := Rect2(x, TAB_Y, tab.w, 9)
		if r.has_point(mp):
			return tab.id
		x += tab.w + 2
	return ""


# ── Drawing ─────────────────────────────────────────────────────

func _on_draw() -> void:
	if not is_open:
		return

	var mp: Vector2 = get_viewport().get_mouse_position()

	# Background
	_canvas.draw_rect(Rect2(0, 0, 320, 180), COL_BG)

	# Panel
	_canvas.draw_rect(Rect2(PANEL_X, PANEL_Y, PANEL_W, PANEL_H), COL_PANEL)
	_draw_border(PANEL_X, PANEL_Y, PANEL_W, PANEL_H, COL_BORDER)

	# Title + gold
	_draw_text(PANEL_X + 4, PANEL_Y + 4, "WEAPON SHOP", COL_TITLE)
	var gold_text: String = str(_gold) + "G"
	var gold_x: int = PANEL_X + PANEL_W - 4 - gold_text.length() * 4
	_draw_text(gold_x, PANEL_Y + 4, gold_text, COL_GOLD)

	# Filter tabs
	_draw_tabs()

	# Item grid
	var filtered: Array = _filtered_items()
	var visible_start: int = _scroll * GRID_COLS
	for vi in range(GRID_COLS * GRID_ROWS):
		var fi: int = visible_start + vi
		var r: Rect2 = _rect_item(vi)
		if fi < filtered.size():
			_draw_shop_item(r, filtered[fi], fi == _selected_idx, mp)
		else:
			# Empty slot
			_canvas.draw_rect(r, COL_SLOT)
			_draw_border(int(r.position.x), int(r.position.y), int(r.size.x), int(r.size.y), COL_BORDER)

	# Info panel for selected item
	if _selected_idx >= 0 and _selected_idx < filtered.size():
		_draw_info(filtered[_selected_idx])

	# Buy flash effect
	if _buy_flash_timer > 0:
		var flash_alpha: float = _buy_flash_timer / 0.3 * 0.3
		_canvas.draw_rect(Rect2(PANEL_X, PANEL_Y, PANEL_W, PANEL_H),
			Color(0.2, 0.8, 0.2, flash_alpha))


func _draw_shop_item(r: Rect2, shop_item: Dictionary, selected: bool, mp: Vector2) -> void:
	var data: Dictionary = _get_item_data(shop_item["id"])
	var price: int = shop_item.get("price", 0)
	var can_afford: bool = _gold >= price
	var is_hovered: bool = r.has_point(mp)

	# Slot background
	_canvas.draw_rect(r, COL_SLOT)

	# Border color: gold if selected, bright if hovered, normal otherwise
	var border: Color = COL_BORDER
	if selected:
		border = COL_SLOT_HLT
	elif is_hovered:
		border = Color(0.7, 0.7, 0.85, 1.0)
	_draw_border(int(r.position.x), int(r.position.y), int(r.size.x), int(r.size.y), border)

	# Item icon (7×7) — ingredients draw green, weapons/armor draw gold
	var icon: Array = data.get("icon", [])
	var base_icon_col: Color = COL_INGR if data.get("type", "") == "ingredient" else COL_ICON
	var icon_color: Color = base_icon_col if can_afford else COL_DIM
	var ix: int = int(r.position.x) + 2
	var iy: int = int(r.position.y) + 2
	for row in range(icon.size()):
		for col in range(icon[row].size()):
			if icon[row][col] == 1:
				_canvas.draw_rect(Rect2(ix + col, iy + row, 1, 1), icon_color)

	# Item name
	var name_text: String = data.get("name", "").to_upper()
	var text_color: Color = COL_TITLE if can_afford else COL_DIM
	_draw_text(ix + 9, iy + 1, name_text, text_color)

	# Price
	var price_text: String = str(price) + "G"
	var price_color: Color = COL_GOLD if can_afford else COL_DIM
	_draw_text(ix + 9, iy + 9, price_text, price_color)


func _draw_info(shop_item: Dictionary) -> void:
	var data: Dictionary = _get_item_data(shop_item["id"])
	var price: int = shop_item.get("price", 0)
	var can_afford: bool = _gold >= price

	# Info background
	_canvas.draw_rect(Rect2(PANEL_X + 4, INFO_Y, PANEL_W - 8, INFO_H), COL_SLOT)
	_draw_border(PANEL_X + 4, INFO_Y, PANEL_W - 8, INFO_H, COL_SLOT_HLT)

	# Stats
	var lx: int = PANEL_X + 8
	if data.get("type", "") == "armor":
		_draw_text(lx, INFO_Y + 3, "DEF " + str(data.get("defense", 0)), COL_GOLD)
	else:
		var dpa: int = data.get("damage", 0)
		var dps: int = roundi(float(dpa) / data.get("cooldown", 1.0))
		_draw_text(lx, INFO_Y + 3, "DPA " + str(dpa), COL_GOLD)
		_draw_text(lx + 32, INFO_Y + 3, "DPS " + str(dps), COL_GOLD)

	_draw_text(lx, INFO_Y + 10, "LVL 1", COL_LABEL)

	# Buy button
	var btn_r: Rect2 = _rect_buy_btn()
	var btn_bg: Color = COL_BUY_OK if can_afford else Color(0.15, 0.15, 0.15, 1.0)
	var btn_border: Color = COL_BUY_BORDER if can_afford else Color(0.3, 0.3, 0.3, 1.0)
	var btn_text: Color = COL_TITLE if can_afford else COL_DIM
	_canvas.draw_rect(btn_r, btn_bg)
	_draw_border(int(btn_r.position.x), int(btn_r.position.y),
		int(btn_r.size.x), int(btn_r.size.y), btn_border)
	_draw_text(int(btn_r.position.x) + 8, int(btn_r.position.y) + 4, "BUY", btn_text)


func _draw_tabs() -> void:
	var x: int = GRID_X
	for tab in TAB_DEFS:
		var is_active: bool = (_filter == tab.id)
		var bg: Color     = Color(0.18, 0.18, 0.32, 1.0) if is_active else COL_SLOT
		var border: Color = COL_SLOT_HLT if is_active else COL_BORDER
		var text: Color   = COL_TITLE    if is_active else COL_LABEL
		_canvas.draw_rect(Rect2(x, TAB_Y, tab.w, 9), bg)
		_draw_border(x, TAB_Y, tab.w, 9, border)
		_draw_text(x + 2, TAB_Y + 2, tab.label, text)
		x += tab.w + 2


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
