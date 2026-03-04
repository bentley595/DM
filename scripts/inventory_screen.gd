extends CanvasLayer
## Inventory overlay — press I to open, click items to see stats, drag to equip.
##
## HOW ITEMS ARE STORED:
## Every item is a small Dictionary: {"id": "sword", "level": 1}
## This lets two different-level swords coexist in the bag — a Level 1 Sword from
## the start and a Level 3 Sword found deep in the dungeon are different objects!
## Empty equip slots are represented as {} (empty dict).
##
## HOW DRAG-AND-DROP WORKS:
## We use a "deferred drag" approach:
##   1. Mouse DOWN → record the item as "_pending" (it stays in its slot)
##   2. Mouse MOVES > 4px → COMMIT to a drag (item leaves its slot, follows cursor)
##   3. Mouse UP without moving → it was a CLICK (show item stats in info panel)
## This gives you BOTH click-to-inspect AND drag-to-equip from the same button!

const WeaponData = preload("res://scripts/weapon_data.gd")
const ArmorData  = preload("res://scripts/armor_data.gd")

signal weapon_equipped(slot: String, item: Dictionary)
signal weapon_unequipped(slot: String)
signal inventory_closed

# ── Layout constants ──────────────────────────────────────────────────────────
const PANEL_X: int = 60
const PANEL_Y: int = 30
const PANEL_W: int = 200
const PANEL_H: int = 118

# Equipment slots (inside the panel)
const EQUIP_X: int = PANEL_X + 8
const EQUIP_MELEE_Y:  int = PANEL_Y + 28
const EQUIP_RANGED_Y: int = PANEL_Y + 58
const EQUIP_ARMOR_Y:  int = PANEL_Y + 88
const SLOT_W: int = 60
const SLOT_H: int = 22

# Bag grid (right side of panel)
const BAG_X: int = PANEL_X + 82
const BAG_Y: int = PANEL_Y + 28
const BAG_SLOT_W: int = 24
const BAG_SLOT_H: int = 24
const BAG_COLS: int = 4
const BAG_ROWS: int = 2
const BAG_GAP: int = 2

# Colors
const COL_BG       := Color(0, 0, 0, 0.72)
const COL_PANEL    := Color(0.06, 0.06, 0.14, 1.0)
const COL_BORDER   := Color(0.55, 0.55, 0.75, 1.0)
const COL_SLOT     := Color(0.12, 0.12, 0.22, 1.0)
const COL_SLOT_HLT := Color(0.9, 0.75, 0.3, 1.0)    # gold highlight = valid drop / selected
const COL_SLOT_BAD := Color(0.7, 0.2, 0.2, 1.0)      # red = wrong type
const COL_WEAPON   := Color(0.8, 0.75, 0.3, 1.0)     # icon fill / gold text
const COL_LABEL    := Color(0.75, 0.75, 0.85, 1.0)
const COL_TITLE    := Color(1.0, 1.0, 1.0, 1.0)
const COL_DIVIDER  := Color(0.3, 0.3, 0.5, 1.0)

# Scroll arrows (to the right of the bag grid)
const SCROLL_X: int = BAG_X + BAG_COLS * (BAG_SLOT_W + BAG_GAP) + 3
const SCROLL_ARROW_W: int = 7
const SCROLL_ARROW_H: int = 5

# Filter tabs (sit above the bag grid)
const TAB_Y: int = BAG_Y - 11
const TAB_H: int = 9
const TAB_DEFS: Array = [
	{"id": "all",    "label": "ALL",    "w": 16},
	{"id": "melee",  "label": "MELEE",  "w": 24},
	{"id": "ranged", "label": "RANGED", "w": 28},
	{"id": "armor",  "label": "ARMOR",  "w": 24},
]

# Item info panel (shown below the bag when an item is clicked)
const INFO_X: int = BAG_X
const INFO_Y: int = BAG_Y + BAG_ROWS * (BAG_SLOT_H + BAG_GAP) + 4   # = 114
const INFO_W: int = 106
const INFO_H: int = 26

# How many pixels the mouse must move while held before we commit to a drag.
# Below this distance, releasing the mouse counts as a "click" (show item info).
const DRAG_THRESHOLD: float = 4.0

