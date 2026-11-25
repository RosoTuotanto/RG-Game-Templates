-- Platformer template settings. Overrides data/settingsCore.lua.
-- Merge rules: key-value tables merge per key, array-style lists are
-- replaced wholesale (see libs/settings.lua).

return {
	-- Sample image sheet frames slightly inside their edges, so neighbouring tiles do not bleed into the map's tiles.
	sampleImageSheetsInsideFrame = true,

	menu = {
		-- Show the full menu, including save/load and credits.
		buttons = { "play", "load", "options", "credits", "exit" },
	},

	-- The game's keyboard actions, in the order they appear in the options scene.
	-- The first key of each action is fixed; the player can rebind the second key in the options.
	-- Up climbs ropes, enters doors and talks to characters, and down climbs down ropes.
	controls = {
		{ id = "up", label = "Up", keys = { "up", "w" } },
		{ id = "down", label = "Down", keys = { "down", "s" } },
		{ id = "left", label = "Left", keys = { "left", "a" } },
		{ id = "right", label = "Right", keys = { "right", "d" } },
		{ id = "jump", label = "Jump", keys = { "space" } },
		{ id = "inventory", label = "Inventory", keys = { "i" } },
		{ id = "menu", label = "Menu", keys = { "escape" } },
	},

	-------------------------------------
	-- Platformer game (scenes/game.lua and classes/):

	platformer = {
		-- The area a new game starts in, as a file name in assets/maps/ without the .json ending.
		startArea = "outdoor",

		-- The object on the start area's objects layer where a new game puts the hero.
		startSpawn = "start",

		-- How strongly gravity pulls everything down, in metres per second squared (Solar2D draws 30 content units per metre).
		gravity = 30,

		-- How far below the map's bottom edge, in content units, the hero may fall before being put back at the last door or spawn.
		fallMargin = 96,

		hero = {
			-- Running speed, in content units per second.
			runSpeed = 300,

			-- Climbing speed on a rope, in content units per second.
			climbSpeed = 200,

			-- The upward speed a jump starts with, in content units per second. A larger value jumps higher.
			jumpSpeed = 560,

			-- How many jumps the hero may make before landing again. 2 gives the double jump.
			maxJumps = 2,

			-- How far, in content units, the hero's feet may be below a platform's top and still count as standing on it.
			landingTolerance = 8,

			-- The physics body: a box with its corners cut off, standing on the feet of the hero sheet's frame, in content units.
			-- The cut corners let the hero slide over the joins between tiles.
			body = {
				width = 24,
				height = 90,
				cornerCut = 4,

				-- How far above and below the feet the ground sensor reaches. It finds the ground the hero stands on.
				footSensorDepth = 4,

				density = 1,
			},
		},

		trampoline = {
			-- How many times the normal jump speed a jump off a trampoline starts with.
			jumpMultiplier = 1.5,

			-- Milliseconds the trampoline shows its pressed frame after a jump.
			pressedTime = 250,
		},

		spikes = {
			-- The share of the tile's width and height, measured from its bottom edge, that touching hurts.
			widthShare = 0.8,
			heightShare = 0.5,
		},

		-- How the camera follows the hero (classes/camera.lua, camera.setTarget). A positive yOffset keeps
		-- the hero below the screen's centre, so more of the area above is in view.
		camera = {
			smoothing = 0.15,
			yOffset = 48,
		},

		-- The backdrop images drawn behind the map, from the farthest to the nearest. Each image repeats
		-- sideways and moves at parallax times the camera's speed: 0 stays still, 1 moves with the map.
		-- NOTE: This is a list, so a project must restate the full list.
		backdrop = {
			{ filename = "assets/images/template/backgrounds/backdrop-far.png", width = 1024, height = 640, parallax = 0.2 },
			{ filename = "assets/images/template/backgrounds/backdrop-near.png", width = 1024, height = 640, parallax = 0.5 },
		},

		-- The music file each area plays, by area name. Areas that share a file keep the music playing between them.
		music = {
			outdoor = "assets/audio/template/music/outdoors.mp3",
			indoor = "assets/audio/template/music/indoors.mp3",
			room = "assets/audio/template/music/indoors.mp3",
		},

		-- The areas drawn without the backdrop, by area name, such as room = true. The screen around
		-- a map smaller than the screen is black in them.
		noBackdrop = {
			room = true,
		},

		item = {
			-- The width and height, in content units, of an item lying on the map. It rests on its object's bottom edge.
			size = 40,
		},

		-- The bubble over a map object that has a prompt property, such as "{up}: talk". {up} becomes
		-- the keys of the up action in controls above, so the bubble follows the player's key bindings.
		prompt = {
			-- The bubble's colour, as red, green and blue from 0 to 1, and how see-through it is (0 invisible, 1 solid).
			boxColor = { 0.12, 0.13, 0.18 },
			boxAlpha = 0.85,

			-- How round the bubble's corners are, in content units.
			cornerRadius = 6,

			-- The space between the text and the bubble's left and right edges, and the bubble's height, in content units.
			paddingX = 10,
			height = 26,

			textSize = 18,

			-- How far above the object's top edge the bubble's centre is, in content units.
			offset = 18,

			-- The largest sideways gap between the hero's body and the object, in content units, at which the bubble
			-- shows. A larger value shows it from further to the side. Talking to a character uses the same reach.
			reachX = 28,

			-- The largest vertical gap between the hero's body and the object, in content units. 0 shows the bubble
			-- only while the body overlaps the object vertically, and a larger value shows it from further above or below.
			reachY = 0,
		},
	},

	-------------------------------------
	-- Dialogue (classes/dialogue.lua):

	-- The story file and the name Spyric Story Weaver knows it by. The name becomes part of Lua code,
	-- so it may hold letters, digits and spaces but no dashes or other punctuation.
	story = {
		name = "Template Story",
		source = "data/templateStory.json",
	},

	-------------------------------------
	-- Inventory (classes/inventory.lua and widgets/inventoryPanel.lua):

	inventory = {
		-- The image sheet the item icons come from. The map's item objects draw from it too, by their frame property.
		itemSheet = {
			filename = "assets/images/template/items.png",
			frameWidth = 64,
			frameHeight = 64,
			frameCount = 1,
		},
	},

	-------------------------------------
	-- Keyboard controls tooltip in the bottom left corner (widgets/hints.lua):

	hints = {
		-- Whether the tooltip shows. false hides it.
		enabled = true,

		-- Each row lists the keys of the actions in controls above, followed by the label.
		rows = {
			{ actions = { "left", "right" }, label = "Move" },
			{ actions = { "jump" }, label = "Jump" },
			{ actions = { "up" }, label = "Enter doors and talk" },
			{ actions = { "inventory" }, label = "Inventory" },
			{ actions = { "menu" }, label = "Menu" },
		},
	},
}
