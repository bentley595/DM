extends RefCounted
## All armor definitions for PIXEL DUNGEON.
##
## Armor works like weapons — each piece has a name, a class template,
## a pixel-art icon, and a defense value.
##
## DEFENSE: How much damage this armor absorbs from each hit.
## All STARTING armor has defense=1 (same stats for fairness).
## Armor found as loot in dungeons can have higher values.
##
## TYPE: Always "armor" — used by the inventory bag filter tab.

const ARMOR: Dictionary = {

	# ── ARMORED CLASS ─────────────────────────────────────────────
	"chainmail": {
		"name": "Chainmail",
		"type": "armor",
		"template": "armored",
		"defense": 1,
		"icon": [
			[0, 1, 0, 1, 0, 1, 0],
			[1, 1, 1, 1, 1, 1, 1],  # shoulder line
			[1, 0, 1, 0, 1, 0, 1],  # chain ring pattern
			[1, 1, 1, 1, 1, 1, 1],
			[0, 0, 1, 0, 1, 0, 0],
			[0, 0, 1, 0, 1, 0, 0],
			[0, 0, 0, 0, 0, 0, 0],
		]
	},

	# ── ROBED CLASS ───────────────────────────────────────────────
	"silk_robe": {
		"name": "Silk Robe",
		"type": "armor",
		"template": "robed",
		"defense": 1,
		"icon": [
			[0, 0, 1, 1, 1, 0, 0],  # collar/hood
			[0, 1, 1, 0, 1, 1, 0],  # shoulders
			[0, 1, 0, 0, 0, 1, 0],
			[0, 1, 0, 0, 0, 1, 0],
			[1, 1, 0, 0, 0, 1, 1],  # flared hem
			[1, 0, 0, 0, 0, 0, 1],
			[0, 0, 0, 0, 0, 0, 0],
		]
	},

	# ── LIGHT CLASS ───────────────────────────────────────────────
	"leather": {
		"name": "Leather",
		"type": "armor",
		"template": "light",
		"defense": 1,
		"icon": [
			[0, 0, 1, 1, 1, 0, 0],
			[0, 1, 0, 1, 0, 1, 0],  # straps
			[0, 1, 0, 0, 0, 1, 0],
			[0, 1, 1, 0, 1, 1, 0],  # buckle row
			[0, 0, 1, 0, 1, 0, 0],
			[0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0],
		]
	},

	# ── CLOTHED CLASS ─────────────────────────────────────────────
	"cloth_vest": {
		"name": "Cloth",
		"type": "armor",
		"template": "clothed",
		"defense": 1,
		"icon": [
			[0, 0, 1, 0, 1, 0, 0],
			[0, 1, 1, 0, 1, 1, 0],  # collar + shoulders
			[0, 1, 0, 0, 0, 1, 0],
			[0, 1, 0, 0, 0, 1, 0],
			[0, 0, 1, 1, 1, 0, 0],  # hem
			[0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0],
		]
	},
}

## Helper: returns the starting armor ID for a given template.
static func default_armor(template: String) -> String:
	match template:
		"armored": return "chainmail"
		"robed":   return "silk_robe"
		"light":   return "leather"
		"clothed": return "cloth_vest"
	return "cloth_vest"