# ── State ─────────────────────────────────────────────────────────────────────
var is_open: bool = false
var _inventory: Dictionary = {}

## The item being actively dragged. {} means nothing is being dragged.
var _dragging: Dictionary = {}
var _drag_from: String = ""
var _drag_pos: Vector2 = Vector2.ZERO

## "Pending" item: set on mouse-down, before we decide if it's a drag or click.
## The item stays in its slot until _pending_pos moves beyond DRAG_THRESHOLD.
var _pending_item: Dictionary = {}
var _pending_from: String = ""
var _pending_pos: Vector2 = Vector2.ZERO

## The item whose stats are shown in the info panel. {} = no panel shown.
var _info_item: Dictionary = {}

var _bag_scroll: int = 0
var _bag_filter: String = "all"
var _canvas: Node2D


## Tiny 3×5 bitmap font for labels.
## Each letter is a 5-row × 3-column array. 1=draw pixel, 0=skip.
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
	"X": [[1,0,1],[1,0,1],[0,1,0],[1,0,1],[1,0,1]],
	"Y": [[1,0,1],[1,0,1],[0,1,0],[0,1,0],[0,1,0]],
	"Z": [[1,1,1],[0,0,1],[0,1,0],[1,0,0],[1,1,1]],
	" ": [[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0]],
	"(": [[0,1,0],[1,0,0],[1,0,0],[1,0,0],[0,1,0]],
	")": [[0,1,0],[0,0,1],[0,0,1],[0,0,1],[0,1,0]],
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


func _ready() -> void:
	layer = 10
	visible = false
	_canvas = Node2D.new()
	_canvas.draw.connect(_on_draw)
	add_child(_canvas)


func open(inv: Dictionary) -> void:
	_inventory = inv
	is_open = true
	visible = true
	_bag_scroll = 0
	_bag_filter = "all"
	_pending_item = {}
	_info_item = {}
	_canvas.queue_redraw()


func close() -> void:
	is_open = false
	visible = false
	_dragging = {}
	_pending_item = {}
	_info_item = {}
	emit_signal("inventory_closed")


func _input(event: InputEvent) -> void:
	if not is_open:
		return

	get_viewport().set_input_as_handled()

	if event is InputEventKey and event.is_pressed():
		if event.physical_keycode == KEY_ESCAPE or event.physical_keycode == KEY_I:
			close()
			return

	if event is InputEventMouseButton:
		var mp: Vector2 = get_viewport().get_mouse_position()

		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_bag_scroll = maxi(_bag_scroll - 1, 0)
			_canvas.queue_redraw()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_bag_scroll = mini(_bag_scroll + 1, _max_scroll())
			_canvas.queue_redraw()

		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var tab_id: String = _tab_at(mp)
				if tab_id != "":
					_bag_filter = tab_id
					_bag_scroll = 0
					_canvas.queue_redraw()
					return
				if _rect_scroll_up().has_point(mp):
					_bag_scroll = maxi(_bag_scroll - 1, 0)
					_canvas.queue_redraw()
				elif _rect_scroll_down().has_point(mp):
					_bag_scroll = mini(_bag_scroll + 1, _max_scroll())
					_canvas.queue_redraw()
				else:
					_try_pickup(mp)
			else:
				# Mouse released — decide: was it a drag, a click, or nothing?
				if not _dragging.is_empty():
					_handle_mouse_up(mp)
				elif not _pending_item.is_empty():
					# Short click (mouse barely moved) → toggle the info panel
					if _info_item == _pending_item:
						_info_item = {}     # clicking the same item again hides the panel
					else:
						_info_item = _pending_item
					_pending_item = {}
					_canvas.queue_redraw()
				else:
					# Released on empty space — hide the info panel
					_info_item = {}
					_canvas.queue_redraw()

	if event is InputEventMouseMotion:
		var cur: Vector2 = get_viewport().get_mouse_position()
		if not _dragging.is_empty():
			# Already dragging — update the floating icon position
			_drag_pos = cur
			_canvas.queue_redraw()
		elif not _pending_item.is_empty():
			# Holding an item but haven't decided yet — check drag threshold
			if (cur - _pending_pos).length() > DRAG_THRESHOLD:
				# Moved enough → commit to a drag
				_remove_from_source(_pending_from)
				_start_drag(_pending_item, _pending_from, cur)
				_pending_item = {}
				_info_item = {}


