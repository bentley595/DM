class_name CharacterData
## Shared character definitions used by the character select and name entry screens.
##
## This script doesn't control any node — it's purely a DATA file.
## Other scripts load it with preload() to access the character array:
##     const CharData = preload("res://scripts/character_data.gd")
##     var chars = CharData.characters()
##
## Key concept: **preload() loads another script by file path**.
## This lets you split your data/logic across multiple files and share it.
## preload() runs at compile time (before the game starts), so it's fast
## and guaranteed to have the data ready when you need it.
##
## We also have `class_name CharacterData` at the top, which registers a
## global name.  But preload() is more reliable when creating files outside
## the Godot editor, because Godot needs to rescan the project to discover
## class_name declarations.
##
## Key concept: **data reuse through templates**.
## Instead of drawing 20 unique characters from scratch, we define 4 body
## shapes (grids) and reuse them with different color palettes.  The Knight
## and Paladin share the same armored body — they just have different colors!

# ══════════════════════════════════════════════════════════════════════
# PIXEL GRID TEMPLATES  (16-bit style — 14 × 20 pixels)
# ══════════════════════════════════════════════════════════════════════
#
# Each grid is a 2D array (14 columns × 20 rows) where:
#   0 = transparent (empty space)
#   1 = outline (dark edge color — gives the sprite a crisp silhouette)
#   2 = primary color (armor, robe, main clothing)
#   3 = primary highlight (lighter version of primary — shows where light hits)
#   4 = skin color
#   5 = skin shadow (darker skin — used for eyes and face shading)
#   6 = secondary color (pants, legs, undershirt)
#   7 = accent color (belt buckle, trim, gems, decorative details)
#
# Why 8 colors instead of 5?  The 3 new colors (outline, highlight, skin
# shadow) are what make 16-bit sprites look SO much better than 8-bit ones:
#   - The OUTLINE (1) draws a dark border around the whole character,
#     making it "pop" against any background — just like SNES sprites!
#   - The HIGHLIGHT (3) adds depth by showing where light hits the armor/robe.
#     Without it, everything looks flat.  With it, you get that shiny 3D feel.
#   - The SKIN SHADOW (5) lets us draw visible EYES on the face!  In the old
#     8-bit sprites, the face was just a solid blob of skin color.  Now you
#     can see two dark pixels for eyes, which gives the character personality.
#
# These are "const" because they never change — they're the same every
# time the game runs.  The "const" keyword tells Godot "this value is
# set once and can never be modified."

## Wide helmet crest, broad shoulder plates, and armored boots.
## Used by: Knight, Paladin, Crusader, Berserker, Samurai
## This is the FRONT-FACING (down) idle pose — what you see when walking toward the camera.
const GRID_ARMORED := [
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,0,0,0,1,7,7,1,0,0,0,0,0],   # helmet crest (accent ornament)
	[0,0,0,0,1,3,3,3,3,1,0,0,0,0],   # helmet dome (highlight — light shining on top)
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # helmet middle (highlight stripe)
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # helmet visor/brim
	[0,0,0,1,4,5,4,4,5,4,1,0,0,0],   # face — two dark pixels for eyes!
	[0,0,0,0,1,4,4,4,4,1,0,0,0,0],   # chin (narrower = jawline shape)
	[0,1,1,2,3,2,7,7,2,3,2,1,1,0],   # shoulder plates (widest row — looks strong!)
	[0,0,1,2,2,3,7,7,3,2,2,1,0,0],   # upper chest with accent stripe
	[0,0,1,2,3,2,2,2,2,3,2,1,0,0],   # chest plate (highlights on sides)
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # lower chest
	[0,0,0,1,7,2,7,7,2,7,1,0,0,0],   # belt with accent buckles
	[0,0,0,1,6,6,1,1,6,6,1,0,0,0],   # hip (outline divides torso from legs)
	[0,0,0,1,6,6,0,0,6,6,1,0,0,0],   # upper legs
	[0,0,0,1,6,6,0,0,6,6,1,0,0,0],   # mid legs
	[0,0,0,1,6,6,0,0,6,6,1,0,0,0],   # lower legs
	[0,0,0,1,2,2,0,0,2,2,1,0,0,0],   # boot cuff (primary color returns)
	[0,0,1,2,3,2,0,0,2,3,2,1,0,0],   # boot with highlight shine
	[0,0,1,2,2,2,0,0,2,2,2,1,0,0],   # boot
	[0,0,0,1,1,1,0,0,1,1,1,0,0,0],   # boot sole (outline only)
]

## Armored left-step frame — left leg shifts 1px left, widening the stride.
## Upper body (rows 0–11) is identical to GRID_ARMORED.
## Only the legs/boots (rows 12–19) change — this is what creates the walk!
const GRID_ARMORED_STEP := [
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,0,0,0,1,7,7,1,0,0,0,0,0],   # (same) helmet crest
	[0,0,0,0,1,3,3,3,3,1,0,0,0,0],   # (same) helmet dome
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # (same) helmet middle
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # (same) helmet visor
	[0,0,0,1,4,5,4,4,5,4,1,0,0,0],   # (same) face
	[0,0,0,0,1,4,4,4,4,1,0,0,0,0],   # (same) chin
	[0,1,1,2,3,2,7,7,2,3,2,1,1,0],   # (same) shoulders
	[0,0,1,2,2,3,7,7,3,2,2,1,0,0],   # (same) upper chest
	[0,0,1,2,3,2,2,2,2,3,2,1,0,0],   # (same) chest plate
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # (same) lower chest
	[0,0,0,1,7,2,7,7,2,7,1,0,0,0],   # (same) belt
	[0,0,0,1,6,6,1,1,6,6,1,0,0,0],   # (same) hip
	[0,0,1,6,6,0,0,0,6,6,1,0,0,0],   # ← left leg shifted 1px left
	[0,0,1,6,6,0,0,0,6,6,1,0,0,0],   # ← left leg shifted 1px left
	[0,0,1,6,6,0,0,0,6,6,1,0,0,0],   # ← lower leg shifted (new row)
	[0,0,1,2,2,0,0,0,2,2,1,0,0,0],   # ← boot cuff shifted
	[0,1,2,3,2,0,0,0,2,3,2,1,0,0],   # ← boot highlight shifted
	[0,1,2,2,2,0,0,0,2,2,2,1,0,0],   # ← boot shifted
	[0,0,1,1,1,0,0,0,1,1,1,0,0,0],   # ← sole shifted
]

## Armored BACK view (walking UP / away from the camera).
## The head changes: no face — just the back of the helmet.  The body and legs
## stay the same because armor looks similar from behind at this pixel size.
## Key rows that change from GRID_ARMORED:
##   Row 4: eyes → solid helmet back (2s replace 4/5 skin colors)
##   Row 6: front accent on shoulders → plain back
##   Row 7: accent stripe → plain
##   Row 10: belt buckles → simpler from behind
const GRID_ARMORED_UP := [
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,0,0,0,1,7,7,1,0,0,0,0,0],   # (same) helmet crest
	[0,0,0,0,1,3,3,3,3,1,0,0,0,0],   # (same) helmet dome
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # (same) helmet middle
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # (same) helmet visor/brim
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # ← back of helmet (no face!)
	[0,0,0,0,1,4,4,4,4,1,0,0,0,0],   # (same) neck/chin area
	[0,1,1,2,3,2,2,2,2,3,2,1,1,0],   # ← no front accent on shoulders
	[0,0,1,2,2,3,2,2,3,2,2,1,0,0],   # ← no accent stripe on back
	[0,0,1,2,3,2,2,2,2,3,2,1,0,0],   # (same) chest plate
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # (same) lower chest
	[0,0,0,1,2,2,7,7,2,2,1,0,0,0],   # ← simpler belt from behind
	[0,0,0,1,6,6,1,1,6,6,1,0,0,0],   # (same) hip
	[0,0,0,1,6,6,0,0,6,6,1,0,0,0],   # (same) upper legs
	[0,0,0,1,6,6,0,0,6,6,1,0,0,0],   # (same) mid legs
	[0,0,0,1,6,6,0,0,6,6,1,0,0,0],   # lower legs
	[0,0,0,1,2,2,0,0,2,2,1,0,0,0],   # (same) boot cuff
	[0,0,1,2,3,2,0,0,2,3,2,1,0,0],   # (same) boot
	[0,0,1,2,2,2,0,0,2,2,2,1,0,0],   # (same) boot
	[0,0,0,1,1,1,0,0,1,1,1,0,0,0],   # (same) boot sole
]

