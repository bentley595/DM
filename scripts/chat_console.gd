extends CanvasLayer
## Developer Console + Chat — press T to open, type commands or messages.
##
## This is a powerful debugging tool!  Commands start with "/" and let you
## give yourself gold, items, unlock stations, etc.  Regular text (without
## a "/" prefix) shows up as a chat message — this will be used for
## multiplayer chat in the future!
##
## Key concept: **developer console**.
## Almost every game has a hidden console for testing.  Instead of playing
## through hours of content to test one feature, you can just type
## "/give gold 9999" and instantly have enough gold to test the shop.
## This saves TONS of time during development!
##
## Key concept: **command parsing**.
## When you type "/give gold 500", we need to break that string into parts:
##   "/" tells us it's a command (not a chat message)
##   "give" is the command name
##   "gold" and "500" are arguments (extra info the command needs)
## We use String.split(" ") to break it into an Array: ["give", "gold", "500"]
## Then we check parts[0] to decide what to do.

const WeaponData = preload("res://scripts/weapon_data.gd")
const ArmorData  = preload("res://scripts/armor_data.gd")
const EasterEgg  = preload("res://music/easter_egg.gd")

# ── Layout ────────────────────────────────────────────────────────────────
# The console sits at the bottom of the screen (320×180 viewport).
# Background: y=108 to y=180 (72px tall).  The input bar sits at the
# very bottom (y=166), and message history fills the area above it.
const CONSOLE_Y: int = 108     # top edge of the console background
const CONSOLE_H: int = 72      # height of the console area (fills to y=180)
const CONSOLE_W: int = 320     # full viewport width
const MSG_X:     int = 4       # left margin for messages
const MSG_START_Y: int = 112   # y of the first visible message line
const MSG_LINE_H:  int = 7     # height per message line (5px font + 2px gap)
const MAX_VISIBLE: int = 7     # how many messages fit above the input bar
const INPUT_Y:   int = 164     # y position for the "> " prompt + LineEdit

# ── Colors ────────────────────────────────────────────────────────────────
const COL_BG       := Color(0.0, 0.0, 0.05, 0.82)
const COL_BORDER   := Color(0.3, 0.3, 0.5, 1.0)
const COL_SYSTEM   := Color(0.5, 0.7, 1.0, 1.0)   # blue — system messages
const COL_ERROR    := Color(1.0, 0.4, 0.4, 1.0)    # red — errors
const COL_SUCCESS  := Color(0.4, 1.0, 0.5, 1.0)    # green — success
const COL_CHAT     := Color(0.9, 0.9, 0.9, 1.0)    # white — player chat
const COL_INPUT    := Color(0.7, 0.7, 0.7, 1.0)    # grey — input prompt ">"
const COL_HELP     := Color(0.8, 0.7, 1.0, 1.0)    # purple — help text

# ── Bitmap font (same 3×5 pixel font used everywhere) ────────────────────
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
	"J": [[0,0,1],[0,0,1],[0,0,1],[1,0,1],[0,1,0]],
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
	"/": [[0,0,1],[0,0,1],[0,1,0],[1,0,0],[1,0,0]],
	":": [[0,0,0],[0,1,0],[0,0,0],[0,1,0],[0,0,0]],
	"+": [[0,0,0],[0,1,0],[1,1,1],[0,1,0],[0,0,0]],
	"-": [[0,0,0],[0,0,0],[1,1,1],[0,0,0],[0,0,0]],
	".": [[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,1,0]],
	",": [[0,0,0],[0,0,0],[0,0,0],[0,1,0],[1,0,0]],
	"!": [[0,1,0],[0,1,0],[0,1,0],[0,0,0],[0,1,0]],
	"?": [[1,1,0],[0,0,1],[0,1,0],[0,0,0],[0,1,0]],
	"(": [[0,1,0],[1,0,0],[1,0,0],[1,0,0],[0,1,0]],
	")": [[0,1,0],[0,0,1],[0,0,1],[0,0,1],[0,1,0]],
	"_": [[0,0,0],[0,0,0],[0,0,0],[0,0,0],[1,1,1]],
	">": [[1,0,0],[0,1,0],[0,0,1],[0,1,0],[1,0,0]],
}