func _try_pickup(mp: Vector2) -> void:
	## Records a potential item pickup on mouse-press.
	## The item stays visible in its slot until we know if this is a click or a drag.
	if _rect_melee_slot().has_point(mp) and not _inventory.get("melee", {}).is_empty():
		_pending_item = _inventory["melee"]
		_pending_from = "melee"
		_pending_pos  = mp
		return

	if _rect_ranged_slot().has_point(mp) and not _inventory.get("ranged", {}).is_empty():
		_pending_item = _inventory["ranged"]
		_pending_from = "ranged"
		_pending_pos  = mp
		return

	if _rect_armor_slot().has_point(mp) and not _inventory.get("armor", {}).is_empty():
		_pending_item = _inventory["armor"]
		_pending_from = "armor"
		_pending_pos  = mp
		return

	var filtered: Array = _filtered_bag()
	var visible_start: int = _bag_scroll * BAG_COLS
	for visual_i in range(BAG_COLS * BAG_ROWS):
		var fi: int = visible_start + visual_i
		if fi >= filtered.size():
			break
		if _rect_bag_slot(visual_i).has_point(mp):
			var entry: Dictionary = filtered[fi]
			_pending_item = entry.item
			_pending_from = "bag:%d" % entry.actual_i
			_pending_pos  = mp
			return

	# Clicked on empty area — close the info panel
	_info_item = {}
	_canvas.queue_redraw()


func _remove_from_source(from: String) -> void:
	## Removes the pending item from its source slot. Called when drag is confirmed.
	## Key concept: we separate "picking up" (deciding) from "removing" (committing).
	## This is what makes the deferred drag work — the item only leaves its slot
	## once we're sure the player is actually dragging, not just clicking!
	if from == "melee":
		_inventory["melee"] = {}
		emit_signal("weapon_unequipped", "melee")
	elif from == "ranged":
		_inventory["ranged"] = {}
		emit_signal("weapon_unequipped", "ranged")
	elif from == "armor":
		_inventory["armor"] = {}
		emit_signal("weapon_unequipped", "armor")
	elif from.begins_with("bag:"):
		var idx: int = int(from.split(":")[1])
		_inventory["bag"].remove_at(idx)


func _start_drag(item: Dictionary, from: String, mp: Vector2) -> void:
	_dragging  = item
	_drag_from = from
	_drag_pos  = mp
	_canvas.queue_redraw()


func _handle_mouse_up(mp: Vector2) -> void:
	if _dragging.is_empty():
		return

	var item_data: Dictionary = _get_item_data(_dragging.get("id", ""))
	var item_type: String = item_data.get("type", "")
	var dropped: bool = false

	if _rect_melee_slot().has_point(mp) and item_type == "melee":
		var old: Dictionary = _inventory.get("melee", {})
		if not old.is_empty():
			_inventory["bag"].append(old)
		_inventory["melee"] = _dragging
		emit_signal("weapon_equipped", "melee", _dragging)
		dropped = true

	elif _rect_ranged_slot().has_point(mp) and item_type == "ranged":
		var old: Dictionary = _inventory.get("ranged", {})
		if not old.is_empty():
			_inventory["bag"].append(old)
		_inventory["ranged"] = _dragging
		emit_signal("weapon_equipped", "ranged", _dragging)
		dropped = true

	elif _rect_armor_slot().has_point(mp) and item_type == "armor":
		var old: Dictionary = _inventory.get("armor", {})
		if not old.is_empty():
			_inventory["bag"].append(old)
		_inventory["armor"] = _dragging
		emit_signal("weapon_equipped", "armor", _dragging)
		dropped = true

	elif _rect_bag_area().has_point(mp):
		_inventory["bag"].append(_dragging)
		dropped = true

	if not dropped:
		_return_to_source()

	_dragging = {}
	_canvas.queue_redraw()


func _return_to_source() -> void:
	if _drag_from == "melee":
		_inventory["melee"] = _dragging
	elif _drag_from == "ranged":
		_inventory["ranged"] = _dragging
	elif _drag_from == "armor":
		_inventory["armor"] = _dragging
	elif _drag_from.begins_with("bag:"):
		var idx: int = int(_drag_from.split(":")[1])
		_inventory["bag"].insert(idx, _dragging)