## Armored back view, left-step frame.
## Head rows (0-11) from GRID_ARMORED_UP + leg rows (12-19) from GRID_ARMORED_STEP.
const GRID_ARMORED_UP_STEP := [
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,0,0,0,1,7,7,1,0,0,0,0,0],   # (same) helmet crest
	[0,0,0,0,1,3,3,3,3,1,0,0,0,0],   # (same) helmet dome
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # (same) helmet middle
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # (same) helmet visor
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # ← back of helmet
	[0,0,0,0,1,4,4,4,4,1,0,0,0,0],   # (same) neck
	[0,1,1,2,3,2,2,2,2,3,2,1,1,0],   # ← no front accent
	[0,0,1,2,2,3,2,2,3,2,2,1,0,0],   # ← no accent stripe
	[0,0,1,2,3,2,2,2,2,3,2,1,0,0],   # (same) chest plate
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # (same) lower chest
	[0,0,0,1,2,2,7,7,2,2,1,0,0,0],   # ← simpler belt
	[0,0,0,1,6,6,1,1,6,6,1,0,0,0],   # (same) hip
	[0,0,1,6,6,0,0,0,6,6,1,0,0,0],   # ← left leg shifted (from STEP)
	[0,0,1,6,6,0,0,0,6,6,1,0,0,0],   # ← shifted
	[0,0,1,6,6,0,0,0,6,6,1,0,0,0],   # ← lower leg shifted (new row)
	[0,0,1,2,2,0,0,0,2,2,1,0,0,0],   # ← boot cuff shifted
	[0,1,2,3,2,0,0,0,2,3,2,1,0,0],   # ← boot shifted
	[0,1,2,2,2,0,0,0,2,2,2,1,0,0],   # ← boot shifted
	[0,0,1,1,1,0,0,0,1,1,1,0,0,0],   # ← sole shifted
]

## Armored LEFT profile (walking left / facing left).
## The head changes: one eye visible, helmet extends 1px to the left, narrower chin.
## Key rows that change from GRID_ARMORED:
##   Row 3: helmet visor extends 1px left
##   Row 4: one eye (right side becomes helmet back)
##   Row 5: chin narrower (one fewer pixel)
const GRID_ARMORED_LEFT := [
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,0,0,0,1,7,7,1,0,0,0,0,0],   # (same) helmet crest
	[0,0,0,0,1,3,3,3,3,1,0,0,0,0],   # (same) helmet dome
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # (same) helmet middle
	[0,0,1,1,2,2,2,2,2,2,1,0,0,0],   # ← visor extends 1px left
	[0,0,0,1,4,5,4,4,2,2,1,0,0,0],   # ← one eye, helmet on right side
	[0,0,0,0,1,4,4,4,1,0,0,0,0,0],   # ← narrower chin
	[0,0,0,1,3,2,7,7,2,2,1,0,0,0],   # ← shoulder narrower (side view)
	[0,0,0,0,1,2,7,7,2,1,0,0,0,0],   # ← chest narrower (side view)
	[0,0,0,0,1,3,2,2,3,1,0,0,0,0],   # ← chest plate side view
	[0,0,0,0,1,2,3,3,2,1,0,0,0,0],   # ← lower chest narrower
	[0,0,0,0,1,7,7,7,7,1,0,0,0,0],   # ← belt narrower
	[0,0,0,0,1,6,6,6,6,1,0,0,0,0],   # ← hip solid (no gap)
	[0,0,0,0,1,6,6,6,6,1,0,0,0,0],   # ← legs solid (side view)
	[0,0,0,0,1,6,6,6,6,1,0,0,0,0],   # ← legs solid
	[0,0,0,0,1,6,6,6,6,1,0,0,0,0],   # ← legs solid
	[0,0,0,0,1,2,2,2,2,1,0,0,0,0],   # ← boot cuff narrower
	[0,0,0,0,1,2,3,3,2,1,0,0,0,0],   # ← boot narrower
	[0,0,0,0,1,2,2,2,2,1,0,0,0,0],   # ← boot narrower
	[0,0,0,0,0,1,1,1,1,0,0,0,0,0],   # ← sole narrower
]

## Armored left profile, left-step frame.
## Head rows (0-11) from GRID_ARMORED_LEFT + leg rows (12-19) from GRID_ARMORED_STEP.
const GRID_ARMORED_LEFT_STEP := [
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,0,0,0,1,7,7,1,0,0,0,0,0],   # (same) helmet crest
	[0,0,0,0,1,3,3,3,3,1,0,0,0,0],   # (same) helmet dome
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # (same) helmet middle
	[0,0,1,1,2,2,2,2,2,2,1,0,0,0],   # ← visor extends left
	[0,0,0,1,4,5,4,4,2,2,1,0,0,0],   # ← one eye
	[0,0,0,0,1,4,4,4,1,0,0,0,0,0],   # ← narrower chin
	[0,0,0,1,3,2,7,7,2,2,1,0,0,0],   # ← shoulder (same as left idle)
	[0,0,0,0,1,2,7,7,2,1,0,0,0,0],   # ← chest (same)
	[0,0,0,0,1,3,2,2,3,1,0,0,0,0],   # ← chest plate (same)
	[0,0,0,0,1,2,3,3,2,1,0,0,0,0],   # ← lower chest (same)
	[0,0,0,0,1,7,7,7,7,1,0,0,0,0],   # ← belt (same)
	[0,0,0,0,1,6,6,6,6,1,0,0,0,0],   # ← hip solid (same)
	[0,0,1,6,6,0,0,0,6,6,1,0,0,0],   # ← legs split (front forward, back stays)
	[0,0,1,6,6,0,0,0,6,6,1,0,0,0],   # ← split
	[0,0,1,6,6,0,0,0,6,6,1,0,0,0],   # ← split
	[0,0,1,2,2,0,0,0,2,2,1,0,0,0],   # ← boot cuff split
	[0,0,1,2,3,0,0,0,3,2,1,0,0,0],   # ← boot split
	[0,0,1,2,2,0,0,0,2,2,1,0,0,0],   # ← boot split
	[0,0,0,1,1,0,0,0,1,1,0,0,0,0],   # ← sole split
]

## Tall pointed hat, flowing robes that widen dramatically at the bottom.
## The robe spreads to full width for that classic wizard silhouette!
## Used by: Mage, Necromancer, Warlock, Elementalist, Summoner, Druid
const GRID_ROBED := [
	[0,0,0,0,0,0,1,1,0,0,0,0,0,0],   # hat tip (pointy!)
	[0,0,0,0,0,1,7,7,1,0,0,0,0,0],   # hat upper (accent gem or star)
	[0,0,0,0,1,2,3,3,2,1,0,0,0,0],   # hat with highlight
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # hat brim
	[0,0,0,1,4,5,4,4,5,4,1,0,0,0],   # face with eyes
	[0,0,0,0,1,4,4,4,4,1,0,0,0,0],   # chin
	[0,0,0,1,2,2,7,7,2,2,1,0,0,0],   # collar with accent brooch
	[0,0,1,2,2,3,2,2,3,2,2,1,0,0],   # robe upper (highlights on folds)
	[0,0,1,2,3,2,2,2,2,3,2,1,0,0],   # robe chest
	[0,0,1,2,2,2,3,3,2,2,2,1,0,0],   # robe middle
	[0,0,1,2,2,2,7,7,2,2,2,1,0,0],   # robe sash (accent belt)
	[0,1,2,2,2,3,2,2,3,2,2,2,1,0],   # robe widens (getting wider!)
	[0,1,2,2,3,2,2,2,2,3,2,2,1,0],   # robe lower body
	[1,2,2,2,2,2,3,3,2,2,2,2,2,1],   # robe bottom (widest — full width!)
	[1,2,2,3,2,2,2,2,2,2,3,2,2,1],   # robe hem with highlight
	[0,1,2,2,2,2,2,2,2,2,2,2,1,0],   # robe gathering
	[0,1,2,2,2,1,0,0,1,2,2,2,1,0],   # robe parts open (slit)
	[0,0,1,2,1,0,0,0,0,1,2,1,0,0],   # robe slit widens
	[0,0,0,1,4,4,0,0,4,4,1,0,0,0],   # feet peeking out
	[0,0,0,0,1,1,0,0,1,1,0,0,0,0],   # sandal soles
]

