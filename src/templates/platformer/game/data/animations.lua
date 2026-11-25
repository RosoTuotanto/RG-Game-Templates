-- The hero's image sheet layout and animation timings.

return {
	-- The hero's image sheet: 8 columns and 5 rows of 96x96 frames. The rows are idle (4 frames),
	-- run (8), jump (2), fall (2) and climb (4). The hero faces right and is mirrored to face left.
	heroSheet = {
		filename = "assets/images/template/characters/hero.png",

		-- The row of pixels in a frame, counted from its top, where the hero's feet are. The physics body stands on it.
		feetY = 96,

		options = {
			width = 96,
			height = 96,
			numFrames = 40,
			sheetContentWidth = 768,
			sheetContentHeight = 480,
		},
	},

	-- The hero's animation sequences. A frame's number is ( row - 1 ) * 8 + column, so the rows start
	-- at frames 1, 9, 17, 25 and 33. time is the milliseconds one loop of the sequence takes.
	heroSequences = {
		{ name = "idle", start = 1, count = 4, time = 800, loopCount = 0 },
		{ name = "run", start = 9, count = 8, time = 400, loopCount = 0 },
		{ name = "jump", start = 17, count = 2, time = 200, loopCount = 0 },
		{ name = "fall", start = 25, count = 2, time = 200, loopCount = 0 },
		{ name = "climb", start = 33, count = 4, time = 500, loopCount = 0 },
	},

	-- The NPC's image sheet: 4 columns and 2 rows of 96x96 frames. The rows are idle (4 frames)
	-- and raising an arm (4). She faces right and is mirrored to face left.
	npcSheet = {
		filename = "assets/images/template/characters/npc.png",

		-- The row of pixels in a frame, counted from its top, where her feet are.
		feetY = 96,

		options = {
			width = 96,
			height = 96,
			numFrames = 8,
			sheetContentWidth = 384,
			sheetContentHeight = 192,
		},
	},

	-- The NPC's animation sequences. The rows start at frames 1 and 5. raise plays once and stops
	-- on its last frame, the pose she holds while talking, and lower plays the same frames backward.
	npcSequences = {
		{ name = "idle", start = 1, count = 4, time = 800, loopCount = 0 },
		{ name = "raise", start = 5, count = 4, time = 300, loopCount = 1 },
		{ name = "lower", frames = { 8, 7, 6, 5 }, time = 300, loopCount = 1 },
	},
}
