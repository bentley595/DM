# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Who I'm Working With

The user is a 13-year-old who is learning to code. When explaining things:
- Explain **why** something works, not just what to type
- Break down new concepts in plain language before using them
- Point out patterns that will be useful to recognize in the future
- It's okay to go a bit slower and be more thorough with explanations

## Project Overview

This is a **Godot 4.6** game project called "DM". It uses GDScript as its scripting language.

## Engine Configuration

- **Renderer**: Forward Plus
- **Graphics Driver (Windows)**: Direct3D 12
- **Physics Engine**: Jolt Physics (third-party replacement for Godot's built-in physics)

## Running the Project

- **Open in editor**: Open `project.godot` with Godot 4.6
- **Run from CLI**: `godot --path .`
- **Export/Build**: Use Godot editor's File > Export menu

## Architecture

Godot projects follow a scene-tree architecture:
- **Scenes** (`*.tscn`) define node hierarchies and are the building blocks of the game
- **Scripts** (`*.gd`) attach to nodes to add behavior via GDScript
- **Resources** (`*.tres`) store reusable data objects
- `project.godot` is the root configuration file — all project settings live here
- The `.godot/` directory contains engine cache and imported assets (not version-controlled)

## Key Files

### Data
- `scripts/character_data.gd` — All 20 character definitions (grids, palettes, directional sprites). Pure data file with no node attachment. Other scripts access it via `preload("res://scripts/character_data.gd")`.

### Sprite System
- `scripts/character_sprite.gd` — Pixel-art renderer that draws characters from 2D grid arrays + color palettes. Supports 4-direction facing (down/up/left/right) and 4-frame walk animation at 6 fps.
  - `set_character(character: Dictionary)` — pass a whole character dict from CharacterData
  - `set_facing(dir: String)` — swap to a direction's grids ("down", "up", "left", "right")
  - `set_walking(bool)` — toggle walk animation on/off
  - Right-facing sprites are auto-computed by mirroring left-facing grids

### Screens (scene flow)
- `scenes/file_select.tscn` → `scenes/character_select.tscn` → `scenes/name_entry.tscn` → `scenes/game.tscn`
- Data passes between scenes via `get_tree().set_meta()` / `get_tree().get_meta()`
  - `"selected_character_index"` (int) — which of the 20 characters was picked
  - `"player_name"` (String) — the name the player typed

### Player
- `scripts/player.gd` — Movement (WASD/arrows), screen bounds clamping, facing direction logic (horizontal wins diagonal ties), passes movement state to CharacterSprite.

## Sprite Grid Format

Each character grid is a 14×20 2D array. Color indices:
- 0=transparent, 1=outline, 2=primary, 3=highlight, 4=skin, 5=skin shadow, 6=secondary, 7=accent

4 body templates: ARMORED, ROBED, LIGHT, CLOTHED — each has grids for down/up/left (idle + step). Right is mirrored from left at runtime.

Walk cycle frame 3 for left/right directions uses `_build_composite()` to avoid the double-mirror head-flip bug (mirroring a step grid flips the head too, so we composite the correct head with mirrored legs).

## Conventions

- Line endings are normalized to LF (`.gitattributes`)
- File encoding is UTF-8 (`.editorconfig`)
- The `.godot/` directory and `/android/` are gitignored