## Robed left-step frame — very subtle because the robe hides most leg movement.
## Only the bottom 4 rows (slit + feet) change — the robe slit opens 1px wider
## on the left, and the left foot peeks out 1px further.
const GRID_ROBED_STEP := [
	[0,0,0,0,0,0,1,1,0,0,0,0,0,0],   # (same) hat tip
	[0,0,0,0,0,1,7,7,1,0,0,0,0,0],   # (same) hat upper
	[0,0,0,0,1,2,3,3,2,1,0,0,0,0],   # (same) hat with highlight
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # (same) hat brim
	[0,0,0,1,4,5,4,4,5,4,1,0,0,0],   # (same) face
	[0,0,0,0,1,4,4,4,4,1,0,0,0,0],   # (same) chin
	[0,0,0,1,2,2,7,7,2,2,1,0,0,0],   # (same) collar
	[0,0,1,2,2,3,2,2,3,2,2,1,0,0],   # (same) robe upper
	[0,0,1,2,3,2,2,2,2,3,2,1,0,0],   # (same) robe chest
	[0,0,1,2,2,2,3,3,2,2,2,1,0,0],   # (same) robe middle
	[0,0,1,2,2,2,7,7,2,2,2,1,0,0],   # (same) robe sash
	[0,1,2,2,2,3,2,2,3,2,2,2,1,0],   # (same) robe widens
	[0,1,2,2,3,2,2,2,2,3,2,2,1,0],   # (same) robe lower body
	[1,2,2,2,2,2,3,3,2,2,2,2,2,1],   # (same) robe bottom
	[1,2,2,3,2,2,2,2,2,2,3,2,2,1],   # (same) robe hem
	[0,1,2,2,2,2,2,2,2,2,2,2,1,0],   # (same) robe gathering
	[1,2,2,2,1,0,0,0,1,2,2,2,1,0],   # ← slit left edge shifted 1px left
	[0,1,2,1,0,0,0,0,0,1,2,1,0,0],   # ← slit left edge shifted 1px left
	[0,0,1,4,4,0,0,0,4,4,1,0,0,0],   # ← left foot shifted 1px left
	[0,0,0,1,1,0,0,0,1,1,0,0,0,0],   # ← left sole shifted 1px left
]

## Robed BACK view (walking UP / away from camera).
## The head changes: no face — back of the pointed hat.  The brooch on the
## collar isn't visible from behind.
## Key rows that change from GRID_ROBED:
##   Row 4: face → solid hat back
##   Row 6: brooch accent → plain collar
const GRID_ROBED_UP := [
	[0,0,0,0,0,0,1,1,0,0,0,0,0,0],   # (same) hat tip
	[0,0,0,0,0,1,7,7,1,0,0,0,0,0],   # (same) hat upper
	[0,0,0,0,1,2,3,3,2,1,0,0,0,0],   # (same) hat with highlight
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # (same) hat brim
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # ← back of hat (no face!)
	[0,0,0,0,1,4,4,4,4,1,0,0,0,0],   # (same) neck
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # ← no brooch on back
	[0,0,1,2,2,3,2,2,3,2,2,1,0,0],   # (same) robe upper
	[0,0,1,2,3,2,2,2,2,3,2,1,0,0],   # (same) robe chest
	[0,0,1,2,2,2,3,3,2,2,2,1,0,0],   # (same) robe middle
	[0,0,1,2,2,2,7,7,2,2,2,1,0,0],   # (same) robe sash
	[0,1,2,2,2,3,2,2,3,2,2,2,1,0],   # (same) robe widens
	[0,1,2,2,3,2,2,2,2,3,2,2,1,0],   # (same) robe lower body
	[1,2,2,2,2,2,3,3,2,2,2,2,2,1],   # (same) robe bottom
	[1,2,2,3,2,2,2,2,2,2,3,2,2,1],   # (same) robe hem
	[0,1,2,2,2,2,2,2,2,2,2,2,1,0],   # (same) robe gathering
	[0,1,2,2,2,1,0,0,1,2,2,2,1,0],   # (same) robe slit
	[0,0,1,2,1,0,0,0,0,1,2,1,0,0],   # (same) slit widens
	[0,0,0,1,4,4,0,0,4,4,1,0,0,0],   # (same) feet
	[0,0,0,0,1,1,0,0,1,1,0,0,0,0],   # (same) soles
]

## Robed back view, left-step frame.
## Head rows (0-11) from GRID_ROBED_UP + leg rows (12-19) from GRID_ROBED_STEP.
const GRID_ROBED_UP_STEP := [
	[0,0,0,0,0,0,1,1,0,0,0,0,0,0],   # (same) hat tip
	[0,0,0,0,0,1,7,7,1,0,0,0,0,0],   # (same) hat upper
	[0,0,0,0,1,2,3,3,2,1,0,0,0,0],   # (same) hat
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # (same) hat brim
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # ← back of hat
	[0,0,0,0,1,4,4,4,4,1,0,0,0,0],   # (same) neck
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # ← no brooch
	[0,0,1,2,2,3,2,2,3,2,2,1,0,0],   # (same) robe upper
	[0,0,1,2,3,2,2,2,2,3,2,1,0,0],   # (same) robe chest
	[0,0,1,2,2,2,3,3,2,2,2,1,0,0],   # (same) robe middle
	[0,0,1,2,2,2,7,7,2,2,2,1,0,0],   # (same) robe sash
	[0,1,2,2,2,3,2,2,3,2,2,2,1,0],   # (same) robe widens
	[0,1,2,2,3,2,2,2,2,3,2,2,1,0],   # (same) robe lower body
	[1,2,2,2,2,2,3,3,2,2,2,2,2,1],   # (same) robe bottom
	[1,2,2,3,2,2,2,2,2,2,3,2,2,1],   # (same) robe hem
	[0,1,2,2,2,2,2,2,2,2,2,2,1,0],   # (same) robe gathering
	[1,2,2,2,1,0,0,0,1,2,2,2,1,0],   # ← slit shifted (from STEP)
	[0,1,2,1,0,0,0,0,0,1,2,1,0,0],   # ← slit shifted
	[0,0,1,4,4,0,0,0,4,4,1,0,0,0],   # ← foot shifted
	[0,0,0,1,1,0,0,0,1,1,0,0,0,0],   # ← sole shifted
]

## Robed LEFT profile (walking left).
## The hat brim extends 1px left, one eye visible, narrower chin.
const GRID_ROBED_LEFT := [
	[0,0,0,0,0,0,1,1,0,0,0,0,0,0],   # (same) hat tip
	[0,0,0,0,0,1,7,7,1,0,0,0,0,0],   # (same) hat upper
	[0,0,0,0,1,2,3,3,2,1,0,0,0,0],   # (same) hat
	[0,0,1,2,2,2,2,2,2,2,1,0,0,0],   # ← hat brim extends 1px left
	[0,0,0,1,4,5,4,4,2,2,1,0,0,0],   # ← one eye
	[0,0,0,0,1,4,4,4,1,0,0,0,0,0],   # ← narrower chin
	[0,0,0,0,1,2,7,7,2,1,0,0,0,0],   # ← collar narrower (side view)
	[0,0,0,1,2,3,2,2,3,2,1,0,0,0],   # ← robe upper narrower
	[0,0,0,1,3,2,2,2,2,3,1,0,0,0],   # ← robe chest narrower
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # ← robe middle narrower
	[0,0,0,1,2,2,7,7,2,2,1,0,0,0],   # ← robe sash narrower
	[0,0,1,2,2,3,2,2,3,2,1,0,0,0],   # ← robe widens (side)
	[0,0,1,2,3,2,2,2,2,3,1,0,0,0],   # ← robe lower (side)
	[0,1,2,2,2,2,3,3,2,2,2,1,0,0],   # ← robe bottom (side)
	[0,1,2,3,2,2,2,2,2,3,2,1,0,0],   # ← robe hem (side)
	[0,0,1,2,2,2,2,2,2,2,1,0,0,0],   # ← robe gathering (side)
	[0,0,0,1,2,2,2,2,2,1,0,0,0,0],   # ← robe bottom taper
	[0,0,0,0,1,2,2,2,1,0,0,0,0,0],   # ← robe hem taper
	[0,0,0,0,1,4,4,4,4,1,0,0,0,0],   # ← feet solid (side view)
	[0,0,0,0,0,1,1,1,1,0,0,0,0,0],   # ← soles solid
]

