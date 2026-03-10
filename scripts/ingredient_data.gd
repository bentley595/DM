extends RefCounted
## All dungeon ingredient definitions for PIXEL DUNGEON.
##
## Ingredients are items the player collects and places into dungeon
## crafting slots.  Each one affects what kind of dungeon gets generated —
## what enemies spawn, how many rooms there are, and what rewards you get.
##
## CATEGORIES:
##   "enemy"    — determines WHAT enemies spawn in the dungeon
##   "modifier" — changes difficulty or rewards (more gold, harder, etc.)
##   "room"     — affects room count or adds special rooms
##
## This follows the same pattern as weapon_data.gd and armor_data.gd:
## a pure data file with no node, no _ready(), no _process().
## Icons are 7x7 grids (0 = transparent, 1 = colored pixel).

const INGREDIENTS: Dictionary = {

	# ── ENEMY INGREDIENTS ─────────────────────────────────────────
	# These determine WHAT enemies appear in the dungeon.
	# You need at least 1 enemy ingredient to enter a dungeon!

	"slime_essence": {
		"name": "Slime Essence",
		"type": "ingredient",
		"category": "enemy",
		"description": "SPAWNS SLIMES",
		"enemy_type": "slime",
		"icon": [
			[0, 0, 0, 0, 0, 0, 0],
			[0, 0, 1, 1, 1, 0, 0],
			[0, 1, 1, 0, 1, 1, 0],
			[0, 1, 0, 0, 0, 1, 0],
			[1, 1, 0, 0, 0, 1, 1],
			[1, 1, 1, 1, 1, 1, 1],
			[0, 0, 0, 0, 0, 0, 0],
		]
	},

	"bone_fragment": {
		"name": "Bone Fragment",
		"type": "ingredient",
		"category": "enemy",
		"description": "SPAWNS SKELETONS",
		"enemy_type": "skeleton",
		"icon": [
			[0, 0, 0, 1, 0, 0, 0],
			[0, 0, 0, 1, 0, 0, 0],
			[0, 1, 0, 1, 0, 1, 0],
			[0, 0, 1, 1, 1, 0, 0],
			[0, 0, 0, 1, 0, 0, 0],
			[0, 0, 1, 0, 1, 0, 0],
			[0, 0, 1, 0, 1, 0, 0],
		]
	},

	"shadow_wisp": {
		"name": "Shadow Wisp",
		"type": "ingredient",
		"category": "enemy",
		"description": "SPAWNS GHOSTS",
		"enemy_type": "ghost",
		"icon": [
			[0, 0, 1, 1, 1, 0, 0],
			[0, 1, 0, 0, 0, 1, 0],
			[0, 1, 0, 1, 0, 1, 0],
			[0, 0, 1, 1, 1, 0, 0],
			[0, 0, 0, 1, 0, 0, 0],
			[0, 0, 1, 0, 1, 0, 0],
			[0, 1, 0, 0, 0, 1, 0],
		]
	},

	# ── MODIFIER INGREDIENTS ──────────────────────────────────────
	# These change how the dungeon plays without adding new enemies.

	"gold_dust": {
		"name": "Gold Dust",
		"type": "ingredient",
		"category": "modifier",
		"description": "+50 PERCENT GOLD",
		"gold_multiplier": 1.5,
		"icon": [
			[0, 0, 0, 1, 0, 0, 0],
			[0, 0, 1, 0, 1, 0, 0],
			[0, 1, 0, 0, 0, 1, 0],
			[0, 0, 1, 0, 1, 0, 0],
			[0, 1, 0, 0, 0, 1, 0],
			[0, 0, 1, 0, 1, 0, 0],
			[0, 0, 0, 1, 0, 0, 0],
		]
	},

	"iron_chunk": {
		"name": "Iron Chunk",
		"type": "ingredient",
		"category": "modifier",
		"description": "ENEMIES +2 HP",
		"enemy_hp_bonus": 2,
		"icon": [
			[0, 0, 0, 0, 0, 0, 0],
			[0, 1, 1, 1, 1, 1, 0],
			[0, 1, 1, 0, 1, 1, 0],
			[0, 1, 0, 0, 0, 1, 0],
			[0, 1, 1, 0, 1, 1, 0],
			[0, 1, 1, 1, 1, 1, 0],
			[0, 0, 0, 0, 0, 0, 0],
		]
	},

	"lucky_clover": {
		"name": "Lucky Clover",
		"type": "ingredient",
		"category": "modifier",
		"description": "BETTER LOOT",
		"loot_bonus": true,
		"icon": [
			[0, 0, 0, 0, 0, 0, 0],
			[0, 1, 0, 0, 0, 1, 0],
			[1, 1, 1, 0, 1, 1, 1],
			[0, 1, 1, 1, 1, 1, 0],
			[0, 0, 1, 1, 1, 0, 0],
			[0, 0, 0, 1, 0, 0, 0],
			[0, 0, 0, 1, 0, 0, 0],
		]
	},

	# ── ROOM INGREDIENTS ──────────────────────────────────────────
	# These change the structure of the dungeon itself.

	"stone_brick": {
		"name": "Stone Brick",
		"type": "ingredient",
		"category": "room",
		"description": "+2 ROOMS",
		"extra_rooms": 2,
		"icon": [
			[1, 1, 1, 0, 1, 1, 1],
			[1, 0, 1, 0, 1, 0, 1],
			[1, 1, 1, 1, 1, 1, 1],
			[0, 0, 1, 0, 1, 0, 0],
			[1, 1, 1, 1, 1, 1, 1],
			[1, 0, 1, 0, 1, 0, 1],
			[1, 1, 1, 0, 1, 1, 1],
		]
	},

	"dark_crystal": {
		"name": "Dark Crystal",
		"type": "ingredient",
		"category": "room",
		"description": "ADDS BOSS ROOM",
		"boss_room": true,
		"icon": [
			[0, 0, 0, 1, 0, 0, 0],
			[0, 0, 1, 1, 1, 0, 0],
			[0, 0, 1, 0, 1, 0, 0],
			[0, 1, 1, 0, 1, 1, 0],
			[0, 1, 0, 0, 0, 1, 0],
			[1, 1, 0, 0, 0, 1, 1],
			[1, 1, 1, 1, 1, 1, 1],
		]
	},
}


