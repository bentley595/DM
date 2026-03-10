extends RefCounted
## Item catalog for the Weapon Shop.
##
## Each item has an ID (matching weapon_data.gd or armor_data.gd)
## and a price in gold.  Items are organized by tier:
##   - Mid-range (50-100G): Basic weapons from other classes
##   - High-quality (300-500G): Premium/rare variants
##
## When bought, items start at Level 1.  The player can upgrade
## them at the Forge later!
##
## Key concept: **data separation**.
## Shop prices are separate from weapon stats (weapon_data.gd).
## This means we can change prices without touching combat balance,
## and add new shop items without modifying the weapon system.

const SHOP_ITEMS: Array = [
	# ── Mid-range melee (50-80G) ─────────────────────────────────
	{"id": "sword",   "price": 60},
	{"id": "staff",   "price": 60},
	{"id": "dagger",  "price": 50},
	{"id": "mace",    "price": 80},

	# ── Mid-range ranged (60-100G) ───────────────────────────────
	{"id": "crossbow",       "price": 80},
	{"id": "wand",           "price": 70},
	{"id": "throwing_knife", "price": 60},
	{"id": "scepter",        "price": 100},

	# ── Armor (70-90G) ──────────────────────────────────────────
	{"id": "chainmail",  "price": 90},
	{"id": "silk_robe",  "price": 70},
	{"id": "leather",    "price": 75},
	{"id": "cloth_vest", "price": 70},

	# ── Dungeon Ingredients (30-200G) ───────────────────────────
	# Place these in crafting slots at the dungeon entrance to
	# generate a custom dungeon!
	{"id": "slime_essence",  "price": 30},
	{"id": "bone_fragment",  "price": 30},
	{"id": "shadow_wisp",    "price": 60},
	{"id": "gold_dust",      "price": 80},
	{"id": "iron_chunk",     "price": 40},
	{"id": "lucky_clover",   "price": 100},
	{"id": "stone_brick",    "price": 50},
	{"id": "dark_crystal",   "price": 200},
]
