-- A character standing on the map, built from an "npc" object on the map's objects layer. The
-- hero talks to her through the dialogue, and she raises an arm while the talk lasts.

local npc = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local animations = require( "data.animations" )

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local sheet = graphics.newImageSheet( animations.npcSheet.filename, animations.npcSheet.options )

-- How far below the sprite's centre the feet are. The sprite is centred on its frame.
local feetOffset = animations.npcSheet.feetY - animations.npcSheet.options.height * 0.5

--------------------------------------------------------------------------------------
-- Public functions

-- Build the character in the given layer with her feet at the object's bottom centre. She has
-- no physics body, so the hero walks past her. The object's node property is the story passage
-- the talk opens.
function npc.new( parent, object )
	local character = display.newSprite( parent, sheet, animations.npcSequences )
	character.x = object.x
	character.y = object.y + object.height * 0.5 - feetOffset
	character.object = object
	character.node = object.node

	character:setSequence( "idle" )
	character:play()

	-- Whether the animation ran when the game paused, so resuming starts only what was running.
	local wasPlaying = false

	-- The art faces right, so she is mirrored to face something on her left.
	function character:face( targetX )
		if targetX > self.x then
			self.xScale = 1

		elseif targetX < self.x then
			self.xScale = -1
		end
	end

	-- raise plays once and stops on its last frame, so she holds her arm up until the talk ends.
	function character:startTalk()
		self:setSequence( "raise" )
		self:play()
	end

	function character:endTalk()
		self:setSequence( "lower" )
		self:play()
	end

	-- Once the arm is down, she goes back to her idle animation.
	function character:sprite( event )
		if event.phase == "ended" and self.sequence == "lower" then
			self:setSequence( "idle" )
			self:play()
		end
	end

	character:addEventListener( "sprite" )

	function character:pauseAnimation()
		wasPlaying = self.isPlaying
		self:pause()
	end

	function character:resumeAnimation()
		if wasPlaying then
			self:play()
		end
	end

	return character
end

return npc