## Robed left profile, left-step frame.
## Head rows (0-11) from GRID_ROBED_LEFT + leg rows (12-19) from GRID_ROBED_STEP.
const GRID_ROBED_LEFT_STEP := [
	[0,0,0,0,0,0,1,1,0,0,0,0,0,0],   # (same) hat tip
	[0,0,0,0,0,1,7,7,1,0,0,0,0,0],   # (same) hat upper
	[0,0,0,0,1,2,3,3,2,1,0,0,0,0],   # (same) hat
	[0,0,1,2,2,2,2,2,2,2,1,0,0,0],   # ← hat brim extends left
	[0,0,0,1,4,5,4,4,2,2,1,0,0,0],   # ← one eye
	[0,0,0,0,1,4,4,4,1,0,0,0,0,0],   # ← narrower chin
	[0,0,0,0,1,2,7,7,2,1,0,0,0,0],   # ← collar (same as left idle)
	[0,0,0,1,2,3,2,2,3,2,1,0,0,0],   # ← robe upper (same)
	[0,0,0,1,3,2,2,2,2,3,1,0,0,0],   # ← robe chest (same)
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # ← robe middle (same)
	[0,0,0,1,2,2,7,7,2,2,1,0,0,0],   # ← robe sash (same)
	[0,0,1,2,2,3,2,2,3,2,1,0,0,0],   # ← robe widens (same)
	[0,0,1,2,3,2,2,2,2,3,1,0,0,0],   # ← robe lower (same)
	[0,1,2,2,2,2,3,3,2,2,2,1,0,0],   # ← robe bottom (same)
	[0,1,2,3,2,2,2,2,2,3,2,1,0,0],   # ← robe hem (same)
	[0,0,1,2,2,2,2,2,2,2,1,0,0,0],   # ← robe gathering (same)
	[0,0,1,2,2,0,0,0,2,2,1,0,0,0],   # ← robe opens into split
	[0,0,1,2,2,0,0,0,2,2,1,0,0,0],   # ← robe hem split
	[0,0,1,4,4,0,0,0,4,4,1,0,0,0],   # ← feet split (front forward, back stays)
	[0,0,0,1,1,0,0,0,1,1,0,0,0,0],   # ← soles split
]

## Deep hood with accent stripes, wrapped chest, slim agile legs.
## The narrower build says "fast and sneaky" — perfect for rogues!
## Used by: Rogue, Ranger, Assassin, Monk, Shadow
const GRID_LIGHT := [
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,0,0,1,2,2,2,2,1,0,0,0,0],   # hood top
	[0,0,0,1,2,3,7,7,3,2,1,0,0,0],   # hood with accent stripes + highlight
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # hood middle (highlight)
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # hood brim
	[0,0,0,1,4,5,4,4,5,4,1,0,0,0],   # face with eyes
	[0,0,0,0,1,4,4,4,4,1,0,0,0,0],   # chin
	[0,0,0,1,2,7,2,2,7,2,1,0,0,0],   # wrapped chest (accent straps)
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # chest (highlight center)
	[0,0,1,2,2,3,2,2,3,2,2,1,0,0],   # torso (wider — arms at sides)
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # lower torso
	[0,0,0,1,7,2,7,7,2,7,1,0,0,0],   # belt with accent
	[0,0,0,1,6,6,1,1,6,6,1,0,0,0],   # hip
	[0,0,0,1,6,6,0,0,6,6,1,0,0,0],   # upper legs
	[0,0,0,1,6,6,0,0,6,6,1,0,0,0],   # mid legs
	[0,0,0,1,4,4,0,0,4,4,1,0,0,0],   # ankle wraps (skin = leather look)
	[0,0,0,1,4,4,0,0,4,4,1,0,0,0],   # boots
	[0,0,0,1,4,5,0,0,5,4,1,0,0,0],   # boot detail (skin shadow stitching)
	[0,0,0,0,1,1,0,0,1,1,0,0,0,0],   # boot sole
]

## Light armor left-step frame — slim legs shift to show a stride.
## Rows 12–19 change: left leg 1px left, right leg stays.
const GRID_LIGHT_STEP := [
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,0,0,1,2,2,2,2,1,0,0,0,0],   # (same) hood top
	[0,0,0,1,2,3,7,7,3,2,1,0,0,0],   # (same) hood stripes
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # (same) hood middle
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # (same) hood brim
	[0,0,0,1,4,5,4,4,5,4,1,0,0,0],   # (same) face
	[0,0,0,0,1,4,4,4,4,1,0,0,0,0],   # (same) chin
	[0,0,0,1,2,7,2,2,7,2,1,0,0,0],   # (same) chest
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # (same) chest highlight
	[0,0,1,2,2,3,2,2,3,2,2,1,0,0],   # (same) torso
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # (same) lower torso
	[0,0,0,1,7,2,7,7,2,7,1,0,0,0],   # (same) belt
	[0,0,0,1,6,6,1,1,6,6,1,0,0,0],   # (same) hip
	[0,0,1,6,6,0,0,0,6,6,1,0,0,0],   # ← left leg shifted 1px left
	[0,0,1,6,6,0,0,0,6,6,1,0,0,0],   # ← left leg shifted 1px left
	[0,0,1,4,4,0,0,0,4,4,1,0,0,0],   # ← ankle shifted 1px left
	[0,0,1,4,4,0,0,0,4,4,1,0,0,0],   # ← boot shifted 1px left
	[0,0,1,4,5,0,0,0,5,4,1,0,0,0],   # ← boot detail shifted 1px left
	[0,0,0,1,1,0,0,0,1,1,0,0,0,0],   # ← sole shifted 1px left
]

## Light armor BACK view (walking UP / away from camera).
## The hood looks similar from behind, but no face is visible and the
## chest straps aren't seen.
## Key rows that change from GRID_LIGHT:
##   Row 4: face → back of hood (no eyes)
##   Row 5: chin → hood extends over neck
##   Row 6: chest straps → plain back
const GRID_LIGHT_UP := [
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,0,0,1,2,2,2,2,1,0,0,0,0],   # (same) hood top
	[0,0,0,1,2,3,7,7,3,2,1,0,0,0],   # (same) hood stripes
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # (same) hood middle
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # (same) hood brim
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # ← back of hood (no face!)
	[0,0,0,0,1,2,2,2,2,1,0,0,0,0],   # ← hood extends over neck
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # ← no straps on back
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # (same) chest highlight
	[0,0,1,2,2,3,2,2,3,2,2,1,0,0],   # (same) torso
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # (same) lower torso
	[0,0,0,1,7,2,7,7,2,7,1,0,0,0],   # (same) belt
	[0,0,0,1,6,6,1,1,6,6,1,0,0,0],   # (same) hip
	[0,0,0,1,6,6,0,0,6,6,1,0,0,0],   # (same) upper legs
	[0,0,0,1,6,6,0,0,6,6,1,0,0,0],   # (same) mid legs
	[0,0,0,1,4,4,0,0,4,4,1,0,0,0],   # (same) ankle wraps
	[0,0,0,1,4,4,0,0,4,4,1,0,0,0],   # (same) boots
	[0,0,0,1,4,5,0,0,5,4,1,0,0,0],   # (same) boot detail
	[0,0,0,0,1,1,0,0,1,1,0,0,0,0],   # (same) boot sole
]

