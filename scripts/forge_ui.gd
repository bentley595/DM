extends CanvasLayer
## Forge overlay — level up your equipped items with gold.
##
## Shows the 3 equipped items (melee, ranged, armor) with their
## current stats, a preview of the next level's stats, and the
## upgrade cost.  Click "UPGRADE" to spend gold and increase
## an item's level.
##
## Key concept: **stat preview**.
## Before upgrading, the player can see EXACTLY what will change:
##   Sword LVL 1: DPA 5  →  LVL 2: DPA 6  (Cost: 20G)
## This removes guesswork and helps players make informed decisions!
##
## Cost formula: level × 20 gold
##   Level 1→2: 20G    Level 5→6: 100G    Level 10→11: 200G

const WeaponData = preload("res://scripts/weapon_data.gd")
const ArmorData  = preload("res://scripts/armor_data.gd")

# ── Layout ──────────────────────────────────────────────────────
const PANEL_X: int = 60
const PANEL_Y: int = 25
const PANEL_W: int = 200
const PANEL_H: int = 130

# Slot layout (3 rows, one per equipment type)
const SLOT_X: int = PANEL_X + 8
const SLOT_START_Y: int = PANEL_Y + 22
const SLOT_W: int = 184
const SLOT_H: int = 30
const SLOT_GAP: int = 4

# Upgrade button (inside each slot, right side)
const BTN_W: int = 36
const BTN_H: int = 12

# ── Colors ──────────────────────────────────────────────────────
const COL_BG       := Color(0, 0, 0, 0.72)
const COL_PANEL    := Color(0.06, 0.06, 0.14, 1.0)
const COL_BORDER   := Color(0.55, 0.55, 0.75, 1.0)
const COL_SLOT     := Color(0.12, 0.12, 0.22, 1.0)
const COL_SLOT_HLT := Color(0.9, 0.75, 0.3, 1.0)
const COL_TITLE    := Color(1.0, 1.0, 1.0, 1.0)
const COL_LABEL    := Color(0.75, 0.75, 0.85, 1.0)
const COL_GOLD     := Color(0.9, 0.75, 0.3, 1.0)
const COL_GREEN    := Color(0.3, 0.85, 0.3, 1.0)
const COL_DIM      := Color(0.4, 0.4, 0.4, 1.0)
const COL_ICON     := Color(0.8, 0.75, 0.3, 1.0)
const COL_BTN_OK   := Color(0.15, 0.35, 0.15, 1.0)
const COL_BTN_BORDER := Color(0.3, 0.7, 0.3, 1.0)

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
	"Q": [[0,1,0],[1,0,1],[1,0,1],[1,1,1],[0,0,1]],
	"R": [[1,1,0],[1,0,1],[1,1,0],[1,0,1],[1,0,1]],
	"S": [[0,1,1],[1,0,0],[0,1,0],[0,0,1],[1,1,0]],
	"T": [[1,1,1],[0,1,0],[0,1,0],[0,1,0],[0,1,0]],
	"U": [[1,0,1],[1,0,1],[1,0,1],[1,0,1],[0,1,0]],
	"V": [[1,0,1],[1,0,1],[1,0,1],[0,1,0],[0,1,0]],
	"W": [[1,0,1],[1,0,1],[1,1,1],[1,1,1],[1,0,1]],
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
var _canvas: Node2D
var _upgrade_flash: int = -1    # which slot just got upgraded (0/1/2), -1=none
var _flash_timer: float = 0.0

## The 3 equip slots in order.
const SLOTS: Array = ["melee", "ranged", "armor"]


func _ready() -> void:
	layer = 10
	visible = false
	_canvas = Node2D.new()
	_canvas.draw.connect(_on_draw)
	add_child(_canvas)


func open(inv: Dictionary, gold: int) -> void:
	_inventory = inv
	_gold = gold
	_upgrade_flash = -1
	is_open = true
	visible = true
	_canvas.queue_redraw()


func close() -> void:
	is_open = false
	visible = false


func _process(delta: float) -> void:
	if _flash_timer > 0:
		_flash_timer -= delta
		if _flash_timer <= 0:
			_upgrade_flash = -1
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
	for i in SLOTS.size():
		var btn_rect: Rect2 = _rect_upgrade_btn(i)
		if btn_rect.has_point(mp):
			_try_upgrade(i)
			return


func _try_upgrade(slot_index: int) -> void:
	var slot_name: String = SLOTS[slot_index]
	var item: Dictionary = _inventory.get(slot_name, {})
	if item.is_empty():
		return

	var level: int = item.get("level", 1)
	var cost: int = level * 20

	if _gold < cost:
		return

	# Deduct gold and increase level
	_gold -= cost
	item["level"] = level + 1
	_inventory[slot_name] = item
	get_tree().set_meta("player_gold", _gold)

	# Update HUD
	var camp: Node = get_parent()
	if camp.has_node("HUD"):
		camp.get_node("HUD").update_gold(_gold)

	# Visual feedback
	_upgrade_flash = slot_index
	_flash_timer = 0.3
	_canvas.queue_redraw()


