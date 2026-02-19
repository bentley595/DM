extends Control
## File Select screen — lets the player choose between 3 save slots.
##
## Key concept: **state as an index**.
## Instead of tracking each slot separately, one integer (selected_index)
## controls everything.  When the player presses Left/Right, we just
## change that number and re-color the slots to match.

# ── Constants for slot colors ─────────────────────────────────────

# "Dim" look for slots that are NOT selected.
const COLOR_SLOT_NORMAL := Color(0.1, 0.1, 0.2, 0.8)
const COLOR_TEXT_NORMAL := Color(1.0, 1.0, 1.0)

# "Bright" look for the slot the player IS pointing at.
const COLOR_SLOT_SELECTED := Color(0.15, 0.15, 0.3, 0.9)
const COLOR_TEXT_SELECTED := Color(0.9, 0.75, 0.3)

# ── State ─────────────────────────────────────────────────────────

## Which slot (0, 1, or 2) is currently highlighted.
var selected_index: int = 0

## References to the 3 slot ColorRects so we don't look them up every frame.
var slots: Array = []

## Guard flag — prevents input while we're switching scenes.
var transitioning: bool = false


func _ready() -> void:
	# Grab the 3 slot nodes from the HBoxContainer.
	# get_children() returns them in order: Slot0, Slot1, Slot2.
	slots = $FileSlots.get_children()

	# Paint the initial selection (slot 0 starts highlighted).
	_update_selection()


func _unhandled_input(event: InputEvent) -> void:
	# Ignore input while a scene transition is happening.
	if transitioning:
		return

	# Only react to fresh presses, not releases.
	if not event.is_pressed():
		return

	# ── Navigation ────────────────────────────────────────────────
	# "move_right" and "move_left" are custom actions we defined in
	# project.godot's [input] section.  Each one maps to BOTH an
	# arrow key AND a WASD key (e.g. move_left = Left arrow OR A).
	# This way we write the check once and it works for either key!
	if event.is_action("move_right"):
		# Move selection right, but don't go past slot 2.
		# clampi(value, min, max) keeps the number in range.
		selected_index = clampi(selected_index + 1, 0, 2)
		_update_selection()
		# Mark this event as handled so nothing else reacts to it.
		get_viewport().set_input_as_handled()

	elif event.is_action("move_left"):
		# Move selection left, but don't go below slot 0.
		selected_index = clampi(selected_index - 1, 0, 2)
		_update_selection()
		get_viewport().set_input_as_handled()

	elif event.is_action("ui_accept"):
		# The player pressed Enter/Space/gamepad A — they chose a slot!
		_select_file(selected_index)
		get_viewport().set_input_as_handled()

	elif event.is_action("ui_cancel"):
		# Escape/gamepad B — go back to the title screen.
		transitioning = true
		get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
		get_viewport().set_input_as_handled()

	elif event.is_action("playtest"):
		# P key — jump straight into the game with no save file.
		# This skips character creation so you can test gameplay fast!
		# We set a default character (Knight, index 0) and name "Test"
		# so the game scene has something to work with.
		transitioning = true
		get_tree().set_meta("selected_character_index", 0)
		get_tree().set_meta("player_name", "Test")
		get_tree().set_meta("is_playtest", true)
		get_tree().change_scene_to_file("res://scenes/game.tscn")
		get_viewport().set_input_as_handled()


func _update_selection() -> void:
	# Loop through each slot and color it based on whether it's selected.
	# enumerate() gives us both the index (i) AND the node (slot) each loop.
	for i in slots.size():
		var slot: ColorRect = slots[i]

		# Grab the two labels inside each slot.
		var slot_label: Label = slot.get_node("SlotLabel")
		var status_label: Label = slot.get_node("StatusLabel")

		if i == selected_index:
			# This slot is selected — make it bright and gold.
			slot.color = COLOR_SLOT_SELECTED
			slot_label.add_theme_color_override("font_color", COLOR_TEXT_SELECTED)
			status_label.add_theme_color_override("font_color", COLOR_TEXT_SELECTED)
		else:
			# This slot is NOT selected — dim and gray.
			slot.color = COLOR_SLOT_NORMAL
			slot_label.add_theme_color_override("font_color", COLOR_TEXT_NORMAL)
			status_label.add_theme_color_override("font_color", COLOR_TEXT_NORMAL)


func _select_file(index: int) -> void:
	# Store which file slot was chosen, then head to character select.
	# Later this will check if the file already has save data (and load
	# the game directly) — for now, every slot starts fresh.
	transitioning = true
	get_tree().set_meta("selected_file_slot", index)
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")