# ── Toast (recent messages shown when console is closed) ──────────────
# Messages appear below the HUD bars and fade out after a few seconds.
# "Toast" is a common UI term for temporary pop-up notifications —
# like toast popping out of a toaster and then disappearing!
const TOAST_X:       int = 4       # left margin
const TOAST_Y:       int = 36      # just below the HUD bars (RollCooldown ends ~34)
const TOAST_LINE_H:  int = 7       # same line height as console
const TOAST_MAX:     int = 4       # max messages shown at once
const TOAST_DURATION: float = 4.0  # seconds before a message starts fading
const TOAST_FADE:    float = 1.0   # seconds to fade from visible to invisible

# ── Custom text input ─────────────────────────────────────────────────
# Instead of using Godot's LineEdit (which renders in Pixelify Sans),
# we build our own text input from scratch using the bitmap font.
# This means we need to handle typing, backspace, and Enter ourselves!
#
# Key concept: **rolling your own input**.
# Sometimes a built-in widget doesn't match your game's art style.
# When that happens, you build your own by tracking state (the text
# string) and handling keyboard events manually.  It's more work but
# gives you total control over how it looks.
const INPUT_MAX_CHARS: int = 72  # max characters (fits ~72 chars at 4px each in 290px)
const CURSOR_BLINK: float = 0.5  # cursor blinks every 0.5 seconds

# ── State ────────────────────────────────────────────────────────────────
var is_open: bool = false

## Message history — each entry is {"text", "color", "time"}.
## "time" is the engine time when the message was added (for fading).
var _messages: Array = []

## The current text being typed (our own state, not a LineEdit).
var _text: String = ""

## Timer for blinking cursor animation.
var _cursor_timer: float = 0.0
var _cursor_visible: bool = true

var _canvas: Node2D       # draws the full console (when open)
var _toast_canvas: Node2D  # draws recent messages (always visible)


func _ready() -> void:
	layer = 12
	visible = false

	# Create the toast canvas FIRST — it draws recent messages even
	# when the console is closed.  It lives on a separate CanvasLayer
	# so it stays visible when we set visible=false on this one.
	var toast_layer: CanvasLayer = CanvasLayer.new()
	toast_layer.layer = 12
	get_parent().call_deferred("add_child", toast_layer)
	_toast_canvas = Node2D.new()
	_toast_canvas.draw.connect(_on_toast_draw)
	toast_layer.add_child(_toast_canvas)

	# Create the drawing surface for the background + message history
	# AND the input text (all bitmap rendered, no LineEdit needed).
	_canvas = Node2D.new()
	_canvas.draw.connect(_on_draw)
	add_child(_canvas)


func open() -> void:
	is_open = true
	visible = true
	_text = ""
	_cursor_timer = 0.0
	_cursor_visible = true
	_canvas.queue_redraw()
	_toast_canvas.queue_redraw()  # hide toasts while console is open


func close() -> void:
	is_open = false
	visible = false
	_toast_canvas.queue_redraw()  # show toasts again


