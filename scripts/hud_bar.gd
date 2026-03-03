extends Node2D
## A reusable bar component for the HUD (like a health bar or mana bar).
##
## Key concept: **@export variables**.
## When you mark a variable with @export, it shows up in Godot's Inspector
## panel AND can be set differently per-instance in a scene file.  This means
## we write ONE script but use it for both the health bar (red) and the
## momentum bar (blue) — just by changing the exported colors!
##
## Key concept: **layered drawing**.
## To draw a bar with an outline, we paint 3 rectangles in order:
##   1. Outline (dark color, slightly bigger than the bar)
##   2. Background (dark gray, exact bar size — covers the middle of the outline)
##   3. Fill (bright color, width based on current/max ratio)
## Each layer covers part of the previous one, creating the final look!

# ── 3x3 pixel icons ─────────────────────────────────────────────
# These tiny icons sit to the left of the bar.  At 4x scaling they
# become 12x12 screen pixels — small but readable!
# 1 = draw a pixel, 0 = skip (transparent).

## Heart shape — two bumps on top, point at the bottom.
const ICON_HEART: Array = [
	[1, 0, 1],
	[1, 1, 1],
	[0, 1, 0],
]

## Lightning bolt — zigzag from top-right to bottom-center.
const ICON_BOLT: Array = [
	[0, 1, 1],
	[1, 1, 0],
	[0, 1, 0],
]

## Soul orb — hollow diamond / sparkle shape.  Looks ethereal and wispy!
const ICON_SOUL: Array = [
	[0, 1, 0],
	[1, 0, 1],
	[0, 1, 0],
]

## Right-pointing chevron ">" — used for the roll/dash cooldown bar.
const ICON_ARROW: Array = [
	[0, 1, 0],
	[0, 0, 1],
	[0, 1, 0],
]

# ── Exported properties (configurable per-instance) ──────────────
# These defaults are set up for a health bar (red).
# The momentum bar overrides them in the scene file to blue.

@export var bar_width: int = 40
@export var bar_height: int = 4
@export var fill_color: Color = Color(0.8, 0.15, 0.15)
@export var outline_color: Color = Color(0.4, 0.05, 0.05)
@export var bg_color: Color = Color(0.15, 0.15, 0.15)
@export var icon_type: String = "heart"

# ── State ────────────────────────────────────────────────────────

## The current value (e.g. current HP).
var current_value: float = 0.0

## The maximum value (e.g. max HP).
var max_value: float = 1.0

## When true, the fill is drawn as a rainbow gradient instead of a flat color.
var rainbow: bool = false

## How fast the rainbow scrolls — full cycle per second.
const RAINBOW_SPEED: float = 0.4

## Current scroll offset (0.0–1.0), advances each frame when rainbow is on.
var _rainbow_offset: float = 0.0


func set_value(current: float, max_val: float) -> void:
	## Update the bar's fill amount.  Call this whenever health/momentum changes.
	## The bar will automatically redraw to reflect the new values.
	current_value = current
	max_value = max_val
	queue_redraw()


func set_colors(fill: Color, outline: Color) -> void:
	## Swap the bar's fill and outline colors at runtime.
	## Used by the momentum bar to change color as stacks increase.
	fill_color = fill
	outline_color = outline
	queue_redraw()


func set_rainbow(enabled: bool) -> void:
	## Enables or disables the rainbow gradient fill.
	rainbow = enabled
	queue_redraw()


func _process(delta: float) -> void:
	if rainbow:
		_rainbow_offset = fmod(_rainbow_offset + delta * RAINBOW_SPEED, 1.0)
		queue_redraw()


func _draw() -> void:
	# ── Draw the icon (3x3 pixels) ──────────────────────────────
	var icon: Array = ICON_HEART  if icon_type == "heart"  \
				else ICON_BOLT  if icon_type == "bolt"   \
				else ICON_ARROW if icon_type == "arrow"  \
				else ICON_SOUL
	for row in 3:
		for col in 3:
			if icon[row][col] == 1:
				draw_rect(Rect2(col, row, 1, 1), fill_color)

	# ── Draw the bar ────────────────────────────────────────────
	# The bar starts 5px right of the node origin (3px icon + 2px gap).
	var bar_x: float = 5.0

	# Layer 1: Outline — a filled rect that's 1px bigger on every side.
	# When we paint the background on top, only the 1px border remains
	# visible, creating a clean dark edge around the bar.
	draw_rect(Rect2(bar_x - 1, -1, bar_width + 2, bar_height + 2), outline_color)

	# Layer 2: Background — covers the inside of the outline rect.
	draw_rect(Rect2(bar_x, 0, bar_width, bar_height), bg_color)

	# Layer 3: Fill — width is proportional to current_value / max_value.
	if max_value > 0:
		var fill_ratio: float = clampf(current_value / max_value, 0.0, 1.0)
		var fill_width: float = bar_width * fill_ratio
		if fill_width > 0:
			if rainbow:
				## Rainbow mode: draw one vertical strip per pixel column.
				## Each column's hue is based on its position across the bar
				## PLUS a scrolling offset — so the gradient flows left to right.
				## fmod(..., 1.0) keeps the hue in range as the offset grows.
				for col in int(fill_width):
					var hue: float = fmod(float(col) / bar_width - _rainbow_offset + 1.0, 1.0)
					draw_rect(Rect2(bar_x + col, 0, 1, bar_height),
							  Color.from_hsv(hue, 1.0, 1.0))
			else:
				draw_rect(Rect2(bar_x, 0, fill_width, bar_height), fill_color)
