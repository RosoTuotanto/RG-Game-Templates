-- Top-down template settings. Overrides data/settingsCore.lua.
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
	controls = {
		{ id = "up", label = "Up", keys = { "up", "w" } },
		{ id = "down", label = "Down", keys = { "down", "s" } },
		{ id = "left", label = "Left", keys = { "left", "a" } },
		{ id = "right", label = "Right", keys = { "right", "d" } },
		{ id = "interact", label = "Interact", keys = { "space", "e" } },
		{ id = "inventory", label = "Inventory", keys = { "i" } },
		{ id = "menu", label = "Menu", keys = { "escape" } },
	},

	-------------------------------------
	-- Top-down game (scenes/game.lua and maps/extensions/):

	topDown = {
		-- The map a new game starts on, as a file name in maps/ without the .json ending.
		startMap = "outdoor1",

		-- How fast the hero walks, in content units per second. The maps' tiles are 64 units wide.
		heroSpeed = 320,

		-- The radius of the hero's round physics body, centred on the hero's feet, in content units.
		heroBodyRadius = 24,

		-- How far in front of the hero the interact key looks, in content units, measured from the
		-- edge of the hero's body along the way the hero faces, so the hero's size does not change it.
		-- A larger value reaches further ahead.
		interactReach = 8,

		-- How close the edge of a character's, a sign's or an item's body must be to that point, in
		-- content units, for the interact key to use it. A larger value forgives standing further away
		-- or a little to the side; a smaller value needs the hero to stand closer and face the object squarely.
		interactRadius = 16,

		-- The hero's line when the interact key finds an item but the inventory is full.
		inventoryFullMessage = "You: My inventory is full.",

		-- The music file each map plays, by map name.
		music = {
			outdoor1 = "assets/audio/template/music/outdoors.mp3",
			outdoor2 = "assets/audio/template/music/outdoors.mp3",
			indoor1 = "assets/audio/template/music/indoors.mp3",
		},

		-- The colour, as red, green and blue from 0 to 1, that fills the screen behind a map
		-- narrower or shorter than the screen, by map name, such as outdoor2 = { 0.5, 0.5, 0.5 }.
		-- A map without a colour has a black background.
		mapBackground = {},
	},

	-------------------------------------
	-- Dialogue (classes/dialogue.lua):

	-- The story file and the name Spyric Story Weaver knows it by. The name becomes part of Lua code,
	-- so it may hold letters, digits and spaces but no dashes or other punctuation.
	story = {
		name = "Template Story",
		source = "data/templateStory.json",

		-- The passage a new game opens once the first map is on the screen.
		introPassage = "intro",

		-- The passage an NPC opens when its Tiled object has no node property.
		npcPassage = "npcBackground",
	},

	-------------------------------------
	-- Inventory (classes/inventory.lua and widgets/inventoryPanel.lua):

	inventory = {
		-- The item ids from data/items.lua that a new game puts in the inventory.
		startingItems = { "note" },

		-- The image sheet the item icons come from. The map's item objects draw from it too, by their frame property.
		itemSheet = {
			filename = "maps/items.png",
			frameWidth = 64,
			frameHeight = 64,
			frameCount = 3,
		},
	},

	-------------------------------------
	-- Keyboard controls tooltip in the bottom left corner (widgets/hints.lua):

	hints = {
		-- Whether the tooltip shows. false hides it.
		enabled = true,

		-- Each row lists the keys of the actions in controls above, followed by the label.
		rows = {
			{ actions = { "up", "left", "down", "right" }, label = "Move" },
			{ actions = { "interact" }, label = "Interact" },
			{ actions = { "inventory" }, label = "Inventory" },
		},
	},
}