func _input(event: InputEvent) -> void:
	# ── T key to open ──────────────────────────────────────────
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.physical_keycode == KEY_T and not is_open:
			# Don't open if another overlay is already open.
			var parent: Node = get_parent()
			var blocked: bool = false
			if parent:
				if parent.has_node("InventoryScreen") and parent.get_node("InventoryScreen").is_open:
					blocked = true
				for overlay_name in ["ShopUI", "ForgeUI", "UnlockPrompt"]:
					if parent.has_node(overlay_name) and parent.get_node(overlay_name).is_open:
						blocked = true
						break
			if blocked:
				return
			open()
			get_viewport().set_input_as_handled()
			return

	if not is_open:
		return

	# ── Block ALL input while the console is open ───────────────
	# Since we no longer have a LineEdit that needs to receive events,
	# we can safely consume everything.  This prevents movement,
	# attacks, and other hotkeys from firing while typing.
	get_viewport().set_input_as_handled()

	if not (event is InputEventKey and event.is_pressed()):
		return

	# ── Escape to close ─────────────────────────────────────────
	if event.physical_keycode == KEY_ESCAPE:
		close()
		return

	# ── Enter to submit ─────────────────────────────────────────
	if event.physical_keycode == KEY_ENTER or event.physical_keycode == KEY_KP_ENTER:
		_submit_text()
		return

	# ── Backspace to delete ─────────────────────────────────────
	if event.physical_keycode == KEY_BACKSPACE:
		if not _text.is_empty():
			_text = _text.substr(0, _text.length() - 1)
			_cursor_timer = 0.0
			_cursor_visible = true
			_canvas.queue_redraw()
		return

	# ── Typing a character ──────────────────────────────────────
	# event.unicode gives the character code for the key pressed.
	# We convert it to uppercase and check if our bitmap font can
	# draw it.  If it can, we add it to the text.
	var char_code: int = event.unicode
	if char_code == 0:
		return  # non-printable key (Shift, Ctrl, etc.)

	var ch: String = char(char_code).to_upper()
	if _text.length() < INPUT_MAX_CHARS and LETTERS.has(ch):
		_text += ch
		_cursor_timer = 0.0
		_cursor_visible = true
		_canvas.queue_redraw()


## Called when the player presses Enter.
func _submit_text() -> void:
	var clean: String = _text.strip_edges()
	_text = ""
	_canvas.queue_redraw()

	if clean.is_empty():
		close()
		return

	if clean.begins_with("/"):
		# It's a command!  Strip the "/" and split into parts.
		# The console stays open so you can chain multiple commands
		# without pressing T each time.
		var cmd_text: String = clean.substr(1)
		var parts: Array = cmd_text.split(" ", false)
		if parts.is_empty():
			return
		_execute_command(parts)
	else:
		# Regular chat message — close after sending so the
		# player can move again immediately.
		_add_message("YOU: " + clean, COL_CHAT)
		close()


## Parse and run a command.
## "parts" is an Array like ["give", "gold", "500"].
func _execute_command(parts: Array) -> void:
	var cmd: String = parts[0].to_lower()

	match cmd:
		"help":
			_cmd_help()
		"give":
			_cmd_give(parts)
		"set":
			_cmd_set(parts)
		"heal":
			_cmd_heal()
		"unlock":
			_cmd_unlock(parts)
		"clear":
			_messages.clear()
			_canvas.queue_redraw()
		"tp":
			_cmd_tp(parts)
		"god":
			_add_message("GOD MODE COMING SOON!", COL_HELP)
		"momentum":
			_cmd_momentum(parts)
		"bend":
			_cmd_bend()
		"unbend":
			_cmd_unbend()
		_:
			_add_message("UNKNOWN COMMAND: /" + cmd, COL_ERROR)
			_add_message("TYPE /HELP FOR A LIST", COL_ERROR)


func _cmd_help() -> void:
	_add_message("-- COMMANDS --", COL_HELP)
	_add_message("/GIVE GOLD (AMT) - ADD GOLD", COL_HELP)
	_add_message("/GIVE (ITEM ID) - ADD ITEM", COL_HELP)
	_add_message("/SET GOLD (AMT) - SET GOLD", COL_HELP)
	_add_message("/HEAL - RESTORE HEALTH", COL_HELP)
	_add_message("/MOMENTUM (AMT) - SET STACKS", COL_HELP)
	_add_message("/UNLOCK ALL - UNLOCK BOOTHS", COL_HELP)
	_add_message("/TP (X) (Y) - TELEPORT", COL_HELP)
	_add_message("/CLEAR - CLEAR CHAT", COL_HELP)


