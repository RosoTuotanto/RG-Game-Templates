-- The Menu button in the top-right corner of the screen.

local menuButton = {}

---------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local screen = require( "classes.screen" )
local settings = require( "libs.settings" )
local audioHandles = require( "libs.audioHandles" )
local widget = require( "widget" )

---------------------------------------------------------------------------
-- Private functions

local function placeInCorner( button )
	local config = settings.menuButton
	button.x = screen.maxX - config.margin - config.frameWidth * 0.5
	button.y = screen.minY + config.margin + config.frameHeight * 0.5
end

-- screen.lua also listens for resize, and the two listeners can run in either order,
-- so screen.update() refreshes the screen sizes before they are read.
local function onResize( button )
	screen.update()
	placeInCorner( button )
end

local function onFinalize( event )
	Runtime:removeEventListener( "resize", event.target )
end

---------------------------------------------------------------------------
-- Public functions

function menuButton.new( params )
	local config = settings.menuButton
	local onPress = params.onPress

	local sheet = graphics.newImageSheet( config.filename, {
		width = config.frameWidth,
		height = config.frameHeight,
		numFrames = 2,
	} )

	local button = widget.newButton( {
		id = "menu",
		sheet = sheet,
		defaultFrame = 1,
		overFrame = 2,
		width = config.frameWidth,
		height = config.frameHeight,
		label = "Menu",
		labelAlign = "center",
		labelColor = { default = { 0.9 }, over = { 1 } },
		font = settings.fonts.bold,
		fontSize = config.fontSize,
		onEvent = function( event )
			if event.phase == "ended" then
				audio.play( audioHandles.click )
				onPress()
			end
			return true
		end,
	} )

	params.parent:insert( button )
	placeInCorner( button )

	-- Runtime calls button.resize( button, event ) on every resize event.
	button.resize = onResize
	Runtime:addEventListener( "resize", button )
	button:addEventListener( "finalize", onFinalize )

	return button
end

return menuButton