# ── Hit-test rectangles ───────────────────────────────────────────────────────

func _rect_melee_slot() -> Rect2:
	return Rect2(EQUIP_X, EQUIP_MELEE_Y, SLOT_W, SLOT_H)

func _rect_ranged_slot() -> Rect2:
	return Rect2(EQUIP_X, EQUIP_RANGED_Y, SLOT_W, SLOT_H)

func _rect_armor_slot() -> Rect2:
	return Rect2(EQUIP_X, EQUIP_ARMOR_Y, SLOT_W, SLOT_H)

func _rect_bag_slot(i: int) -> Rect2:
	var col: int = i % BAG_COLS
	var row: int = i / BAG_COLS
	return Rect2(
		BAG_X + col * (BAG_SLOT_W + BAG_GAP),
		BAG_Y + row * (BAG_SLOT_H + BAG_GAP),
		BAG_SLOT_W, BAG_SLOT_H
	)

func _rect_bag_area() -> Rect2:
	return Rect2(
		BAG_X - 2, BAG_Y - 2,
		BAG_COLS * (BAG_SLOT_W + BAG_GAP) + 4,
		BAG_ROWS * (BAG_SLOT_H + BAG_GAP) + 4
	)

func _rect_scroll_up() -> Rect2:
	return Rect2(SCROLL_X, BAG_Y, SCROLL_ARROW_W, SCROLL_ARROW_H)

func _rect_scroll_down() -> Rect2:
	var bag_bottom: int = BAG_Y + BAG_ROWS * (BAG_SLOT_H + BAG_GAP) - SCROLL_ARROW_H
	return Rect2(SCROLL_X, bag_bottom, SCROLL_ARROW_W, SCROLL_ARROW_H)

func _max_scroll() -> int:
	var total_rows: int = ceili(float(_filtered_bag().size()) / BAG_COLS)
	return maxi(0, total_rows - BAG_ROWS)


## Looks up base item data (from weapon_data.gd or armor_data.gd) by item ID.
func _get_item_data(id: String) -> Dictionary:
	if WeaponData.WEAPONS.has(id):
		return WeaponData.WEAPONS[id]
	if ArmorData.ARMOR.has(id):
		return ArmorData.ARMOR[id]
	return {}


## Returns visible bag items filtered by the active tab.
## Each entry: { actual_i: int, item: Dictionary }
## actual_i is the real index in _inventory["bag"] — needed for drag-drop.
func _filtered_bag() -> Array:
	var bag: Array = _inventory.get("bag", [])
	var result: Array = []
	for i in range(bag.size()):
		var entry_item: Dictionary = bag[i]
		if _bag_filter == "all":
			result.append({"actual_i": i, "item": entry_item})
		else:
			var data: Dictionary = _get_item_data(entry_item.get("id", ""))
			if data.get("type", "") == _bag_filter:
				result.append({"actual_i": i, "item": entry_item})
	return result


## Returns the tab ID at the given point, or "" if none.
func _tab_at(mp: Vector2) -> String:
	var x: int = BAG_X
	for tab in TAB_DEFS:
		var r := Rect2(x, TAB_Y, tab.w, TAB_H)
		if r.has_point(mp):
			return tab.id
		x += tab.w + 2
	return ""


# ── Drawing ───────────────────────────────────────────────────────────────────

