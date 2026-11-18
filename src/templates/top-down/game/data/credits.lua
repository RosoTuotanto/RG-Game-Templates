-- Credits configuration and data.
-- All values are scaled for the 960x640 content area.
-- Templates and game projects overwrite this file with their own credits.

local settings = require( "libs.settings" )

return {
	-- Configuration section - all scene parameters.
	config = {
		-- How many milliseconds for full scroll animation.
		scrollSpeed = 20000,

		-- How many milliseconds the credits text takes to fade out after the scroll reaches its end.
		-- Touching the credits brings the text back. Set to 0 to keep the text visible.
		endFadeTime = 1500,

		-- ScrollView configuration.
		scrollView = {
			top = 120,
			width = 800,
			height = 420,
			scrollHeight = 1600,
			bottomPadding = 100,
			backgroundColor = { 0, 0.8 }
		},

		-- Title configuration. The title font and colour are shared by every view title (widgets/sceneTitle.lua).
		title = {
			text = "Credits",
			yOffset = 44
		},

		-- Back button configuration.
		backButton = {
			label = "Back",
			labelAlign = "center",
			fontSize = 28,
			font = settings.fonts.bold,
			labelColor = { default={ 0.9 }, over={ 1 } },
			fillColor = { default={ 0, 0.7 }, over={ 0, 0.9 } },
			shape = "rect",
			width = 120,
			height = 52,
			xOffset = 10,
			yOffset = 10
		}
	},

	-- Credits entries - each entry has its own styling.
	-- Add, remove or modify the credits to suit your team and project.
	entries = {
		{ text = "", font = settings.fonts.regular, fontSize = 30, color = { 1, 1, 1 }, padding = 2 },
		{ text = "ROSO GAMES", font = settings.fonts.regular, fontSize = 32, color = { 240/255, 220/255, 0 }, padding = 2 },
		{ text = "", font = settings.fonts.regular, fontSize = 30, color = { 1, 1, 1 }, padding = 2 },
		{ text = "", font = settings.fonts.regular, fontSize = 30, color = { 1, 1, 1 }, padding = 2 },

		{ text = "GAME NAME", font = settings.fonts.regular, fontSize = 40, color = { 240/255, 220/255, 0 }, padding = 2 },
		{ text = "", font = settings.fonts.regular, fontSize = 30, color = { 1, 1, 1 }, padding = 2 },
		{ text = "", font = settings.fonts.regular, fontSize = 30, color = { 1, 1, 1 }, padding = 2 },

		{ text = "PROGRAMMING", font = settings.fonts.regular, fontSize = 28, color = { 240/255, 220/255, 0 }, padding = 2 },
		{ text = "Name #1", font = settings.fonts.regular, fontSize = 24, color = { 1, 1, 1 }, padding = 2 },
		{ text = "Name #2", font = settings.fonts.regular, fontSize = 24, color = { 1, 1, 1 }, padding = 2 },
		{ text = "Name #3", font = settings.fonts.regular, fontSize = 24, color = { 1, 1, 1 }, padding = 2 },
		{ text = "", font = settings.fonts.regular, fontSize = 30, color = { 1, 1, 1 }, padding = 2 },

		{ text = "GAME DESIGN", font = settings.fonts.regular, fontSize = 28, color = { 240/255, 220/255, 0 }, padding = 2 },
		{ text = "Name #1", font = settings.fonts.regular, fontSize = 24, color = { 1, 1, 1 }, padding = 2 },
		{ text = "Name #2", font = settings.fonts.regular, fontSize = 24, color = { 1, 1, 1 }, padding = 2 },
		{ text = "Name #3", font = settings.fonts.regular, fontSize = 24, color = { 1, 1, 1 }, padding = 2 },
		{ text = "Name #4", font = settings.fonts.regular, fontSize = 24, color = { 1, 1, 1 }, padding = 2 },
		{ text = "", font = settings.fonts.regular, fontSize = 30, color = { 1, 1, 1 }, padding = 2 },

		{ text = "LEVEL DESIGN", font = settings.fonts.regular, fontSize = 28, color = { 240/255, 220/255, 0 }, padding = 2 },
		{ text = "Name #1", font = settings.fonts.regular, fontSize = 24, color = { 1, 1, 1 }, padding = 2 },
		{ text = "Name #2", font = settings.fonts.regular, fontSize = 24, color = { 1, 1, 1 }, padding = 2 },
		{ text = "", font = settings.fonts.regular, fontSize = 30, color = { 1, 1, 1 }, padding = 2 },

		{ text = "ART", font = settings.fonts.regular, fontSize = 28, color = { 240/255, 220/255, 0 }, padding = 2 },
		{ text = "Name #1", font = settings.fonts.regular, fontSize = 24, color = { 1, 1, 1 }, padding = 2 },
		{ text = "Name #2", font = settings.fonts.regular, fontSize = 24, color = { 1, 1, 1 }, padding = 2 },
		{ text = "Name #3", font = settings.fonts.regular, fontSize = 24, color = { 1, 1, 1 }, padding = 2 },
		{ text = "", font = settings.fonts.regular, fontSize = 30, color = { 1, 1, 1 }, padding = 2 },

		{ text = "STORY", font = settings.fonts.regular, fontSize = 28, color = { 240/255, 220/255, 0 }, padding = 2 },
		{ text = "Name #1", font = settings.fonts.regular, fontSize = 24, color = { 1, 1, 1 }, padding = 2 },
		{ text = "Name #2", font = settings.fonts.regular, fontSize = 24, color = { 1, 1, 1 }, padding = 2 },
		{ text = "", font = settings.fonts.regular, fontSize = 30, color = { 1, 1, 1 }, padding = 2 },

		{ text = "MUSIC & AUDIO", font = settings.fonts.regular, fontSize = 28, color = { 240/255, 220/255, 0 }, padding = 2 },
		{ text = "Name #1", font = settings.fonts.regular, fontSize = 24, color = { 1, 1, 1 }, padding = 2 },
		{ text = "", font = settings.fonts.regular, fontSize = 30, color = { 1, 1, 1 }, padding = 2 },

		{ text = "GAME PRODUCERS", font = settings.fonts.regular, fontSize = 28, color = { 240/255, 220/255, 0 }, padding = 2 },
		{ text = "Name #1", font = settings.fonts.regular, fontSize = 24, color = { 1, 1, 1 }, padding = 2 },
		{ text = "Name #2", font = settings.fonts.regular, fontSize = 24, color = { 1, 1, 1 }, padding = 2 },
		{ text = "", font = settings.fonts.regular, fontSize = 30, color = { 1, 1, 1 }, padding = 2 },

		{ text = "THIRD-PARTY ASSETS", font = settings.fonts.regular, fontSize = 28, color = { 240/255, 220/255, 0 }, padding = 2 },
		{ text = "List any 3rd party assets the game uses below", font = settings.fonts.regular, fontSize = 24, color = { 1, 1, 1 }, padding = 2 },
		{ text = "", font = settings.fonts.regular, fontSize = 30, color = { 1, 1, 1 }, padding = 2 },
		{ text = "", font = settings.fonts.regular, fontSize = 30, color = { 1, 1, 1 }, padding = 2 },
		{ text = "", font = settings.fonts.regular, fontSize = 30, color = { 1, 1, 1 }, padding = 2 },
	}
}
