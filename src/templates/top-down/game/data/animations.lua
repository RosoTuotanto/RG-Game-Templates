-- Image sheet layouts and animation timings for the characters on the maps.

-- How many milliseconds one full walk loop of four frames takes. A smaller value makes the hero step faster.
local walkLoopTime = 600

return {
	-- The hero's image sheet: 5 columns and 3 rows of 64x96 frames. The rows face south, north
	-- and west. Column 1 is the idle frame and columns 2 to 5 are the walk loop.
	heroSheet = {
		filename = "assets/images/template/characters/hero.png",

		-- The row of pixels in a frame, counted from its top, where the middle of the hero's feet is.
		-- The hero's position and physics body sit on this row, so the hero sorts and collides by its feet.
		feetY = 84,

		options = {
			width = 64,
			height = 96,
			numFrames = 15,
			sheetContentWidth = 320,
			sheetContentHeight = 288,
		},
	},

	-- The NPC pictures in maps/characters.png: 64x96 frames in one row. An NPC object's frame
	-- property picks one. The feet sit on the same row of pixels as the hero's.
	characterSheet = {
		filename = "maps/characters.png",
		feetY = 84,

		options = {
			width = 64,
			height = 96,
			numFrames = 3,
			sheetContentWidth = 192,
			sheetContentHeight = 96,
		},
	},

	-- The hero's animation sequences. A frame's number is ( row - 1 ) * 5 + column, so each row
	-- starts at frame 1, 6 or 11. East has no row of its own: the hero plays the west sequences mirrored.
	heroSequences = {
		{ name = "idleSouth", start = 1, count = 1 },
		{ name = "walkSouth", start = 2, count = 4, time = walkLoopTime, loopCount = 0 },

		{ name = "idleNorth", start = 6, count = 1 },
		{ name = "walkNorth", start = 7, count = 4, time = walkLoopTime, loopCount = 0 },

		{ name = "idleWest", start = 11, count = 1 },
		{ name = "walkWest", start = 12, count = 4, time = walkLoopTime, loopCount = 0 },
	},

	-- The small hop an NPC makes when the player talks to it.
	npcBounce = {
		-- How many content units the NPC rises.
		height = 16,

		-- Milliseconds the rise takes.
		upTime = 110,

		-- Milliseconds the drop back down takes.
		downTime = 130,
	},
}
