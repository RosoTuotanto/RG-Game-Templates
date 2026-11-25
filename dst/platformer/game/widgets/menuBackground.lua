-- A full-screen menu background image that pans slowly in random directions.

local menuBackground = {}

---------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local screen = require( "classes.screen" )
local settings = require( "libs.settings" )

---------------------------------------------------------------------------
-- Private functions

-- Move the image to a random spot and start the next move when it arrives.
-- The top-left corner stays between 0 and 2 * panSlack outside the screen's top-left corner,
-- so art at the image's top-left stays in view and the image edges never show.
local function pan( image )
	local config = settings.menu.background
	local travel = config.panSlack * 2

	transition.to( image, {
		time = config.panTime,
		x = screen.minX - math.random( 0, travel ),
		y = screen.minY - math.random( 0, travel ),
		transition = config.panEasing,
		onComplete = pan,
	} )
end

-- Cover the screen plus panSlack on every side, and put the top-left corner panSlack outside the screen's top-left corner.
local function fitToScreen( image )
	local config = settings.menu.background
	display.scaleDisplayObject( image, screen.width + config.panSlack * 2, screen.height + config.panSlack * 2 )
	image.x = screen.minX - config.panSlack
	image.y = screen.minY - config.panSlack
end

-- When the screen size changes, fit the image to the new size and start panning again from its resting place.
-- screen.lua also listens for resize, and the two listeners can run in either order,
-- so screen.update() refreshes the screen sizes before they are read.
local function onResize( image )
	screen.update()
	transition.cancel( image )
	fitToScreen( image )
	pan( image )
end

local function onFinalize( event )
	transition.cancel( event.target )
	Runtime:removeEventListener( "resize", event.target )
end

---------------------------------------------------------------------------
-- Public functions

function menuBackground.new( parent )
	local config = settings.menu.background
	local image = display.newImage( parent, config.filename )
	image.anchorX, image.anchorY = 0, 0
	fitToScreen( image )

	-- Runtime calls image.resize( image, event ) on every resize event.
	image.resize = onResize
	Runtime:addEventListener( "resize", image )

	image:addEventListener( "finalize", onFinalize )
	pan( image )

	return image
end

return menuBackground
