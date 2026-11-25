-- Spike tiles: a sensor body over the lower part of the tile, where the spikes are drawn.
-- Touching it sends the hero back to the last door or spawn (scenes/game.lua).

local spikes = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local physics = require( "physics" )
local settings = require( "libs.settings" )

--------------------------------------------------------------------------------------
-- Public functions

function spikes.new( tile )
	local config = settings.platformer.spikes
	local halfHeight = tile.height * config.heightShare * 0.5

	physics.addBody( tile, "static", {
		isSensor = true,
		box = {
			halfWidth = tile.width * config.widthShare * 0.5,
			halfHeight = halfHeight,
			x = 0,
			y = tile.height * 0.5 - halfHeight,
		},
	} )

	return tile
end

return spikes
