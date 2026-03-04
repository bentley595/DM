extends RefCounted
## All weapon definitions for PIXEL DUNGEON.
##
## This is a pure data file — no node, no _ready(), no _process().
## Think of it like a big dictionary of facts about each weapon.
##
## HOW ICONS WORK:
## Each weapon has a 7×7 pixel grid (the "icon" field).
## 0 = transparent (empty pixel), 1 = colored pixel
## These are drawn using the character's palette colors so every
## character's weapons look like they belong to that character.
##
## HOW TEMPLATES WORK:
## The "template" field matches the char_template in player.gd:
## "armored", "robed", "light", or "clothed"
## This controls which projectile SHAPE fires when you use that weapon.

const WEAPONS: Dictionary = {

	# ── ARMORED CLASS ─────────────────────────────────────────────
	"sword": {
		"name": "Sword",
		"type": "melee",
		"template": "armored",
		"damage": 5,
		"cooldown": 0.55,
		"icon": [
			[0, 0, 1, 1, 0, 0, 0],
			[0, 0, 0, 1, 0, 0, 0],
			[0, 0, 0, 1, 0, 0, 0],
			[1, 1, 1, 1, 1, 1, 0],  # crossguard
			[0, 0, 0, 1, 0, 0, 0],
			[0, 0, 0, 1, 0, 0, 0],
			[0, 0, 0, 1, 0, 0, 0],
		]
	},
	"crossbow": {
		"name": "Crossbow",
		"type": "ranged",
		"template": "armored",
		"damage": 6,
		"cooldown": 0.45,
		"icon": [
			[0, 1, 0, 0, 0, 1, 0],
			[1, 0, 1, 0, 1, 0, 0],
			[0, 1, 0, 1, 0, 1, 0],  # bow arc
			[0, 0, 1, 1, 1, 0, 0],  # stock
			[0, 0, 0, 1, 0, 0, 0],
			[0, 0, 0, 1, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0],
		]
	},

	# ── ROBED CLASS ───────────────────────────────────────────────
	"staff": {
		"name": "Staff",
		"type": "melee",
		"template": "robed",
		"damage": 4,
		"cooldown": 0.55,
		"icon": [
			[0, 1, 1, 0, 0, 0, 0],
			[1, 0, 0, 1, 0, 0, 0],  # orb outline
			[0, 1, 1, 0, 0, 0, 0],
			[0, 0, 1, 0, 0, 0, 0],
			[0, 0, 1, 0, 0, 0, 0],
			[0, 0, 1, 0, 0, 0, 0],
			[0, 0, 1, 0, 0, 0, 0],
		]
	},
	"wand": {
		"name": "Wand",
		"type": "ranged",
		"template": "robed",
		"damage": 4,
		"cooldown": 0.45,
		"icon": [
			[0, 0, 1, 1, 0, 0, 0],
			[0, 1, 0, 0, 1, 0, 0],  # small orb tip
			[0, 0, 1, 1, 0, 0, 0],
			[0, 0, 0, 1, 0, 0, 0],
			[0, 0, 1, 0, 0, 0, 0],
			[0, 1, 0, 0, 0, 0, 0],
			[1, 0, 0, 0, 0, 0, 0],
		]
	},

	# ── LIGHT CLASS ───────────────────────────────────────────────
	"dagger": {
		"name": "Dagger",
		"type": "melee",
		"template": "light",
		"damage": 3,
		"cooldown": 0.40,
		"icon": [
			[0, 0, 1, 0, 0, 0, 0],
			[0, 0, 1, 0, 0, 0, 0],
			[0, 1, 1, 1, 0, 0, 0],  # small crossguard
			[0, 0, 1, 0, 0, 0, 0],
			[0, 0, 1, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0],
		]
	},
	"throwing_knife": {
		"name": "Knife",
		"type": "ranged",
		"template": "light",
		"damage": 3,
		"cooldown": 0.30,
		"icon": [
			[0, 0, 0, 0, 0, 0, 1],
			[0, 0, 0, 0, 0, 1, 0],
			[0, 0, 0, 0, 1, 0, 0],  # diagonal blade
			[0, 0, 0, 1, 0, 0, 0],
			[0, 0, 1, 0, 0, 0, 0],
			[0, 1, 0, 0, 0, 0, 0],
			[1, 0, 0, 0, 0, 0, 0],
		]
	},

	# ── CLOTHED CLASS ─────────────────────────────────────────────
	"mace": {
		"name": "Mace",
		"type": "melee",
		"template": "clothed",
		"damage": 7,
		"cooldown": 0.70,
		"icon": [
			[0, 1, 1, 1, 0, 0, 0],
			[1, 1, 1, 1, 1, 0, 0],  # mace head (wider top)
			[0, 1, 1, 1, 0, 0, 0],
			[0, 0, 1, 0, 0, 0, 0],
			[0, 0, 1, 0, 0, 0, 0],
			[0, 0, 1, 0, 0, 0, 0],
			[0, 0, 1, 0, 0, 0, 0],
		]
	},
	"scepter": {
		"name": "Scepter",
		"type": "ranged",
		"template": "clothed",
		"damage": 6,
		"cooldown": 0.60,
		"icon": [
			[0, 1, 1, 1, 0, 0, 0],
			[1, 0, 1, 0, 1, 0, 0],  # gem top
			[0, 1, 1, 1, 0, 0, 0],
			[0, 1, 0, 1, 0, 0, 0],  # decorative band
			[0, 0, 1, 0, 0, 0, 0],
			[0, 0, 1, 0, 0, 0, 0],
			[0, 0, 1, 0, 0, 0, 0],
		]
	},
}

## Helper: returns the melee weapon ID for a given template
static func default_melee(template: String) -> String:
	match template:
		"armored": return "sword"
		"robed":   return "staff"
		"light":   return "dagger"
		"clothed": return "mace"
	return "sword"

## Helper: returns the ranged weapon ID for a given template
static func default_ranged(template: String) -> String:
	match template:
		"armored": return "crossbow"
		"robed":   return "wand"
		"light":   return "throwing_knife"
		"clothed": return "scepter"
	return "crossbow"