func _on_draw() -> void:
	if not is_open:
		return

	var mp: Vector2 = get_viewport().get_mouse_position()

	_canvas.draw_rect(Rect2(0, 0, 320, 180), COL_BG)
	_canvas.draw_rect(Rect2(PANEL_X, PANEL_Y, PANEL_W, PANEL_H), COL_PANEL)
	_draw_border(PANEL_X, PANEL_Y, PANEL_W, PANEL_H, COL_BORDER)

	_draw_text(PANEL_X + 4, PANEL_Y + 4, "INVENTORY", COL_TITLE)
	_draw_text(EQUIP_X, EQUIP_MELEE_Y - 10, "EQUIPPED", COL_LABEL)
	_canvas.draw_rect(Rect2(BAG_X - 6, PANEL_Y + 14, 1, PANEL_H - 18), COL_DIVIDER)

	_draw_text(EQUIP_X + 2, EQUIP_MELEE_Y  + 2, "MELEE",  COL_LABEL)
	_draw_text(EQUIP_X + 2, EQUIP_RANGED_Y + 2, "RANGED", COL_LABEL)
	_draw_text(EQUIP_X + 2, EQUIP_ARMOR_Y  + 2, "ARMOR",  COL_LABEL)

	_draw_equip_slot(EQUIP_X, EQUIP_MELEE_Y,  "melee",  mp)
	_draw_equip_slot(EQUIP_X, EQUIP_RANGED_Y, "ranged", mp)
	_draw_equip_slot(EQUIP_X, EQUIP_ARMOR_Y,  "armor",  mp)

	_draw_tabs()

	var filtered: Array = _filtered_bag()
	var visible_start: int = _bag_scroll * BAG_COLS
	for visual_i in range(BAG_COLS * BAG_ROWS):
		var fi: int = visible_start + visual_i
		var r: Rect2 = _rect_bag_slot(visual_i)
		var slot_item: Dictionary = filtered[fi].item if fi < filtered.size() else {}
		_draw_item_slot(r, slot_item, mp, "")

	_draw_scroll_arrows()

	# Info panel (shown when an item is clicked)
	if not _info_item.is_empty():
		_draw_info_panel()

	# Floating icon following the cursor during a drag
	if not _dragging.is_empty():
		var icon_topleft: Vector2 = _drag_pos - Vector2(3, 3)
		_draw_item_icon(int(icon_topleft.x), int(icon_topleft.y), _dragging.get("id", ""))


func _draw_equip_slot(x: int, y: int, slot: String, mp: Vector2) -> void:
	var item: Dictionary = _inventory.get(slot, {})
	var r: Rect2 = Rect2(x + 30, y, SLOT_W - 30, SLOT_H)
	_draw_item_slot(r, item, mp, slot)


func _draw_item_slot(r: Rect2, item: Dictionary, mp: Vector2, drop_slot: String) -> void:
	## Draws one slot box. drop_slot is "melee"/"ranged"/"armor" for equip slots,
	## or "" for bag slots (bag slots don't care what type gets dropped in them).
	var border_col: Color = COL_BORDER

	# Gold border on the currently selected (info-panel) item
	if not _info_item.is_empty() and item == _info_item:
		border_col = COL_SLOT_HLT

	# While dragging over an equipment slot: gold = valid type, red = wrong type
	if not _dragging.is_empty() and drop_slot != "":
		var wtype: String = _get_item_data(_dragging.get("id", "")).get("type", "")
		if r.has_point(mp):
			border_col = COL_SLOT_HLT if wtype == drop_slot else COL_SLOT_BAD

	_canvas.draw_rect(r, COL_SLOT)
	_draw_border(int(r.position.x), int(r.position.y), int(r.size.x), int(r.size.y), border_col)

	# Draw item icon + name inside the slot (if occupied)
	if not item.is_empty():
		var item_id: String = item.get("id", "")
		var data: Dictionary = _get_item_data(item_id)
		if not data.is_empty():
			var cx: int = int(r.position.x) + 2
			var cy: int = int(r.position.y) + int((r.size.y - 7) / 2.0)
			_draw_item_icon(cx, cy, item_id)
			_draw_text(cx + 9, cy + 1, data.get("name", "").to_upper(), COL_WEAPON)


