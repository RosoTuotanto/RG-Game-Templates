-- PonyTiled extension for the map's "exit" objects. PonyTiled calls exitExtension.new for each
-- such object. An exit is an invisible sensor: when the player touches it, the screen fades to
-- black and the game moves to the map and spawn point named in the object's properties.
-- The requiredFlag and lockedMessage properties lock an exit: it opens only once the story
-- variable that requiredFlag names holds a value other than false or nil.

local exitExtension = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local composer = require( "composer" )
local controls = require( "classes.controls" )
local transitionOverlay = require( "classes.transitionOverlay" )
local dialogue = require( "classes.dialogue" )

--------------------------------------------------------------------------------------
-- Forward declarations & variables

-- Stops a map change from starting more than once. Every exit shares this variable,
-- so no other exit can start a map change while one is already running.
local transitioning = false

-- A function from the game scene that shows a locked exit's message on screen.
exitExtension.onLocked = nil

--------------------------------------------------------------------------------------
-- Public functions

function exitExtension.new( instance )
	function instance:collision( event )
		-- React only when the player arrives at the exit (the start of the collision).
		if event.phase == "began" and event.other.name == "hero" then
			if transitioning then
				return
			end

			-- A locked exit does not let the player through until the story has set its flag.
			-- Instead, the player comments on why they are not going there.
			if self.requiredFlag and not dialogue.getFlag( self.requiredFlag ) then
				exitExtension.onLocked( self.lockedMessage )
				return
			end

			transitioning = true

			-- Take the target map's details, which come from the Tiled object's properties.
			local hero = event.other
			local targetMap = self.targetMap
			local targetSpawn = self.targetSpawn

			-- Start the map change only on the next frame. Physics and scenes must not change
			-- in the middle of a collision handler, so we wait for the collision to finish.
			-- The game goes through the refresh scene, so the new map is built from scratch.
			timer.performWithDelay( 1, function()
				-- The player must not move the hero while the screen fades out.
				controls.stop()
				hero:stop()

				transitionOverlay.show( {
					onMidpoint = function()
						composer.gotoScene( "scenes.refresh", { params = { mapName = targetMap, spawnName = targetSpawn } } )
					end,
				} )
			end )
		end
	end

	-- When the exit is removed on a map change, map changes are allowed again.
	function instance:finalize()
		transitioning = false
		instance:removeEventListener( "collision" )
	end

	instance:addEventListener( "collision" )
	instance:addEventListener( "finalize" )

	return instance
end

return exitExtension
