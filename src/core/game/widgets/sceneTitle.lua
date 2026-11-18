-- The title at the top of the load, save, options, credits and pause views.

local sceneTitle = {}

---------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local settings = require( "libs.settings" )

---------------------------------------------------------------------------
-- Public functions

-- The title hangs from its top edge, so a view can place what follows it at title.y + title.height.
function sceneTitle.new( parent, text, x, top )
	local title = display.newText( {
		parent = parent,
		text = text,
		x = x,
		y = top,
		font = settings.fonts.bold,
		fontSize = settings.sceneTitle.fontSize,
	} )
	title.anchorY = 0

	return title
end

return sceneTitle
