-- The inventory button in the top-left corner of the screen, for a game played with the mouse.

local inventoryButton = {}

---------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local screen = require( "classes.screen" )
local settings = require( "libs.settings" )
local audioHandles = require( "libs.audioHandles" )
local widget = require( "widget" )

---------------------------------------------------------------------------
-- Private functions

local function placeInCorner( button )
	button.x, button.y = inventoryButton.getPosition()
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

function inventoryButton.new( params )
	local config = settings.inventoryButton
	local onPress = params.onPress

	local sheet = graphics.newImageSheet( config.filename, {
		width = config.frameWidth,
		height = config.frameHeight,
		numFrames = 2,
	} )

	-- The frames are drawn at the button's size, so a larger image only makes the button sharper.
	local button = widget.newButton( {
		id = "inventory",
		sheet = sheet,
		defaultFrame = 1,
		overFrame = 2,
		width = config.size,
		height = config.size,
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


-- The centre of the button, so the scene can place things beside it. The button uses the Menu button's
-- margin, so the two top corners match. The position is worked out from the screen, so it is right even
-- before the button has followed a resize.
function inventoryButton.getPosition()
	local size = settings.inventoryButton.size
	local margin = settings.menuButton.margin
	return screen.minX + margin + size * 0.5, screen.minY + margin + size * 0.5
end

return inventoryButton
