extends RefCounted
## All dungeon ingredient definitions for PIXEL DUNGEON.
##
## Ingredients are PERMANENT UNLOCKS — once you earn one, you can use
## it unlimited times in the crafting UI.  You unlock new ingredients
## by achieving specific goals during dungeon runs.
##
## CATEGORIES:
##   "enemy"     — determines WHAT enemies spawn in the dungeon
##   "modifier"  — changes difficulty or rewards (more gold, harder, etc.)
##   "room"      — affects room count or adds special rooms
##   "challenge" — makes the PLAYER weaker in exchange for more gold
##
## Each ingredient has an "unlock" field describing how to earn it:
##   {"type": "default"}                        — unlocked from the start
##   {"type": "dungeons_completed", "count": 3} — complete 3 dungeon runs
##   {"type": "enemies_killed_in_run", "count": 5} — kill 5 in one run
##   etc.
##
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
		"unlock": {"type": "default"},
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
		"unlock": {"type": "enemies_killed_in_run", "count": 5,
			"hint": "KILL 5 IN ONE RUN"},
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
		"unlock": {"type": "dungeons_completed", "count": 1,
			"hint": "COMPLETE 1 DUNGEON"},
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
		"unlock": {"type": "total_gold_earned", "count": 100,
			"hint": "EARN 100 GOLD TOTAL"},
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
		"unlock": {"type": "rooms_cleared_in_run", "count": 5,
			"hint": "CLEAR 5 ROOMS IN ONE RUN"},
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
		"unlock": {"type": "dungeons_completed", "count": 3,
			"hint": "COMPLETE 3 DUNGEONS"},
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
		"unlock": {"type": "dungeons_completed_no_damage", "count": 1,
			"hint": "COMPLETE A DUNGEON DAMAGELESS"},
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
		"unlock": {"type": "bosses_defeated", "count": 1,
			"hint": "DEFEAT A BOSS"},
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

	# ── CHALLENGE INGREDIENTS ────────────────────────────────────
	# These make the dungeon HARDER but reward you with more gold.
	# It's a risk-vs-reward trade: take on the challenge for bigger
	# payouts!  Each one debuffs the player in some way and adds a
	# gold multiplier to compensate.

	"curse_of_frailty": {
		"name": "Frailty",
		"type": "ingredient",
		"category": "challenge",
		"description": "HALF HP, GOLD X1.5",
		"player_hp_multiplier": 0.5,
		"gold_multiplier": 1.5,
		"unlock": {"type": "dungeons_completed", "count": 5,
			"hint": "COMPLETE 5 DUNGEONS"},
		"icon": [
			[0, 0, 1, 1, 1, 0, 0],
			[0, 1, 0, 0, 0, 1, 0],
			[0, 1, 0, 1, 0, 1, 0],
			[0, 0, 1, 0, 1, 0, 0],
			[0, 0, 0, 1, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 1, 0, 0, 0],
		]
	},

	"leaden_boots": {
		"name": "Lead Boots",
		"type": "ingredient",
		"category": "challenge",
		"description": "-25 PERCENT SPEED, GOLD X1.3",
		"player_speed_multiplier": 0.75,
		"gold_multiplier": 1.3,
		"unlock": {"type": "total_gold_earned", "count": 500,
			"hint": "EARN 500 GOLD TOTAL"},
		"icon": [
			[0, 0, 0, 0, 0, 0, 0],
			[0, 0, 1, 0, 1, 0, 0],
			[0, 0, 1, 0, 1, 0, 0],
			[0, 1, 1, 0, 1, 1, 0],
			[0, 1, 1, 0, 1, 1, 0],
			[1, 1, 1, 0, 1, 1, 1],
			[1, 1, 1, 0, 1, 1, 1],
		]
	},

	"eternal_night": {
		"name": "Darkness",
		"type": "ingredient",
		"category": "challenge",
		"description": "SPOTLIGHT ONLY, GOLD X1.2",
		"darkness": true,
		"gold_multiplier": 1.2,
		"unlock": {"type": "enemies_killed_total", "count": 50,
			"hint": "KILL 50 ENEMIES TOTAL"},
		"icon": [
			[1, 1, 1, 1, 1, 1, 1],
			[1, 0, 0, 0, 0, 0, 1],
			[1, 0, 1, 0, 1, 0, 1],
			[1, 0, 0, 0, 0, 0, 1],
			[1, 0, 0, 0, 0, 0, 1],
			[1, 0, 0, 0, 0, 0, 1],
			[1, 1, 1, 1, 1, 1, 1],
		]
	},

	"swarm": {
		"name": "Swarm",
		"type": "ingredient",
		"category": "challenge",
		"description": "2X ENEMIES, GOLD X1.5",
		"enemy_count_multiplier": 2,
		"gold_multiplier": 1.5,
		"unlock": {"type": "bosses_defeated", "count": 3,
			"hint": "DEFEAT 3 BOSSES"},
		"icon": [
			[1, 0, 1, 0, 1, 0, 1],
			[0, 1, 0, 1, 0, 1, 0],
			[1, 0, 1, 0, 1, 0, 1],
			[0, 1, 0, 1, 0, 1, 0],
			[1, 0, 1, 0, 1, 0, 1],
			[0, 1, 0, 1, 0, 1, 0],
			[1, 0, 1, 0, 1, 0, 1],
		]
	},

	# ── DUNGEON CRAWLER INGREDIENTS ──────────────────────────────
	# These ingredients work great with the room-based dungeon crawler.
	# They were added alongside the INGREDIENT room type, where you
	# can discover locked ingredients during dungeon exploration!

	"healing_herb": {
		"name": "Healing Herb",
		"type": "ingredient",
		"category": "modifier",
		"description": "HEAL 20 HP PER ROOM",
		"heal_per_room": 20,
		"unlock": {"type": "dungeons_completed", "count": 2,
			"hint": "CLEAR 2 DUNGEONS"},
		"icon": [
			[0, 0, 1, 1, 1, 0, 0],
			[0, 1, 0, 1, 0, 1, 0],
			[0, 1, 0, 1, 0, 1, 0],
			[0, 0, 0, 1, 0, 0, 0],
			[0, 0, 0, 1, 0, 0, 0],
			[0, 0, 1, 0, 1, 0, 0],
			[0, 0, 0, 1, 0, 0, 0],
		]
	},

	"map_scroll": {
		"name": "Map Scroll",
		"type": "ingredient",
		"category": "room",
		"description": "REVEALS MINIMAP",
		"reveal_map": true,
		"unlock": {"type": "total_gold_earned", "count": 250,
			"hint": "EARN 250G TOTAL"},
		"icon": [
			[0, 1, 1, 1, 1, 1, 0],
			[1, 0, 0, 0, 0, 0, 1],
			[1, 0, 1, 1, 1, 0, 1],
			[1, 0, 0, 0, 0, 0, 1],
			[1, 0, 1, 1, 1, 0, 1],
			[1, 0, 0, 0, 0, 0, 1],
			[0, 1, 1, 1, 1, 1, 0],
		]
	},

	"treasure_map": {
		"name": "Treasure Map",
		"type": "ingredient",
		"category": "room",
		"description": "+2 TREASURE ROOMS",
		"extra_treasure_rooms": 2,
		"unlock": {"type": "enemies_killed_total", "count": 25,
			"hint": "KILL 25 TOTAL"},
		"icon": [
			[1, 1, 1, 1, 1, 1, 0],
			[1, 0, 0, 0, 0, 1, 0],
			[1, 0, 1, 0, 1, 1, 0],
			[1, 0, 0, 1, 0, 1, 0],
			[1, 0, 1, 0, 1, 1, 0],
			[1, 0, 0, 0, 0, 1, 0],
			[1, 1, 1, 1, 1, 1, 0],
		]
	},

	"phoenix_feather": {
		"name": "Phoenix Feather",
		"type": "ingredient",
		"category": "modifier",
		"description": "REVIVE ONCE IF YOU DIE",
		"has_revive": true,
		"unlock": {"type": "dungeons_completed", "count": 7,
			"hint": "CLEAR 7 DUNGEONS"},
		"icon": [
			[0, 0, 0, 1, 0, 0, 0],
			[0, 0, 1, 1, 1, 0, 0],
			[0, 1, 1, 0, 1, 1, 0],
			[0, 1, 0, 1, 0, 1, 0],
			[0, 0, 1, 1, 1, 0, 0],
			[0, 0, 0, 1, 0, 0, 0],
			[0, 0, 0, 1, 0, 0, 0],
		]
	},
}