## Light armor back view, left-step frame.
## Head rows (0-11) from GRID_LIGHT_UP + leg rows (12-19) from GRID_LIGHT_STEP.
const GRID_LIGHT_UP_STEP := [
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,0,0,1,2,2,2,2,1,0,0,0,0],   # (same) hood top
	[0,0,0,1,2,3,7,7,3,2,1,0,0,0],   # (same) hood stripes
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # (same) hood middle
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # (same) hood brim
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # ← back of hood
	[0,0,0,0,1,2,2,2,2,1,0,0,0,0],   # ← hood over neck
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # ← no straps
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # (same) chest
	[0,0,1,2,2,3,2,2,3,2,2,1,0,0],   # (same) torso
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # (same) lower torso
	[0,0,0,1,7,2,7,7,2,7,1,0,0,0],   # (same) belt
	[0,0,0,1,6,6,1,1,6,6,1,0,0,0],   # (same) hip
	[0,0,1,6,6,0,0,0,6,6,1,0,0,0],   # ← left leg shifted (from STEP)
	[0,0,1,6,6,0,0,0,6,6,1,0,0,0],   # ← shifted
	[0,0,1,4,4,0,0,0,4,4,1,0,0,0],   # ← ankle shifted
	[0,0,1,4,4,0,0,0,4,4,1,0,0,0],   # ← boot shifted
	[0,0,1,4,5,0,0,0,5,4,1,0,0,0],   # ← boot detail shifted
	[0,0,0,1,1,0,0,0,1,1,0,0,0,0],   # ← sole shifted
]

## Light armor LEFT profile (walking left).
## Hood extends 1px left, one eye visible, narrower chin.
const GRID_LIGHT_LEFT := [
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,0,0,1,2,2,2,2,1,0,0,0,0],   # (same) hood top
	[0,0,0,1,2,3,7,7,3,2,1,0,0,0],   # (same) hood stripes
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # (same) hood middle
	[0,0,1,2,2,2,2,2,2,2,1,0,0,0],   # ← hood extends 1px left
	[0,0,0,1,4,5,4,4,2,2,1,0,0,0],   # ← one eye
	[0,0,0,0,1,4,4,4,1,0,0,0,0,0],   # ← narrower chin
	[0,0,0,0,1,7,2,2,7,1,0,0,0,0],   # ← chest straps narrower (side)
	[0,0,0,0,1,2,3,3,2,1,0,0,0,0],   # ← chest narrower
	[0,0,0,1,2,3,2,2,3,2,1,0,0,0],   # ← torso (side view)
	[0,0,0,0,1,2,2,2,2,1,0,0,0,0],   # ← lower torso narrower
	[0,0,0,0,1,7,7,7,7,1,0,0,0,0],   # ← belt narrower
	[0,0,0,0,1,6,6,6,6,1,0,0,0,0],   # ← hip solid (no gap)
	[0,0,0,0,1,6,6,6,6,1,0,0,0,0],   # ← legs solid (side view)
	[0,0,0,0,1,6,6,6,6,1,0,0,0,0],   # ← legs solid
	[0,0,0,0,1,4,4,4,4,1,0,0,0,0],   # ← ankle wraps narrower
	[0,0,0,0,1,4,4,4,4,1,0,0,0,0],   # ← boots narrower
	[0,0,0,0,1,4,5,5,4,1,0,0,0,0],   # ← boot detail narrower
	[0,0,0,0,0,1,1,1,1,0,0,0,0,0],   # ← sole narrower
]

## Light armor left profile, left-step frame.
## Head rows (0-11) from GRID_LIGHT_LEFT + leg rows (12-19) from GRID_LIGHT_STEP.
const GRID_LIGHT_LEFT_STEP := [
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,0,0,1,2,2,2,2,1,0,0,0,0],   # (same) hood top
	[0,0,0,1,2,3,7,7,3,2,1,0,0,0],   # (same) hood stripes
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # (same) hood middle
	[0,0,1,2,2,2,2,2,2,2,1,0,0,0],   # ← hood extends left
	[0,0,0,1,4,5,4,4,2,2,1,0,0,0],   # ← one eye
	[0,0,0,0,1,4,4,4,1,0,0,0,0,0],   # ← narrower chin
	[0,0,0,0,1,7,2,2,7,1,0,0,0,0],   # ← chest straps (same as left idle)
	[0,0,0,0,1,2,3,3,2,1,0,0,0,0],   # ← chest (same)
	[0,0,0,1,2,3,2,2,3,2,1,0,0,0],   # ← torso (same)
	[0,0,0,0,1,2,2,2,2,1,0,0,0,0],   # ← lower torso (same)
	[0,0,0,0,1,7,7,7,7,1,0,0,0,0],   # ← belt (same)
	[0,0,0,0,1,6,6,6,6,1,0,0,0,0],   # ← hip solid (same)
	[0,0,1,6,6,0,0,0,6,6,1,0,0,0],   # ← legs split (front forward, back stays)
	[0,0,1,6,6,0,0,0,6,6,1,0,0,0],   # ← split
	[0,0,1,4,4,0,0,0,4,4,1,0,0,0],   # ← ankle split
	[0,0,1,4,4,0,0,0,4,4,1,0,0,0],   # ← boot split
	[0,0,1,4,5,0,0,0,5,4,1,0,0,0],   # ← boot detail split
	[0,0,0,1,1,0,0,0,1,1,0,0,0,0],   # ← sole split
]

## Wide-brim hat with accent trim, buttoned shirt, neat shoes.
## The broad hat gives scholars and bards a distinctive look.
## Used by: Cleric, Bard, Witch, Alchemist
const GRID_CLOTHED := [
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,7,1,2,2,2,2,2,2,1,7,0,0],   # hat brim (wide! accent trim on edges)
	[0,0,0,1,2,3,7,7,3,2,1,0,0,0],   # hat crown (accent band + highlight)
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # hat middle (highlight)
	[0,0,0,0,1,2,2,2,2,1,0,0,0,0],   # hat base (narrower bottom)
	[0,0,0,1,4,5,4,4,5,4,1,0,0,0],   # face with eyes
	[0,0,0,0,1,4,4,4,4,1,0,0,0,0],   # chin
	[0,0,1,2,2,3,2,2,3,2,2,1,0,0],   # shoulders / shirt (highlights)
	[0,0,1,2,3,2,2,2,2,3,2,1,0,0],   # shirt upper
	[0,0,0,1,2,2,7,7,2,2,1,0,0,0],   # shirt with button/clasp (accent)
	[0,0,0,1,2,3,2,2,3,2,1,0,0,0],   # shirt lower (highlights)
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # shirt bottom
	[0,0,0,1,6,6,1,1,6,6,1,0,0,0],   # hip
	[0,0,0,1,6,6,0,0,6,6,1,0,0,0],   # upper legs
	[0,0,0,1,6,6,0,0,6,6,1,0,0,0],   # mid legs
	[0,0,0,1,4,4,0,0,4,4,1,0,0,0],   # ankle
	[0,0,1,4,4,4,0,0,4,4,4,1,0,0],   # shoes (wider than ankles)
	[0,0,1,4,5,4,0,0,4,5,4,1,0,0],   # shoe detail (skin shadow stitching)
	[0,0,0,1,1,1,0,0,1,1,1,0,0,0],   # shoe sole
]