func _draw_info_panel() -> void:
	## Shows a small stat card below the bag when an item is clicked.
	## Layout (2 rows):
	##   Row 1: item name (white)      LVL N (gold, right-aligned)
	##   Row 2: type (grey)            stat (gold): DEF N for armor, class name for weapons
	var data: Dictionary = _get_item_data(_info_item.get("id", ""))
	if data.is_empty():
		return

	_canvas.draw_rect(Rect2(INFO_X, INFO_Y, INFO_W, INFO_H), COL_SLOT)
	_draw_border(INFO_X, INFO_Y, INFO_W, INFO_H, COL_SLOT_HLT)

	var lx: int = INFO_X + 3
	var level: int = _info_item.get("level", 1)

	# Row 1: name on the left, "LVL N" on the right
	var name_str: String = data.get("name", "").to_upper()
	_draw_text(lx, INFO_Y + 3, name_str, COL_TITLE)
	var lvl_str: String = "LVL " + str(level)
	var lvl_x: int = INFO_X + INFO_W - 3 - lvl_str.length() * 4
	_draw_text(lvl_x, INFO_Y + 3, lvl_str, COL_WEAPON)

	# Row 2: stats — DEF for armor, DPA + DPS for weapons
	if data.get("type", "") == "armor":
		var item_type: String = data.get("type", "").to_upper()
		_draw_text(lx, INFO_Y + 13, item_type, COL_LABEL)
		var eff_def: int = data.get("defense", 0) + level - 1
		_draw_text(lx + 32, INFO_Y + 13, "DEF " + str(eff_def), COL_WEAPON)
	else:
		var dpa: int = data.get("damage", 0) + level - 1
		var dps: int = roundi(float(dpa) / data.get("cooldown", 1.0))
		_draw_text(lx,      INFO_Y + 13, "DPA " + str(dpa), COL_WEAPON)
		_draw_text(lx + 52, INFO_Y + 13, "DPS " + str(dps), COL_WEAPON)


func _draw_item_icon(x: int, y: int, item_id: String) -> void:
	var icon: Array = _get_item_data(item_id).get("icon", [])
	for row in range(icon.size()):
		for col in range(icon[row].size()):
			if icon[row][col] == 1:
				_canvas.draw_rect(Rect2(x + col, y + row, 1, 1), COL_WEAPON)


func _draw_border(x: int, y: int, w: int, h: int, col: Color) -> void:
	_canvas.draw_rect(Rect2(x,         y,         w, 1), col)
	_canvas.draw_rect(Rect2(x,         y + h - 1, w, 1), col)
	_canvas.draw_rect(Rect2(x,         y,         1, h), col)
	_canvas.draw_rect(Rect2(x + w - 1, y,         1, h), col)


func _draw_tabs() -> void:
	var x: int = BAG_X
	for tab in TAB_DEFS:
		var is_active: bool = (_bag_filter == tab.id)
		var bg_col: Color     = Color(0.18, 0.18, 0.32, 1.0) if is_active else COL_SLOT
		var border_col: Color = COL_SLOT_HLT if is_active else COL_BORDER
		var text_col: Color   = COL_TITLE    if is_active else COL_LABEL
		_canvas.draw_rect(Rect2(x, TAB_Y, tab.w, TAB_H), bg_col)
		_draw_border(x, TAB_Y, tab.w, TAB_H, border_col)
		_draw_text(x + 2, TAB_Y + 2, tab.label, text_col)
		x += tab.w + 2


func _draw_scroll_arrows() -> void:
	var can_up: bool   = _bag_scroll > 0
	var can_down: bool = _bag_scroll < _max_scroll()
	var col_up: Color   = COL_SLOT_HLT if can_up   else Color(0.3, 0.3, 0.3, 1.0)
	var col_down: Color = COL_SLOT_HLT if can_down else Color(0.3, 0.3, 0.3, 1.0)

	var up_r: Rect2 = _rect_scroll_up()
	var ux: int = int(up_r.position.x)
	var uy: int = int(up_r.position.y)
	_canvas.draw_rect(Rect2(ux + 3, uy,     1, 1), col_up)
	_canvas.draw_rect(Rect2(ux + 2, uy + 1, 3, 1), col_up)
	_canvas.draw_rect(Rect2(ux + 1, uy + 2, 5, 1), col_up)
	_canvas.draw_rect(Rect2(ux,     uy + 3, 7, 1), col_up)

	var dn_r: Rect2 = _rect_scroll_down()
	var dx: int = int(dn_r.position.x)
	var dy: int = int(dn_r.position.y)
	_canvas.draw_rect(Rect2(dx,     dy,     7, 1), col_down)
	_canvas.draw_rect(Rect2(dx + 1, dy + 1, 5, 1), col_down)
	_canvas.draw_rect(Rect2(dx + 2, dy + 2, 3, 1), col_down)
	_canvas.draw_rect(Rect2(dx + 3, dy + 3, 1, 1), col_down)


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