func _cmd_give(parts: Array) -> void:
	if parts.size() < 2:
		_add_message("USAGE: /GIVE GOLD (AMT)", COL_ERROR)
		_add_message("  OR: /GIVE (ITEM ID)", COL_ERROR)
		return

	var target: String = parts[1].to_lower()

	if target == "gold":
		# /give gold 500
		if parts.size() < 3 or not parts[2].is_valid_int():
			_add_message("USAGE: /GIVE GOLD (AMOUNT)", COL_ERROR)
			return
		var amount: int = parts[2].to_int()
		var current: int = get_tree().get_meta("player_gold", 0)
		get_tree().set_meta("player_gold", current + amount)
		_update_gold_hud()
		_add_message("+" + str(amount) + " GOLD (NOW " + str(current + amount) + ")", COL_SUCCESS)
	else:
		# /give sword, /give chainmail, etc.
		_give_item(target)


func _cmd_set(parts: Array) -> void:
	if parts.size() < 3:
		_add_message("USAGE: /SET GOLD (AMOUNT)", COL_ERROR)
		return

	var target: String = parts[1].to_lower()

	if target == "gold":
		if not parts[2].is_valid_int():
			_add_message("USAGE: /SET GOLD (AMOUNT)", COL_ERROR)
			return
		var amount: int = parts[2].to_int()
		get_tree().set_meta("player_gold", amount)
		_update_gold_hud()
		_add_message("GOLD SET TO " + str(amount), COL_SUCCESS)
	else:
		_add_message("UNKNOWN: /SET " + target.to_upper(), COL_ERROR)


func _cmd_heal() -> void:
	# Health system not implemented yet — placeholder message.
	_add_message("HEAL: COMING SOON!", COL_HELP)


func _cmd_momentum(parts: Array) -> void:
	if parts.size() < 2 or not parts[1].is_valid_int():
		_add_message("USAGE: /MOMENTUM (0-50)", COL_ERROR)
		return

	var amount: int = clampi(parts[1].to_int(), 0, 50)
	var player: Node2D = _find_player()
	if not player:
		_add_message("ERROR: NO PLAYER FOUND", COL_ERROR)
		return

	player.momentum = amount
	var hud: CanvasLayer = _find_hud()
	if hud:
		hud.update_momentum(amount, 50)
	_add_message("MOMENTUM SET TO " + str(amount), COL_SUCCESS)


func _cmd_unlock(parts: Array) -> void:
	if parts.size() < 2 or parts[1].to_lower() != "all":
		_add_message("USAGE: /UNLOCK ALL", COL_ERROR)
		return

	get_tree().set_meta("unlocked_forge", true)
	get_tree().set_meta("unlocked_shop", true)
	get_tree().set_meta("unlocked_infinite_dungeon", true)
	_add_message("ALL STATIONS UNLOCKED!", COL_SUCCESS)
	_add_message("RE-ENTER CAMP TO SEE CHANGES", COL_SYSTEM)


func _cmd_bend() -> void:
	# Easter egg!  Plays a secret jingle and shows a message.
	var parent: Node = get_parent()
	if parent and parent.has_node("MusicPlayer"):
		var mp: Node = parent.get_node("MusicPlayer")
		mp.load_song(EasterEgg.new().SONG_DATA)
		mp.play_song()
	_add_message("BENT STUDIOS!", COL_HELP)


func _cmd_unbend() -> void:
	# Stops the easter egg and resumes the scene's normal music.
	var parent: Node = get_parent()
	if parent and parent.has_node("MusicPlayer"):
		var mp: Node = parent.get_node("MusicPlayer")
		mp.stop_song()
		# Reload the scene's original song based on which scene we're in.
		if parent.has_method("_ready"):
			# Camp has a CampSong preload, game uses test_song.
			if parent.has_node("CampGround"):
				var CampSong = load("res://music/camp.gd")
				mp.load_song(CampSong.new().SONG_DATA)
			else:
				var TestSong = load("res://music/test_song.gd")
				mp.load_song(TestSong.new().SONG_DATA)
			mp.play_song()
	_add_message("MUSIC RESTORED!", COL_SUCCESS)