## Clothed left-step frame — shoes step out to the left.
## Rows 12–19 change: left leg/shoe 1px left, right stays.
const GRID_CLOTHED_STEP := [
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,7,1,2,2,2,2,2,2,1,7,0,0],   # (same) hat brim
	[0,0,0,1,2,3,7,7,3,2,1,0,0,0],   # (same) hat crown
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # (same) hat middle
	[0,0,0,0,1,2,2,2,2,1,0,0,0,0],   # (same) hat base
	[0,0,0,1,4,5,4,4,5,4,1,0,0,0],   # (same) face
	[0,0,0,0,1,4,4,4,4,1,0,0,0,0],   # (same) chin
	[0,0,1,2,2,3,2,2,3,2,2,1,0,0],   # (same) shoulders
	[0,0,1,2,3,2,2,2,2,3,2,1,0,0],   # (same) shirt upper
	[0,0,0,1,2,2,7,7,2,2,1,0,0,0],   # (same) shirt buttons
	[0,0,0,1,2,3,2,2,3,2,1,0,0,0],   # (same) shirt lower
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # (same) shirt bottom
	[0,0,0,1,6,6,1,1,6,6,1,0,0,0],   # (same) hip
	[0,0,1,6,6,0,0,0,6,6,1,0,0,0],   # ← left leg shifted 1px left
	[0,0,1,6,6,0,0,0,6,6,1,0,0,0],   # ← left leg shifted 1px left
	[0,0,1,4,4,0,0,0,4,4,1,0,0,0],   # ← ankle shifted 1px left
	[0,1,4,4,4,0,0,0,4,4,4,1,0,0],   # ← shoe shifted 1px left
	[0,1,4,5,4,0,0,0,4,5,4,1,0,0],   # ← shoe detail shifted 1px left
	[0,0,1,1,1,0,0,0,1,1,1,0,0,0],   # ← sole shifted 1px left
]
## Clothed BACK view (walking UP / away from camera).
## Back of head visible (skin but no eyes), no buttons on back of shirt.
## Key rows that change from GRID_CLOTHED:
##   Row 4: face → back of head (skin-colored, no eye shadows)
##   Row 8: shirt buttons → plain back
const GRID_CLOTHED_UP := [
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,7,1,2,2,2,2,2,2,1,7,0,0],   # (same) hat brim
	[0,0,0,1,2,3,7,7,3,2,1,0,0,0],   # (same) hat crown
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # (same) hat middle
	[0,0,0,0,1,2,2,2,2,1,0,0,0,0],   # (same) hat base
	[0,0,0,1,4,4,4,4,4,4,1,0,0,0],   # ← back of head (skin, no eyes!)
	[0,0,0,0,1,4,4,4,4,1,0,0,0,0],   # (same) neck
	[0,0,1,2,2,3,2,2,3,2,2,1,0,0],   # (same) shoulders
	[0,0,1,2,3,2,2,2,2,3,2,1,0,0],   # (same) shirt upper
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # ← no buttons on back
	[0,0,0,1,2,3,2,2,3,2,1,0,0,0],   # (same) shirt lower
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # (same) shirt bottom
	[0,0,0,1,6,6,1,1,6,6,1,0,0,0],   # (same) hip
	[0,0,0,1,6,6,0,0,6,6,1,0,0,0],   # (same) upper legs
	[0,0,0,1,6,6,0,0,6,6,1,0,0,0],   # (same) mid legs
	[0,0,0,1,4,4,0,0,4,4,1,0,0,0],   # (same) ankle
	[0,0,1,4,4,4,0,0,4,4,4,1,0,0],   # (same) shoes
	[0,0,1,4,5,4,0,0,4,5,4,1,0,0],   # (same) shoe detail
	[0,0,0,1,1,1,0,0,1,1,1,0,0,0],   # (same) shoe sole
]

## Clothed back view, left-step frame.
## Head rows (0-11) from GRID_CLOTHED_UP + leg rows (12-19) from GRID_CLOTHED_STEP.
const GRID_CLOTHED_UP_STEP := [
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,7,1,2,2,2,2,2,2,1,7,0,0],   # (same) hat brim
	[0,0,0,1,2,3,7,7,3,2,1,0,0,0],   # (same) hat crown
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # (same) hat middle
	[0,0,0,0,1,2,2,2,2,1,0,0,0,0],   # (same) hat base
	[0,0,0,1,4,4,4,4,4,4,1,0,0,0],   # ← back of head
	[0,0,0,0,1,4,4,4,4,1,0,0,0,0],   # (same) neck
	[0,0,1,2,2,3,2,2,3,2,2,1,0,0],   # (same) shoulders
	[0,0,1,2,3,2,2,2,2,3,2,1,0,0],   # (same) shirt upper
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # ← no buttons
	[0,0,0,1,2,3,2,2,3,2,1,0,0,0],   # (same) shirt lower
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0],   # (same) shirt bottom
	[0,0,0,1,6,6,1,1,6,6,1,0,0,0],   # (same) hip
	[0,0,1,6,6,0,0,0,6,6,1,0,0,0],   # ← left leg shifted (from STEP)
	[0,0,1,6,6,0,0,0,6,6,1,0,0,0],   # ← shifted
	[0,0,1,4,4,0,0,0,4,4,1,0,0,0],   # ← ankle shifted
	[0,1,4,4,4,0,0,0,4,4,4,1,0,0],   # ← shoe shifted
	[0,1,4,5,4,0,0,0,4,5,4,1,0,0],   # ← shoe detail shifted
	[0,0,1,1,1,0,0,0,1,1,1,0,0,0],   # ← sole shifted
]

## Clothed LEFT profile (walking left).
## Hat brim extends 1px left, hat base shifts, one eye visible, narrower chin.
const GRID_CLOTHED_LEFT := [
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,7,1,2,2,2,2,2,2,2,1,0,0,0],   # ← hat brim extends 1px left
	[0,0,0,1,2,3,7,7,3,2,1,0,0,0],   # (same) hat crown
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # (same) hat middle
	[0,0,0,1,2,2,2,2,1,0,0,0,0,0],   # ← hat base shifts left
	[0,0,0,1,4,5,4,4,2,2,1,0,0,0],   # ← one eye
	[0,0,0,0,1,4,4,4,1,0,0,0,0,0],   # ← narrower chin
	[0,0,0,1,2,3,2,2,3,1,0,0,0,0],   # ← shoulders narrower (side view)
	[0,0,0,0,1,3,2,2,3,1,0,0,0,0],   # ← shirt upper narrower
	[0,0,0,0,1,2,7,7,2,1,0,0,0,0],   # ← shirt buttons narrower
	[0,0,0,0,1,3,2,2,3,1,0,0,0,0],   # ← shirt lower narrower
	[0,0,0,0,1,2,2,2,2,1,0,0,0,0],   # ← shirt bottom narrower
	[0,0,0,0,1,6,6,6,6,1,0,0,0,0],   # ← hip solid (no gap)
	[0,0,0,0,1,6,6,6,6,1,0,0,0,0],   # ← legs solid (side view)
	[0,0,0,0,1,6,6,6,6,1,0,0,0,0],   # ← legs solid
	[0,0,0,0,1,4,4,4,4,1,0,0,0,0],   # ← ankle narrower
	[0,0,0,0,1,4,4,4,4,1,0,0,0,0],   # ← shoes narrower
	[0,0,0,0,1,4,5,5,4,1,0,0,0,0],   # ← shoe detail narrower
	[0,0,0,0,0,1,1,1,1,0,0,0,0,0],   # ← sole narrower
]

## Clothed left profile, left-step frame.
## Head rows (0-11) from GRID_CLOTHED_LEFT + leg rows (12-19) from GRID_CLOTHED_STEP.
const GRID_CLOTHED_LEFT_STEP := [
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0],   # (transparent — padding row)
	[0,7,1,2,2,2,2,2,2,2,1,0,0,0],   # ← hat brim extends left
	[0,0,0,1,2,3,7,7,3,2,1,0,0,0],   # (same) hat crown
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0],   # (same) hat middle
	[0,0,0,1,2,2,2,2,1,0,0,0,0,0],   # ← hat base shifts left
	[0,0,0,1,4,5,4,4,2,2,1,0,0,0],   # ← one eye
	[0,0,0,0,1,4,4,4,1,0,0,0,0,0],   # ← narrower chin
	[0,0,0,1,2,3,2,2,3,1,0,0,0,0],   # ← shoulders (same as left idle)
	[0,0,0,0,1,3,2,2,3,1,0,0,0,0],   # ← shirt upper (same)
	[0,0,0,0,1,2,7,7,2,1,0,0,0,0],   # ← shirt buttons (same)
	[0,0,0,0,1,3,2,2,3,1,0,0,0,0],   # ← shirt lower (same)
	[0,0,0,0,1,2,2,2,2,1,0,0,0,0],   # ← shirt bottom (same)
	[0,0,0,0,1,6,6,6,6,1,0,0,0,0],   # ← hip solid (same)
	[0,0,1,6,6,0,0,0,6,6,1,0,0,0],   # ← legs split (front forward, back stays)
	[0,0,1,6,6,0,0,0,6,6,1,0,0,0],   # ← split
	[0,0,1,4,4,0,0,0,4,4,1,0,0,0],   # ← ankle split
	[0,0,1,4,4,0,0,0,4,4,1,0,0,0],   # ← shoe split
	[0,0,1,4,5,0,0,0,5,4,1,0,0,0],   # ← shoe detail split
	[0,0,0,1,1,0,0,0,1,1,0,0,0,0],   # ← sole split
]


