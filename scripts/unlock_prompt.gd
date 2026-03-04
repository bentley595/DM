extends CanvasLayer
## Unlock prompt overlay — shows when interacting with a locked booth.
##
## Displays a dimmed preview with the station name, description,
## unlock cost, and a clickable "UNLOCK" button.
##
## Key concept: **modal overlay**.
## When this is open, it "eats" all input (like the inventory screen).
## The game world is still visible underneath but dimmed, so you can
## see what station you're looking at while deciding to unlock.

# ── Layout ──────────────────────────────────────────────────────
const PANEL_X: int = 80
const PANEL_Y: int = 45
const PANEL_W: int = 160
const PANEL_H: int = 90

const BTN_X: int = PANEL_X + 30
const BTN_Y: int = PANEL_Y + 65
const BTN_W: int = 100
const BTN_H: int = 16

# ── Colors ──────────────────────────────────────────────────────
const COL_BG       := Color(0, 0, 0, 0.72)
const COL_PANEL    := Color(0.06, 0.06, 0.14, 1.0)
const COL_BORDER   := Color(0.55, 0.55, 0.75, 1.0)
const COL_TITLE    := Color(1.0, 1.0, 1.0, 1.0)
const COL_DESC     := Color(0.65, 0.65, 0.75, 1.0)
const COL_GOLD     := Color(0.9, 0.75, 0.3, 1.0)
const COL_BTN_OK   := Color(0.15, 0.35, 0.15, 1.0)
const COL_BTN_GREY := Color(0.15, 0.15, 0.15, 1.0)
const COL_BTN_BORDER_OK   := Color(0.3, 0.7, 0.3, 1.0)
const COL_BTN_BORDER_GREY := Color(0.4, 0.4, 0.4, 1.0)

# ── Bitmap font (subset needed for prompts) ────────────────────
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
	",": [[0,0,0],[0,0,0],[0,0,0],[0,1,0],[0,1,0]],
}

# ── State ───────────────────────────────────────────────────────
var is_open: bool = false
var _station: Node2D = null       # the station being unlocked
var _station_name: String = ""
var _station_desc: String = ""
var _unlock_cost: int = 0
var _player_gold: int = 0
var _canvas: Node2D


func _ready() -> void:
	layer = 11  # above inventory (10)
	visible = false
	_canvas = Node2D.new()
	_canvas.draw.connect(_on_draw)
	add_child(_canvas)


func open(station: Node2D, station_name: String, desc: String, cost: int) -> void:
	_station = station
	_station_name = station_name
	_station_desc = desc
	_unlock_cost = cost
	_player_gold = get_tree().get_meta("player_gold", 0)
	is_open = true
	visible = true
	_canvas.queue_redraw()


func close() -> void:
	is_open = false
	visible = false
	_station = null


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
			if _rect_btn().has_point(mp) and _player_gold >= _unlock_cost:
				_do_unlock()


func _do_unlock() -> void:
	# Deduct gold and mark the station as unlocked
	_player_gold -= _unlock_cost
	get_tree().set_meta("player_gold", _player_gold)

	# Save the unlock state to metadata so it persists across scenes
	if _station and _station.unlock_meta_key != "":
		get_tree().set_meta(_station.unlock_meta_key, true)
		_station.is_unlocked = true

	# Update the HUD gold display
	var camp: Node = get_parent()
	if camp.has_node("HUD"):
		camp.get_node("HUD").update_gold(_player_gold)

	close()


func _rect_btn() -> Rect2:
	return Rect2(BTN_X, BTN_Y, BTN_W, BTN_H)


func _on_draw() -> void:
	if not is_open:
		return

	# Dimmed background
	_canvas.draw_rect(Rect2(0, 0, 320, 180), COL_BG)

	# Panel
	_canvas.draw_rect(Rect2(PANEL_X, PANEL_Y, PANEL_W, PANEL_H), COL_PANEL)
	_draw_border(PANEL_X, PANEL_Y, PANEL_W, PANEL_H, COL_BORDER)

	# Title
	_draw_text(PANEL_X + 4, PANEL_Y + 4, _station_name, COL_TITLE)

	# Description (split by \n for multi-line)
	var lines: PackedStringArray = _station_desc.split("\n")
	for i in lines.size():
		_draw_text(PANEL_X + 4, PANEL_Y + 16 + i * 8, lines[i].to_upper(), COL_DESC)

	# Cost display
	var cost_text: String = "COST " + _format_gold(_unlock_cost) + "G"
	_draw_text(PANEL_X + 4, PANEL_Y + 40, cost_text, COL_GOLD)

	# Current gold display
	var gold_text: String = "YOUR GOLD " + _format_gold(_player_gold) + "G"
	_draw_text(PANEL_X + 4, PANEL_Y + 50, gold_text, COL_GOLD)

	# Unlock button
	var can_afford: bool = _player_gold >= _unlock_cost
	var btn_bg: Color = COL_BTN_OK if can_afford else COL_BTN_GREY
	var btn_border: Color = COL_BTN_BORDER_OK if can_afford else COL_BTN_BORDER_GREY
	var btn_text_color: Color = COL_TITLE if can_afford else Color(0.4, 0.4, 0.4, 1.0)

	_canvas.draw_rect(Rect2(BTN_X, BTN_Y, BTN_W, BTN_H), btn_bg)
	_draw_border(BTN_X, BTN_Y, BTN_W, BTN_H, btn_border)

	var btn_label: String = "UNLOCK" if can_afford else "NOT ENOUGH GOLD"
	_draw_text(BTN_X + 4, BTN_Y + 5, btn_label, btn_text_color)


func _format_gold(amount: int) -> String:
	## Formats gold with commas: 10000 → "10,000"
	var s: String = str(amount)
	if s.length() <= 3:
		return s
	var result: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result


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