func _cmd_tp(parts: Array) -> void:
	if parts.size() < 3:
		_add_message("USAGE: /TP (X) (Y)", COL_ERROR)
		return
	if not parts[1].is_valid_int() or not parts[2].is_valid_int():
		_add_message("X AND Y MUST BE NUMBERS", COL_ERROR)
		return

	var x: int = parts[1].to_int()
	var y: int = parts[2].to_int()
	var player: Node2D = _find_player()
	if not player:
		_add_message("ERROR: NO PLAYER FOUND", COL_ERROR)
		return

	player.global_position = Vector2(x, y)
	_add_message("TELEPORTED TO (" + str(x) + ", " + str(y) + ")", COL_SUCCESS)


## Give an item by ID — looks it up in weapon and armor data.
func _give_item(item_id: String) -> void:
	# Check if it's a weapon
	if WeaponData.WEAPONS.has(item_id):
		var player: Node2D = _find_player()
		if not player:
			_add_message("ERROR: NO PLAYER FOUND", COL_ERROR)
			return
		var item: Dictionary = {"id": item_id, "level": 1}
		player.inventory["bag"].append(item)
		var wname: String = WeaponData.WEAPONS[item_id]["name"]
		_add_message("ADDED " + wname.to_upper() + " TO BAG", COL_SUCCESS)
		return

	# Check if it's armor
	if ArmorData.ARMOR.has(item_id):
		var player: Node2D = _find_player()
		if not player:
			_add_message("ERROR: NO PLAYER FOUND", COL_ERROR)
			return
		var item: Dictionary = {"id": item_id, "level": 1}
		player.inventory["bag"].append(item)
		var aname: String = ArmorData.ARMOR[item_id]["name"]
		_add_message("ADDED " + aname.to_upper() + " TO BAG", COL_SUCCESS)
		return

	# Not found — show available IDs
	_add_message("UNKNOWN ITEM: " + item_id.to_upper(), COL_ERROR)
	var ids: String = ", ".join(WeaponData.WEAPONS.keys())
	ids += ", " + ", ".join(ArmorData.ARMOR.keys())
	_add_message("ITEMS: " + ids.to_upper(), COL_SYSTEM)


# ── Helpers ─────────────────────────────────────────────────────────────

func _find_player() -> Node2D:
	var parent: Node = get_parent()
	if parent and parent.has_node("Player"):
		return parent.get_node("Player")
	return null


func _find_hud() -> CanvasLayer:
	var parent: Node = get_parent()
	if parent and parent.has_node("HUD"):
		return parent.get_node("HUD")
	return null


func _update_gold_hud() -> void:
	var hud: CanvasLayer = _find_hud()
	if hud and hud.has_method("update_gold"):
		hud.update_gold(get_tree().get_meta("player_gold", 0))


func _add_message(text: String, color: Color) -> void:
	_messages.append({"text": text, "color": color, "time": Time.get_ticks_msec() / 1000.0})
	_canvas.queue_redraw()
	_toast_canvas.queue_redraw()


func _process(delta: float) -> void:
	# Blink the cursor while the console is open.
	if is_open:
		_cursor_timer += delta
		if _cursor_timer >= CURSOR_BLINK:
			_cursor_timer = 0.0
			_cursor_visible = not _cursor_visible
			_canvas.queue_redraw()

	# Redraw the toast overlay so messages fade out smoothly.
	# We only need to redraw while there ARE recent messages — once
	# they've all faded, we stop redrawing to save performance.
	if not is_open and not _messages.is_empty():
		var now: float = Time.get_ticks_msec() / 1000.0
		var newest: Dictionary = _messages.back()
		var age: float = now - newest["time"]
		if age < TOAST_DURATION + TOAST_FADE:
			_toast_canvas.queue_redraw()


