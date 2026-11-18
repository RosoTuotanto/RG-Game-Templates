-- PonyTiled extension for the map's "zone" objects. PonyTiled calls zoneExtension.new for each
-- such object. A zone is an invisible sensor: when the player steps into it, the player comments
-- with the zone's message property. A zone with the once property fires only once per game;
-- any other zone fires again every time the player leaves the area and comes back.

local zoneExtension = {}

--------------------------------------------------------------------------------------
-- Forward declarations & variables

-- The record of once zones that have already fired: triggered[mapName][zoneName] = true.
-- The record lives outside the game scene and is stored in the game's save, so a zone that
-- has fired does not fire again even when the game is continued from a save.
local triggered = {}

-- The current map. The game scene sets it before building the map, so that firings are
-- recorded under the right map.
local currentMap

-- A function from the game scene that shows the zone's message on screen.
zoneExtension.onMessage = nil

--------------------------------------------------------------------------------------
-- Public functions

-- Tell the zones which map is being built.
function zoneExtension.setMap( mapName )
	currentMap = mapName
	triggered[mapName] = triggered[mapName] or {}
end


-- Return the record, so that the game's save can write it to disk.
function zoneExtension.getTriggered()
	return triggered
end


-- Bring back a saved record when the game is continued from a save.
function zoneExtension.restore( savedTriggered )
	triggered = savedTriggered or {}
end


-- Empty the record. Starting a new game calls this, so the firings from the
-- previous game do not carry over.
function zoneExtension.reset()
	triggered = {}
	currentMap = nil
end


function zoneExtension.new( instance )
	function instance:collision( event )
		-- React only when the player steps into the zone (the start of the collision).
		if event.phase == "began" and event.other.name == "hero" then
			-- A once zone fires only once per game, and the record remembers it.
			if self.once then
				if triggered[currentMap][self.name] then
					return
				end

				triggered[currentMap][self.name] = true
			end

			-- Showing the message only draws on screen, so it can happen right inside the
			-- collision handler. Only physics and scenes must not change during it.
			zoneExtension.onMessage( self.message )
		end
	end

	function instance:finalize()
		instance:removeEventListener( "collision" )
	end

	instance:addEventListener( "collision" )
	instance:addEventListener( "finalize" )

	return instance
end

return zoneExtension