# ══════════════════════════════════════════════════════════════════════
# CHARACTER LIST
# ══════════════════════════════════════════════════════════════════════

## Cached array — built once, reused forever.
## We use a static var so it's shared across all uses of CharacterData.
static var _characters: Array = []


static func characters() -> Array:
	## Returns the full array of 20 character definitions.
	## Each entry is a Dictionary with "name", "grid", and "palette" keys.
	##
	## We build it on the first call and cache it — this is called the
	## "lazy initialization" pattern.  Why?  Because Color() objects
	## can't be created at compile time (they need the engine running),
	## so we build them the first time someone asks for the data.
	if _characters.is_empty():
		_characters = _build_characters()
	return _characters


static func _build_characters() -> Array:
	## Constructs all 20 character definitions.
	## Each character has:
	##   "name"    — displayed in the UI (e.g. "Knight")
	##   "grid"    — which body shape template to use
	##   "palette" — array of 8 Colors:
	##       [transparent, outline, primary, highlight, skin, skin_shadow, secondary, accent]
	##        index: 0        1        2        3       4        5           6         7

	# ── Common skin tones ──
	# Reused across many characters so we don't repeat the same Color() everywhere.
	# Each skin tone now has a matching SHADOW tone for eyes and face shading.
	var T := Color(0, 0, 0, 0)                # transparent (index 0 — always this)
	var TAN := Color(0.87, 0.72, 0.53)        # warm skin tone
	var TAN_SHADOW := Color(0.65, 0.5, 0.35)  # tan shadow (eyes, jawline)
	var PALE := Color(0.93, 0.82, 0.76)       # lighter skin tone
	var PALE_SHADOW := Color(0.7, 0.58, 0.52) # pale shadow
	var DARK := Color(0.45, 0.35, 0.3)        # darker skin tone
	var DARK_SHADOW := Color(0.3, 0.22, 0.18) # dark shadow

	# Remember: palette order is [transparent, outline, primary, highlight, skin, skin_shadow, secondary, accent]
	#                     index:   0           1        2         3        4       5            6          7
	return [
		# ── ARMORED characters (wide shoulders, helmet) ──────────────
		{
			"name": "Knight",
			"grid": GRID_ARMORED,
			"step_grid": GRID_ARMORED_STEP,
			"grid_up": GRID_ARMORED_UP,
			"step_grid_up": GRID_ARMORED_UP_STEP,
			"grid_left": GRID_ARMORED_LEFT,
			"step_grid_left": GRID_ARMORED_LEFT_STEP,
			# Silver armor with gold trim — the classic RPG knight!
			"palette": [T, Color(0.25, 0.25, 0.35), Color(0.7, 0.7, 0.8), Color(0.85, 0.85, 0.95), TAN, TAN_SHADOW, Color(0.3, 0.3, 0.6), Color(0.9, 0.75, 0.3)],
		},
		{
			"name": "Paladin",
			"grid": GRID_ARMORED,
			"step_grid": GRID_ARMORED_STEP,
			"grid_up": GRID_ARMORED_UP,
			"step_grid_up": GRID_ARMORED_UP_STEP,
			"grid_left": GRID_ARMORED_LEFT,
			"step_grid_left": GRID_ARMORED_LEFT_STEP,
			# Golden armor, cream pants, holy white trim
			"palette": [T, Color(0.4, 0.3, 0.1), Color(0.85, 0.7, 0.2), Color(0.95, 0.85, 0.4), TAN, TAN_SHADOW, Color(0.9, 0.85, 0.8), Color(0.95, 0.95, 1.0)],
		},
		{
			"name": "Crusader",
			"grid": GRID_ARMORED,
			"step_grid": GRID_ARMORED_STEP,
			"grid_up": GRID_ARMORED_UP,
			"step_grid_up": GRID_ARMORED_UP_STEP,
			"grid_left": GRID_ARMORED_LEFT,
			"step_grid_left": GRID_ARMORED_LEFT_STEP,
			# White armor with a bold red cross — templar style
			"palette": [T, Color(0.4, 0.38, 0.35), Color(0.9, 0.88, 0.85), Color(1.0, 0.98, 0.95), TAN, TAN_SHADOW, Color(0.8, 0.78, 0.75), Color(0.8, 0.2, 0.15)],
		},
		{
			"name": "Berserker",
			"grid": GRID_ARMORED,
			"step_grid": GRID_ARMORED_STEP,
			"grid_up": GRID_ARMORED_UP,
			"step_grid_up": GRID_ARMORED_UP_STEP,
			"grid_left": GRID_ARMORED_LEFT,
			"step_grid_left": GRID_ARMORED_LEFT_STEP,
			# Brown leather armor, dark pants, red war paint
			"palette": [T, Color(0.25, 0.15, 0.08), Color(0.55, 0.35, 0.2), Color(0.7, 0.5, 0.3), TAN, TAN_SHADOW, Color(0.4, 0.25, 0.15), Color(0.8, 0.2, 0.1)],
		},
		{
			"name": "Samurai",
			"grid": GRID_ARMORED,
			"step_grid": GRID_ARMORED_STEP,
			"grid_up": GRID_ARMORED_UP,
			"step_grid_up": GRID_ARMORED_UP_STEP,
			"grid_left": GRID_ARMORED_LEFT,
			"step_grid_left": GRID_ARMORED_LEFT_STEP,
			# Red lacquered armor, dark pants, near-black accent
			"palette": [T, Color(0.3, 0.05, 0.05), Color(0.7, 0.15, 0.15), Color(0.85, 0.3, 0.25), TAN, TAN_SHADOW, Color(0.2, 0.15, 0.15), Color(0.12, 0.1, 0.1)],
		},

		# ── ROBED characters (pointy hat, flowing robe) ──────────────
		{
			"name": "Mage",
			"grid": GRID_ROBED,
			"step_grid": GRID_ROBED_STEP,
			"grid_up": GRID_ROBED_UP,
			"step_grid_up": GRID_ROBED_UP_STEP,
			"grid_left": GRID_ROBED_LEFT,
			"step_grid_left": GRID_ROBED_LEFT_STEP,
			# Blue robe, pale skin, gold star on hat
			"palette": [T, Color(0.08, 0.1, 0.35), Color(0.2, 0.3, 0.8), Color(0.35, 0.45, 0.95), PALE, PALE_SHADOW, Color(0.15, 0.2, 0.65), Color(0.9, 0.75, 0.3)],
		},
		{
			"name": "Necromancer",
			"grid": GRID_ROBED,
			"step_grid": GRID_ROBED_STEP,
			"grid_up": GRID_ROBED_UP,
			"step_grid_up": GRID_ROBED_UP_STEP,
			"grid_left": GRID_ROBED_LEFT,
			"step_grid_left": GRID_ROBED_LEFT_STEP,
			# Near-black robe, pale skin, glowing purple accent
			"palette": [T, Color(0.05, 0.04, 0.08), Color(0.15, 0.12, 0.2), Color(0.28, 0.22, 0.38), PALE, PALE_SHADOW, Color(0.25, 0.1, 0.3), Color(0.55, 0.2, 0.65)],
		},
		{
			"name": "Warlock",
			"grid": GRID_ROBED,
			"step_grid": GRID_ROBED_STEP,
			"grid_up": GRID_ROBED_UP,
			"step_grid_up": GRID_ROBED_UP_STEP,
			"grid_left": GRID_ROBED_LEFT,
			"step_grid_left": GRID_ROBED_LEFT_STEP,
			# Dark purple robe, pale skin, red flame accent
			"palette": [T, Color(0.12, 0.04, 0.15), Color(0.3, 0.1, 0.35), Color(0.45, 0.2, 0.5), PALE, PALE_SHADOW, Color(0.22, 0.08, 0.28), Color(0.8, 0.2, 0.2)],
		},
		{
			"name": "Elementalist",
			"grid": GRID_ROBED,
			"step_grid": GRID_ROBED_STEP,
			"grid_up": GRID_ROBED_UP,
			"step_grid_up": GRID_ROBED_UP_STEP,
			"grid_left": GRID_ROBED_LEFT,
			"step_grid_left": GRID_ROBED_LEFT_STEP,
			# Cyan robe, pale skin, orange fire accent
			"palette": [T, Color(0.08, 0.3, 0.35), Color(0.2, 0.65, 0.75), Color(0.35, 0.8, 0.9), PALE, PALE_SHADOW, Color(0.15, 0.55, 0.65), Color(0.9, 0.5, 0.1)],
		},
		{
			"name": "Summoner",
			"grid": GRID_ROBED,
			"step_grid": GRID_ROBED_STEP,
			"grid_up": GRID_ROBED_UP,
			"step_grid_up": GRID_ROBED_UP_STEP,
			"grid_left": GRID_ROBED_LEFT,
			"step_grid_left": GRID_ROBED_LEFT_STEP,
			# Teal robe, pale skin, white spirit accent
			"palette": [T, Color(0.05, 0.25, 0.25), Color(0.15, 0.55, 0.55), Color(0.3, 0.7, 0.7), PALE, PALE_SHADOW, Color(0.1, 0.42, 0.42), Color(0.9, 0.9, 0.95)],
		},
		{
			"name": "Druid",
			"grid": GRID_ROBED,
			"step_grid": GRID_ROBED_STEP,
			"grid_up": GRID_ROBED_UP,
			"step_grid_up": GRID_ROBED_UP_STEP,
			"grid_left": GRID_ROBED_LEFT,
			"step_grid_left": GRID_ROBED_LEFT_STEP,
			# Forest green robe, tan skin, brown wood accent
			"palette": [T, Color(0.1, 0.22, 0.08), Color(0.25, 0.5, 0.2), Color(0.4, 0.65, 0.35), TAN, TAN_SHADOW, Color(0.2, 0.38, 0.15), Color(0.55, 0.4, 0.2)],
		},

		# ── LIGHT characters (hood, slim/agile build) ────────────────
		{
			"name": "Rogue",
			"grid": GRID_LIGHT,
			"step_grid": GRID_LIGHT_STEP,
			"grid_up": GRID_LIGHT_UP,
			"step_grid_up": GRID_LIGHT_UP_STEP,
			"grid_left": GRID_LIGHT_LEFT,
			"step_grid_left": GRID_LIGHT_LEFT_STEP,
			# Dark gray gear, tan skin, dark green pants, green accent
			"palette": [T, Color(0.12, 0.12, 0.15), Color(0.3, 0.3, 0.35), Color(0.45, 0.45, 0.5), TAN, TAN_SHADOW, Color(0.2, 0.35, 0.2), Color(0.3, 0.6, 0.3)],
		},
		{
			"name": "Ranger",
			"grid": GRID_LIGHT,
			"step_grid": GRID_LIGHT_STEP,
			"grid_up": GRID_LIGHT_UP,
			"step_grid_up": GRID_LIGHT_UP_STEP,
			"grid_left": GRID_LIGHT_LEFT,
			"step_grid_left": GRID_LIGHT_LEFT_STEP,
			# Forest green, tan skin, brown pants, light brown accent
			"palette": [T, Color(0.08, 0.22, 0.08), Color(0.2, 0.5, 0.2), Color(0.35, 0.65, 0.35), TAN, TAN_SHADOW, Color(0.45, 0.3, 0.15), Color(0.6, 0.45, 0.2)],
		},
		{
			"name": "Assassin",
			"grid": GRID_LIGHT,
			"step_grid": GRID_LIGHT_STEP,
			"grid_up": GRID_LIGHT_UP,
			"step_grid_up": GRID_LIGHT_UP_STEP,
			"grid_left": GRID_LIGHT_LEFT,
			"step_grid_left": GRID_LIGHT_LEFT_STEP,
			# Near-black gear, tan skin, very dark gray, red blade accent
			"palette": [T, Color(0.04, 0.04, 0.06), Color(0.12, 0.12, 0.15), Color(0.22, 0.22, 0.28), TAN, TAN_SHADOW, Color(0.18, 0.18, 0.2), Color(0.75, 0.15, 0.1)],
		},
		{
			"name": "Monk",
			"grid": GRID_LIGHT,
			"step_grid": GRID_LIGHT_STEP,
			"grid_up": GRID_LIGHT_UP,
			"step_grid_up": GRID_LIGHT_UP_STEP,
			"grid_left": GRID_LIGHT_LEFT,
			"step_grid_left": GRID_LIGHT_LEFT_STEP,
			# Orange robe, tan skin, brown pants, dark brown sash
			"palette": [T, Color(0.4, 0.25, 0.05), Color(0.85, 0.55, 0.15), Color(0.95, 0.7, 0.3), TAN, TAN_SHADOW, Color(0.5, 0.35, 0.2), Color(0.6, 0.4, 0.15)],
		},
		{
			"name": "Shadow",
			"grid": GRID_LIGHT,
			"step_grid": GRID_LIGHT_STEP,
			"grid_up": GRID_LIGHT_UP,
			"step_grid_up": GRID_LIGHT_UP_STEP,
			"grid_left": GRID_LIGHT_LEFT,
			"step_grid_left": GRID_LIGHT_LEFT_STEP,
			# Dark blue gear, dark skin, near-black, midnight accent
			"palette": [T, Color(0.03, 0.03, 0.1), Color(0.1, 0.1, 0.25), Color(0.2, 0.2, 0.4), DARK, DARK_SHADOW, Color(0.08, 0.08, 0.18), Color(0.05, 0.05, 0.12)],
		},

		# ── CLOTHED characters (wide hat, medium build) ──────────────
		{
			"name": "Cleric",
			"grid": GRID_CLOTHED,
			"step_grid": GRID_CLOTHED_STEP,
			"grid_up": GRID_CLOTHED_UP,
			"step_grid_up": GRID_CLOTHED_UP_STEP,
			"grid_left": GRID_CLOTHED_LEFT,
			"step_grid_left": GRID_CLOTHED_LEFT_STEP,
			# White vestments, tan skin, light gray pants, gold holy accent
			"palette": [T, Color(0.4, 0.4, 0.45), Color(0.9, 0.9, 0.95), Color(1.0, 1.0, 1.0), TAN, TAN_SHADOW, Color(0.8, 0.8, 0.85), Color(0.9, 0.75, 0.3)],
		},
		{
			"name": "Bard",
			"grid": GRID_CLOTHED,
			"step_grid": GRID_CLOTHED_STEP,
			"grid_up": GRID_CLOTHED_UP,
			"step_grid_up": GRID_CLOTHED_UP_STEP,
			"grid_left": GRID_CLOTHED_LEFT,
			"step_grid_left": GRID_CLOTHED_LEFT_STEP,
			# Purple outfit, tan skin, darker purple pants, gold trim
			"palette": [T, Color(0.22, 0.08, 0.28), Color(0.5, 0.2, 0.6), Color(0.65, 0.35, 0.75), TAN, TAN_SHADOW, Color(0.4, 0.15, 0.45), Color(0.9, 0.75, 0.3)],
		},
		{
			"name": "Witch",
			"grid": GRID_CLOTHED,
			"step_grid": GRID_CLOTHED_STEP,
			"grid_up": GRID_CLOTHED_UP,
			"step_grid_up": GRID_CLOTHED_UP_STEP,
			"grid_left": GRID_CLOTHED_LEFT,
			"step_grid_left": GRID_CLOTHED_LEFT_STEP,
			# Dark green robes, pale skin, deeper green, purple magic accent
			"palette": [T, Color(0.06, 0.12, 0.06), Color(0.15, 0.3, 0.15), Color(0.28, 0.45, 0.28), PALE, PALE_SHADOW, Color(0.12, 0.22, 0.12), Color(0.55, 0.2, 0.6)],
		},
		{
			"name": "Alchemist",
			"grid": GRID_CLOTHED,
			"step_grid": GRID_CLOTHED_STEP,
			"grid_up": GRID_CLOTHED_UP,
			"step_grid_up": GRID_CLOTHED_UP_STEP,
			"grid_left": GRID_CLOTHED_LEFT,
			"step_grid_left": GRID_CLOTHED_LEFT_STEP,
			# Yellow outfit, tan skin, yellow-green pants, green potion accent
			"palette": [T, Color(0.4, 0.35, 0.08), Color(0.85, 0.78, 0.2), Color(0.95, 0.9, 0.4), TAN, TAN_SHADOW, Color(0.7, 0.65, 0.15), Color(0.3, 0.6, 0.2)],
		},
	]