# ── Drawing ─────────────────────────────────────────────────────────────

func _on_draw() -> void:
	if not is_open:
		return

	# Dark background
	_canvas.draw_rect(Rect2(0, CONSOLE_Y, CONSOLE_W, CONSOLE_H), COL_BG)

	# Top border line
	_canvas.draw_rect(Rect2(0, CONSOLE_Y, CONSOLE_W, 1), COL_BORDER)

	# ── Input area background ──────────────────────────────────
	_canvas.draw_rect(Rect2(1, INPUT_Y - 1, CONSOLE_W - 2, 7), Color(0.1, 0.1, 0.15, 0.6))
	_canvas.draw_rect(Rect2(1, INPUT_Y - 1, CONSOLE_W - 2, 1), COL_BORDER)

	# ── Draw "> " prompt + typed text ──────────────────────────
	_draw_text_on(_canvas, 4, INPUT_Y, ">", COL_INPUT)
	var text_x: int = 12  # after "> " (4 + 4px for ">" + 4px gap)
	_draw_text_on(_canvas, text_x, INPUT_Y, _text, COL_CHAT)

	# ── Blinking cursor ───────────────────────────────────────
	if _cursor_visible:
		# Position cursor right after the last character.
		# Each character is 4px wide (3px glyph + 1px gap).
		var cursor_x: int = text_x + _text.length() * 4
		# Draw a small vertical bar (1px wide, 5px tall).
		_canvas.draw_rect(Rect2(cursor_x, INPUT_Y, 1, 5), COL_CHAT)

	# ── Message history ────────────────────────────────────────
	var start: int = maxi(0, _messages.size() - MAX_VISIBLE)
	var y: int = MSG_START_Y
	for i in range(start, _messages.size()):
		var msg: Dictionary = _messages[i]
		_draw_text_on(_canvas, MSG_X, y, msg["text"], msg["color"])
		y += MSG_LINE_H


## Toast overlay — draws recent messages below the HUD bars even when
## the console is closed.  Messages fade out after TOAST_DURATION seconds.
func _on_toast_draw() -> void:
	# Don't show toasts while the full console is open — you can
	# already see all the messages there.
	if is_open:
		return
	if _messages.is_empty():
		return

	var now: float = Time.get_ticks_msec() / 1000.0

	# Collect recent messages that haven't fully faded yet.
	var recent: Array = []
	for i in range(_messages.size() - 1, -1, -1):
		var msg: Dictionary = _messages[i]
		var age: float = now - msg["time"]
		if age > TOAST_DURATION + TOAST_FADE:
			break  # older messages are even older, stop looking
		recent.push_front(msg)
		if recent.size() >= TOAST_MAX:
			break

	# Draw each recent message with fading alpha.
	var y: int = TOAST_Y
	for msg in recent:
		var age: float = now - msg["time"]
		var alpha: float = 1.0
		if age > TOAST_DURATION:
			# Fade out over TOAST_FADE seconds
			alpha = 1.0 - (age - TOAST_DURATION) / TOAST_FADE
			alpha = clampf(alpha, 0.0, 1.0)
		if alpha <= 0.0:
			continue
		var col: Color = msg["color"]
		col.a = alpha
		_draw_text_on(_toast_canvas, TOAST_X, y, msg["text"], col)
		y += TOAST_LINE_H


## Draw bitmap text on a specific canvas node.
## Both the console canvas and toast canvas use this same function.
func _draw_text_on(canvas: Node2D, x: int, y: int, text: String, col: Color) -> void:
	var cx: int = x
	for ch in text:
		if LETTERS.has(ch):
			var glyph: Array = LETTERS[ch]
			for row in range(glyph.size()):
				for col_idx in range(glyph[row].size()):
					if glyph[row][col_idx] == 1:
						canvas.draw_rect(Rect2(cx + col_idx, y + row, 1, 1), col)
		cx += 4
