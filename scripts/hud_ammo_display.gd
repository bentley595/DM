extends Node2D
## Displays the current ammo as a bar with a small diamond icon.
## Gold when ammo is available, grey during reload.
## The bar drains left-to-right as you shoot, and refills right-to-left
## during reload so it looks visually distinct from normal depletion.

# ── 3x3 diamond icon ────────────────────────────────────────────

const ICON_DIAMOND: Array = [
	[0, 1, 0],
	[1, 1, 1],
	[0, 1, 0],
]

# ── Bar dimensions ───────────────────────────────────────────────
# Matches the layout of every other HUD bar: icon (3px) + gap (2px) + bar.

## X position where the bar starts — right after the icon and gap.
const BAR_X: float = 5.0

## Width of the bar in pixels (same as health/momentum/soul bars).
const BAR_WIDTH: int = 40

## Height of the bar in pixels (same as other bars).
const BAR_HEIGHT: int = 4

## Background color for the empty part of the bar.
const COLOR_BAR_BG: Color = Color(0.15, 0.15, 0.15)

# ── Colors ───────────────────────────────────────────────────────

## Gold — used when ammo is available.
const COLOR_NORMAL: Color = Color(0.9, 0.75, 0.3)

## Dark gold — outline color.
const COLOR_OUTLINE: Color = Color(0.35, 0.28, 0.1)

## Grey — used during reload to show you can't shoot yet.
const COLOR_RELOADING: Color = Color(0.45, 0.45, 0.45)

## Dark grey — outline during reload.
const COLOR_OUTLINE_RELOAD: Color = Color(0.18, 0.18, 0.18)

var icon_color: Color = COLOR_NORMAL
var outline_color: Color = COLOR_OUTLINE

# ── State ────────────────────────────────────────────────────────

var current_ammo: int = 12
var max_ammo: int = 12

## True while reloading — turns the bar grey and reverses fill direction.
var is_reloading: bool = false


func set_ammo(current: int, max_val: int) -> void:
	## Update the bar (normal mode — gold color, left-anchored fill).
	current_ammo = current
	max_ammo = max_val
	is_reloading = false
	icon_color = COLOR_NORMAL
	outline_color = COLOR_OUTLINE
	queue_redraw()


func set_reload_progress(refilled: int, max_val: int) -> void:
	## Update during reload — grey bar fills from the right as rounds refill.
	current_ammo = refilled
	max_ammo = max_val
	is_reloading = true
	icon_color = COLOR_RELOADING
	outline_color = COLOR_OUTLINE_RELOAD
	queue_redraw()


func _draw() -> void:
	# ── Draw diamond icon (3×3 pixels) ──────────────────────────
	for row in 3:
		for col in 3:
			if ICON_DIAMOND[row][col] == 1:
				draw_rect(Rect2(col, row, 1, 1), icon_color)

	# ── Draw the bar (same 3-layer technique as hud_bar.gd) ──────
	# Layer 1: outline (1px border on all sides)
	draw_rect(Rect2(BAR_X - 1, -1, BAR_WIDTH + 2, BAR_HEIGHT + 2), outline_color)
	# Layer 2: dark background
	draw_rect(Rect2(BAR_X, 0, BAR_WIDTH, BAR_HEIGHT), COLOR_BAR_BG)
	# Layer 3: fill
	if max_ammo > 0:
		var ratio: float = clampf(float(current_ammo) / float(max_ammo), 0.0, 1.0)
		var fill_w: float = BAR_WIDTH * ratio
		if fill_w > 0.0:
			# Normal: fill anchored to left edge, shrinks right as ammo depletes.
			# Reload: fill anchored to right edge, grows left as rounds refill.
			var fill_x: float = BAR_X if not is_reloading \
								else BAR_X + BAR_WIDTH - fill_w
			draw_rect(Rect2(fill_x, 0, fill_w, BAR_HEIGHT), icon_color)
