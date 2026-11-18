-- Core game settings. These are the defaults for every RG project.
-- A template overrides these via data/settingsTemplate.lua.
-- Merge rules: key-value tables merge per key, array-style lists are
-- replaced wholesale (see libs/settings.lua).
-- NOTE: Per-developer launch flags (debugMode, gotoScene, etc.) do not
-- belong here. They go into data/launchParams.json, which is gitignored.

return {
	-------------------------------------
	-- General:

	-- Whether or not to suppress runtime errors & messages when not in debug mode.
	-- This should always be set to false during a game's development.
	suppressErrors = false,

	-- Game uses pixel art and should use nearest neighbour scaling instead of linear.
	usesPixelArt = false,

	-- Sample image sheet frames slightly inside their edges, so neighbouring pixels in a sprite sheet
	-- or tileset do not bleed into a frame. Turn on for pixel art that draws tiles from image sheets.
	sampleImageSheetsInsideFrame = false,

	-- The scene that the game enters after the launch screen.
	startScene = "menu",

	-------------------------------------
	-- Fonts:

	-- The regular and bold font of all game text, each a file in a family folder under assets/fonts/.
	fonts = {
		regular = "assets/fonts/Rubik/Rubik-Regular.ttf",
		bold = "assets/fonts/Rubik/Rubik-Medium.ttf",
	},

	-------------------------------------
	-- Launch screen (scenes/launchScreen.lua):

	splashScreen = {
		-- Logo image. Sizes and offsets are in physical pixels: the launch
		-- screen scales them so that the logo looks the same on every device.
		logoFilename = "assets/images/launchScreen/RosoGamesWhiteWeb.png",
		logoWidth = 213,
		logoHeight = 269,
		logoOffsetX = 0,
		logoOffsetY = 0,
		logoAnchorX = 0.5,
		logoAnchorY = 0.5,

		-- Footer text is generated automatically: "(c) <projectYear> Roso Games",
		-- or a year range if the build year is later than projectYear.
		projectYear = 2026,
		fontSize = 24,
		textAlign = "center",
		textWidth = 600,
		textOffsetX = 0,
		textOffsetY = -10,
		textAnchorX = 0.5,
		textAnchorY = 1,

		-- Logo & footer text transition options:
		showDelay = 250,
		showTime = 500,
		showEasing = easing.inOut,
		hideDelay = 1250,
		hideTime = 250,
		hideEasing = easing.inOut,
	},

	-------------------------------------
	-- Menu (scenes/menu.lua):

	menu = {
		-- Menu buttons, in the order they are shown.
		-- Valid ids: "play", "load", "options", "credits", "exit".
		-- NOTE: This is a list, so a template must restate the full list.
		-- The exit button is hidden automatically on iOS, tvOS and HTML5.
		buttons = { "play", "options", "exit" },

		-- The scene that the play button opens.
		playScene = "game",

		-- Music that plays in the menu. It keeps playing in the load, options and credits scenes, and fades out when Play or a save slot starts the game.
		music = "assets/audio/music/menuMusic.mp3",

		-- Background image of the menu, credits and load scenes (widgets/menuBackground.lua).
		background = {
			filename = "assets/images/ui/menu.png",

			-- How far, in content units, the image extends past the screen's top and left edges at rest. The pan moves it up to this far from there; 0 keeps it still.
			panSlack = 20,

			-- How long one pan move takes, in milliseconds. A larger value makes the pan slower.
			panTime = 15000,

			-- How each pan move speeds up and slows down.
			panEasing = easing.inOutSine,
		},
	},

	-------------------------------------
	-- Scene titles (widgets/sceneTitle.lua):

	sceneTitle = {
		fontSize = 40,
	},

	-------------------------------------
	-- Save slots (scenes/load.lua):

	saveSlots = {
		-- Distance, in content units, from the top of the screen to the top of the Load or Save title.
		titleTop = 24,

		-- Distance, in content units, from a slot's left, right and bottom edges to its Remove and Load or Save buttons.
		buttonInset = 8,

		-- Message of the panel that shows after the player saves.
		savedText = "Game saved.",

		-- Milliseconds the saved panel stays fully visible before it starts to fade.
		savedHoldTime = 1000,

		-- Milliseconds the saved panel takes to fade out before the game returns.
		savedFadeTime = 300,
	},

	-------------------------------------
	-- Options (scenes/options.lua):

	options = {
		-- Distance, in content units, from just below the tabs to the centre of the Master Volume slider. The other sliders, their labels and the Fullscreen switch move with it.
		audioTop = 82,
	},

	-------------------------------------
	-- Music (classes/music.lua):

	music = {
		-- Milliseconds a track takes to fade out when it stops or another track replaces it.
		fadeOutTime = 1000,

		-- Milliseconds a new track takes to fade in to the player's music volume.
		fadeInTime = 1000,
	},

	-------------------------------------
	-- Menu button (widgets/menuButton.lua):

	menuButton = {
		-- Two frames side by side: the button as it is drawn normally, then while it is pressed.
		filename = "assets/images/ui/menuButton.png",
		frameWidth = 128,
		frameHeight = 48,

		-- Distance, in content units, from the top and right edges of the screen.
		margin = 12,

		fontSize = 24,
	},

	-------------------------------------
	-- Inventory button (widgets/inventoryButton.lua), for a template that opens the inventory with the mouse:

	inventoryButton = {
		-- Two frames side by side: the button as it is drawn normally, then while it is pressed.
		filename = "assets/images/ui/inventoryButton.png",
		frameWidth = 64,
		frameHeight = 64,

		-- The width and height the button is drawn at, in content units. It sits in the top-left corner,
		-- as far from the edges as the Menu button is from its corner.
		size = 48,
	},

	-------------------------------------
	-- Scene transition overlay (classes/transitionOverlay.lua):

	transition = {
		-- Milliseconds the screen takes to fade to black.
		fadeInTime = 400,

		-- Milliseconds the screen takes to fade back in from black.
		fadeOutTime = 400,
	},

	-------------------------------------
	-- Controls (classes/controls.lua and scenes/options.lua):

	-- The game's keyboard actions, in the order they appear in the options
	-- scene. Each action has an id (used in code), a label (shown to the
	-- player), and up to two default keys: { main, secondary }. The main
	-- key is fixed; the player can rebind the secondary key in the options.
	-- NOTE: This is a list, so a template must restate the full list.
	controls = {
		{ id = "up", label = "Up", keys = { "up", "w" } },
		{ id = "down", label = "Down", keys = { "down", "s" } },
		{ id = "left", label = "Left", keys = { "left", "a" } },
		{ id = "right", label = "Right", keys = { "right", "d" } },
		{ id = "interact", label = "Interact", keys = { "space", "e" } },
		{ id = "menu", label = "Menu", keys = { "escape" } },
	},

	-------------------------------------
	-- Keyboard controls tooltip (widgets/hints.lua):

	hints = {
		-- Whether the tooltip shows. false hides it.
		enabled = true,

		-- The tooltip's rows, such as { actions = { "interact" }, label = "Interact" }. Each row
		-- lists the keys of the actions in controls above, followed by the label.
		-- NOTE: This is a list, so a template must restate the full list.
		rows = {},
	},

	-------------------------------------
	-- Inventory (classes/inventory.lua and widgets/inventoryPanel.lua):

	inventory = {
		-- The size of the inventory grid, in slots.
		columns = 4,
		rows = 2,

		-- The item ids from data/items.lua that a new game puts in the inventory.
		-- NOTE: This is a list, so a template must restate the full list.
		startingItems = {},

		-- The image sheet the item icons come from: frames of the same size, numbered from 1.
		-- Each item in data/items.lua names its frame. A template that uses the inventory adds
		-- filename, the path of its image file.
		itemSheet = {
			frameWidth = 64,
			frameHeight = 64,
			frameCount = 1,
		},

		-- The panel's size follows from these, in content units: the grid's slots and the gaps between them,
		-- the space between the panel's edge and its contents, the title's row, and the gaps between the title,
		-- the grid and the info box.
		slotSize = 96,
		slotGap = 18,
		padding = 26,
		titleHeight = 34,
		sectionGap = 18,

		-- The size of an item's icon in its slot, in content units.
		iconSize = 64,

		titleFontSize = 30,
		nameFontSize = 26,
		descriptionFontSize = 20,

		-- How many lines of description the info box holds. A longer description is cut and ends in "...".
		descriptionLines = 4,

		-- The info box's description for an empty slot, which tells the player how to move around the grid.
		emptySlotDescription = "Move the cursor with the arrow keys.",
	},

	-------------------------------------
	-- Dialogue (classes/dialogue.lua):

	-- The story file and the name Spyric Story Weaver knows it by. The name becomes part of Lua code,
	-- so it may hold letters, digits and spaces but no dashes or other punctuation.
	story = {
		name = "Story",
		source = "data/story.json",
	},

	-------------------------------------
	-- Default user settings:

	-- These seed the player's userdata.json on the first launch (or after a
	-- cleanLaunch). On every later launch, a setting the player's file lacks is
	-- added from here, but a value the player already has is never changed: the
	-- options scene modifies userdata.json, never this file.
	defaultUserdata = {
		audio = {
			volume = {
				master = 50, -- master volume affects all channels
				music = 50,
				sfx = 50,
			},
		},

		-- Whether the game starts in fullscreen on desktop platforms. The player can
		-- change it in the options. Starting in a window is easier while developing and testing.
		fullscreen = false,
	},
}
