-- Trampoline tiles: a jump that starts on one goes higher, and the tile shows its pressed frame for a moment.
-- The tile's sensor body comes from its tileset properties, and its two frames from its Tiled animation (rest, pressed).

local trampoline = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local settings = require( "libs.settings" )

--------------------------------------------------------------------------------------
-- Public functions

function trampoline.new( tile )
	-- PonyTiled starts the tile's animation, but the frames change only when the trampoline is used.
	tile:pause()
	tile:setFrame( 1 )

	-- The "game" tag lets the game scene cancel the timer when the scene is left.
	function tile:use()
		self:setFrame( 2 )

		timer.performWithDelay( settings.platformer.trampoline.pressedTime, function()
			self:setFrame( 1 )
		end, "game" )
	end

	return tile
end

return trampoline