func _rect_upgrade_btn(slot_index: int) -> Rect2:
	var y: int = SLOT_START_Y + slot_index * (SLOT_H + SLOT_GAP)
	return Rect2(SLOT_X + SLOT_W - BTN_W - 4, y + 14, BTN_W, BTN_H)


func _get_item_data(id: String) -> Dictionary:
	if WeaponData.WEAPONS.has(id):
		return WeaponData.WEAPONS[id]
	if ArmorData.ARMOR.has(id):
		return ArmorData.ARMOR[id]
	return {}


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
	_draw_text(PANEL_X + 4, PANEL_Y + 4, "FORGE", COL_TITLE)
	var gold_text: String = str(_gold) + "G"
	var gold_x: int = PANEL_X + PANEL_W - 4 - gold_text.length() * 4
	_draw_text(gold_x, PANEL_Y + 4, gold_text, COL_GOLD)

	# Subtitle
	_draw_text(PANEL_X + 4, PANEL_Y + 13, "UPGRADE EQUIPPED ITEMS", COL_LABEL)

	# Draw 3 equipment slots
	for i in SLOTS.size():
		_draw_slot(i, mp)


func _draw_slot(slot_index: int, mp: Vector2) -> void:
	var slot_name: String = SLOTS[slot_index]
	var item: Dictionary = _inventory.get(slot_name, {})
	var y: int = SLOT_START_Y + slot_index * (SLOT_H + SLOT_GAP)

	# Slot background
	_canvas.draw_rect(Rect2(SLOT_X, y, SLOT_W, SLOT_H), COL_SLOT)
	var border_col: Color = COL_SLOT_HLT if _upgrade_flash == slot_index else COL_BORDER
	_draw_border(SLOT_X, y, SLOT_W, SLOT_H, border_col)

	# Slot label
	_draw_text(SLOT_X + 3, y + 3, slot_name.to_upper(), COL_LABEL)

	if item.is_empty():
		_draw_text(SLOT_X + 3, y + 13, "NO ITEM EQUIPPED", COL_DIM)
		return

	var data: Dictionary = _get_item_data(item.get("id", ""))
	if data.is_empty():
		return

	var level: int = item.get("level", 1)
	var cost: int = level * 20
	var can_afford: bool = _gold >= cost

	# Item icon
	var icon: Array = data.get("icon", [])
	var ix: int = SLOT_X + 3
	var iy: int = y + 12
	for row in range(icon.size()):
		for col in range(icon[row].size()):
			if icon[row][col] == 1:
				_canvas.draw_rect(Rect2(ix + col, iy + row, 1, 1), COL_ICON)

	# Item name + level
	var name_text: String = data.get("name", "").to_upper()
	_draw_text(ix + 9, iy + 1, name_text, COL_TITLE)

	# Current stat → next stat
	var stat_text: String = ""
	if data.get("type", "") == "armor":
		var cur_def: int = data.get("defense", 0) + level - 1
		var next_def: int = cur_def + 1
		stat_text = "DEF " + str(cur_def)
		_draw_text(ix + 9, iy + 9, stat_text, COL_GOLD)
		_draw_text(ix + 9 + stat_text.length() * 4 + 4, iy + 9, str(next_def), COL_GREEN)
	else:
		var cur_dpa: int = data.get("damage", 0) + level - 1
		var next_dpa: int = cur_dpa + 1
		stat_text = "DPA " + str(cur_dpa)
		_draw_text(ix + 9, iy + 9, stat_text, COL_GOLD)
		_draw_text(ix + 9 + stat_text.length() * 4 + 4, iy + 9, str(next_dpa), COL_GREEN)

	# Level display
	var lvl_text: String = "LVL " + str(level)
	_draw_text(SLOT_X + SLOT_W - 60, y + 3, lvl_text, COL_GOLD)

	# Upgrade button
	var btn_r: Rect2 = _rect_upgrade_btn(slot_index)
	var btn_bg: Color = COL_BTN_OK if can_afford else Color(0.15, 0.15, 0.15, 1.0)
	var btn_border: Color = COL_BTN_BORDER if can_afford else Color(0.3, 0.3, 0.3, 1.0)
	var btn_text_col: Color = COL_TITLE if can_afford else COL_DIM

	# Hover effect
	if btn_r.has_point(mp) and can_afford:
		btn_bg = Color(0.2, 0.45, 0.2, 1.0)

	_canvas.draw_rect(btn_r, btn_bg)
	_draw_border(int(btn_r.position.x), int(btn_r.position.y),
		int(btn_r.size.x), int(btn_r.size.y), btn_border)

	var cost_label: String = str(cost) + "G"
	_draw_text(int(btn_r.position.x) + 3, int(btn_r.position.y) + 3, cost_label, btn_text_col)

	# Flash effect on upgrade
	if _upgrade_flash == slot_index and _flash_timer > 0:
		var flash_alpha: float = _flash_timer / 0.3 * 0.25
		_canvas.draw_rect(Rect2(SLOT_X, y, SLOT_W, SLOT_H),
			Color(0.3, 0.85, 0.3, flash_alpha))


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