# ── Stacking ──────────────────────────────────────────────────────
## Ingredients can stack up to MAX_STACK in a single bag slot.
## This saves space — instead of 6 separate "slime_essence" entries,
## you get one entry with count=6.
##
## Key concept: **stack-aware helpers**.
## Every place that adds or removes ingredients from the bag should
## use these functions instead of raw append/remove_at.  That way
## stacking logic lives in ONE place, not scattered across files!

const MAX_STACK: int = 10


## Adds count copies of an ingredient to the bag, stacking with
## existing entries when possible.  If a stack is full (20), the
## remainder goes into a new stack.
static func add_to_bag(bag: Array, item_id: String, count: int = 1) -> void:
	# Try to stack with an existing entry first
	for entry in bag:
		if entry.get("id") == item_id and INGREDIENTS.has(item_id):
			var current: int = entry.get("count", 1)
			var space: int = MAX_STACK - current
			if space > 0:
				var add: int = mini(count, space)
				entry["count"] = current + add
				count -= add
				if count <= 0:
					return

	# Remaining count goes into new stack(s)
	while count > 0:
		var stack: int = mini(count, MAX_STACK)
		bag.append({"id": item_id, "level": 1, "count": stack})
		count -= stack


## Removes one ingredient from a bag entry at the given index.
## If the stack has more than 1, it decrements the count.
## If the stack has exactly 1, it removes the entry entirely.
static func remove_one(bag: Array, bag_index: int) -> void:
	var entry: Dictionary = bag[bag_index]
	var c: int = entry.get("count", 1)
	if c <= 1:
		bag.remove_at(bag_index)
	else:
		entry["count"] = c - 1
