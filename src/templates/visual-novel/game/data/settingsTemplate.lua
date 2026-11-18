-- Visual novel template settings. Overrides data/settingsCore.lua.
-- Merge rules: key-value tables merge per key, array-style lists are
-- replaced wholesale (see libs/settings.lua).

return {
	menu = {
		-- Show the full menu, including save/load and credits.
		buttons = { "play", "load", "options", "credits", "exit" },
	},

	-- The visual novel is mouse-driven: the only keyboard actions are the
	-- inventory and the pause menu. This list replaces core's list wholesale.
	controls = {
		{ id = "inventory", label = "Inventory", keys = { "i" } },
		{ id = "menu", label = "Menu", keys = { "escape" } },
	},

	-------------------------------------
	-- Inventory (classes/inventory.lua and widgets/inventoryPanel.lua):

	inventory = {
		-- The image sheet the item icons come from, by the frame data/items.lua gives each item.
		itemSheet = {
			filename = "assets/images/items.png",
			frameWidth = 64,
			frameHeight = 64,
			frameCount = 1,
		},

		-- The visual novel has no arrow keys, so an empty slot tells the player to click the slots instead.
		emptySlotDescription = "Click a slot to see what it holds.",
	},

	-------------------------------------
	-- Visual novel game (scenes/game.lua):

	visualNovel = {
		-- The name Spyric Story Weaver knows the story by. Saves store it with the game state.
		storyName = "Template Story",

		-- The Twine story exported to JSON, as a path from the project folder.
		storyFile = "data/templateStory.json",

		-- The passage a new game starts at.
		startPassage = "start",

		-- Music that plays while the story is on screen. The menu brings back its own music.
		music = "assets/audio/music/story.mp3",

		-- Backgrounds are drawn at this size, then scaled to cover the screen and centred.
		background = {
			width = 1920,
			height = 1080,
		},

		-- The text box along the bottom of the screen that holds the story text and its links.
		textBox = {
			height = 170,
			color = { 0, 0.7 },

			-- Space between the box's top and side edges and the text.
			padding = 20,

			fontSize = 24,
			linkColor = { 0.9, 0.67, 0.1 },

			-- Space between a link and the text or link above it.
			linkSpacing = 16,
		},

		characters = {
			-- A character image is <folder><name>-<expression>.png.
			folder = "assets/images/characters/",

			-- The size the character images are drawn at; the on-screen height keeps their shape.
			imageWidth = 720,
			imageHeight = 1080,
			height = 520,

			-- The expression <<character, show, name>> uses when it names none.
			defaultExpression = "default",

			-- Where a character stands, as a fraction of the screen width from its left edge.
			positions = {
				left = 0.25,
				center = 0.5,
				right = 0.75,
			},
			defaultPosition = "center",

			-- How far a character slides in from its side of the screen when it enters.
			enterDistance = 80,

			-- Animation times in milliseconds: entering, the pop on an expression switch, moving to another position, and leaving.
			enterTime = 350,
			switchTime = 200,
			moveTime = 350,
			leaveTime = 300,

			-- How much larger a character starts the pop on an expression switch.
			switchScale = 1.06,
		},

		-- The money display beside the inventory button in the top-left corner. The amount is the story
		-- variable $money, which <<money, 50>> raises and <<money, -50>> lowers.
		money = {
			-- How the amount is written, beside the button and in the inventory; %d is the amount.
			format = "$ %d",

			fontSize = 24,

			-- The dark plate behind the amount keeps it readable on light and dark backgrounds.
			plateColor = { 0, 0.7 },

			-- How round the plate's corners are; 0 gives square corners.
			plateCornerRadius = 10,

			-- Space between the plate's edges and the amount, and between the inventory button and the plate.
			platePadding = 12,
			gap = 8,
		},

		-- The minigames <<minigame, name>> runs, each by its module name in classes/minigames/.
		minigames = {
			targetPractice = {
				-- Length of a round in seconds.
				duration = 10,

				-- Hits the player needs for $targetGoalReached to be true.
				goal = 6,

				-- Milliseconds a target stays before it disappears unhit.
				targetLifetime = 1100,

				-- Milliseconds between one target leaving and the next appearing.
				spawnDelay = 250,

				-- Milliseconds the hit image takes to fade out.
				hitFadeTime = 250,

				targetImage = "assets/images/minigame/target.png",
				hitImage = "assets/images/minigame/target-hit.png",
				targetSize = 96,

				-- The closest a target's centre comes to the screen's sides and bottom, and to its top, which leaves room for the counters and the Menu button.
				edgeMargin = 70,
				topMargin = 120,

				-- The counters in the top-left corner and at the top centre: their distance from the screen edge, size and text.
				hudMargin = 20,
				hudFontSize = 28,
				counterText = "Hits: %d / %d",
				clockText = "Time: %d",
			},
		},
	},
}
