# Test song for PIXEL DUNGEON Music Player
# A simple 4-bar melody to verify the music system works!
#
# This file was hand-written as a test. Normally you'd export these
# from the piano roll tool (tools/piano_roll.html).
extends RefCounted

const SONG_DATA: Dictionary = {
	"name": "test_song",
	"bpm": 120,
	"beats_per_bar": 4,
	"subdivisions": 4,
	"total_bars": 4,
	"tracks": [
		{
			"name": "Lead",
			"waveform": "square",
			"volume": 0.6,
			"notes": [
				# Bar 1: C4 - E4 - G4 - C5 (simple ascending arpeggio)
				[60, 0, 2], [64, 2, 2], [67, 4, 2], [72, 6, 2],
				# Bar 2: B4 - G4 - E4 - D4
				[71, 8, 2], [67, 10, 2], [64, 12, 2], [62, 14, 2],
				# Bar 3: repeat bar 1
				[60, 16, 2], [64, 18, 2], [67, 20, 2], [72, 22, 2],
				# Bar 4: G4 held, then resolve to C4
				[67, 24, 4], [64, 28, 2], [60, 30, 4]
			]
		},
		{
			"name": "Bass",
			"waveform": "triangle",
			"volume": 0.7,
			"notes": [
				# Simple bass: root notes on each bar, held for full bar
				[48, 0, 16],   # C3 for bars 1-2 (held long)
				[48, 16, 8],   # C3 for bar 3
				[43, 24, 8]    # G2 for bar 4
			]
		}
	],
	"tempo_changes": [[0, 120]]
}
