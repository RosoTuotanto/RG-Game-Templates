-- The platformer's hero: running, the double jump, ropes, one-way platforms, trampolines and the animations.

local player = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local physics = require( "physics" )
local settings = require( "libs.settings" )
local animations = require( "data.animations" )

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local heroSettings = settings.platformer.hero
local trampolineSettings = settings.platformer.trampoline

local sfxJump = audio.loadSound( "assets/audio/template/sfx/jump.wav" )

local sheet = graphics.newImageSheet( animations.heroSheet.filename, animations.heroSheet.options )

-- How far below the sprite's centre the feet are. The sprite is centred on its frame.
local feetOffset = animations.heroSheet.feetY - animations.heroSheet.options.height * 0.5

-- The body's box around the sprite's centre, before its corners are cut off. widgets/prompt.lua reads it
-- through hero.bodyBounds to measure the hero's reach from the body's edges.
local bodyBounds = {
	halfWidth = heroSettings.body.width * 0.5,
	top = feetOffset - heroSettings.body.height,
	bottom = feetOffset,
}

-- The body's second element, the ground sensor. Collision events name it in event.selfElement.
local footElement = 2

--------------------------------------------------------------------------------------
-- Private functions

-- The body's outline: a box standing on the feet, with its corners cut off. Box2D wants the
-- points in clockwise order, and an outline may have at most eight points.
local function buildBodyShape()
	local halfWidth = bodyBounds.halfWidth
	local bottom = bodyBounds.bottom
	local top = bodyBounds.top
	local cut = heroSettings.body.cornerCut

	return {
		-halfWidth + cut, top,
		halfWidth - cut, top,
		halfWidth, top + cut,
		halfWidth, bottom - cut,
		halfWidth - cut, bottom,
		-halfWidth + cut, bottom,
		-halfWidth, bottom - cut,
		-halfWidth, top + cut,
	}
end


-- The ground sensor: a thin strip across the feet, inside the cut corners, so it touches floors but never walls.
local function buildFootBox()
	local body = heroSettings.body

	return {
		halfWidth = body.width * 0.5 - body.cornerCut,
		halfHeight = body.footSensorDepth,
		x = 0,
		y = feetOffset,
	}
end

--------------------------------------------------------------------------------------
-- Public functions

-- Build the hero in the given layer with its feet frame centred on x, y.
function player.new( parent, x, y )
	local hero = display.newSprite( parent, sheet, animations.heroSequences )
	hero.x, hero.y = x, y
	hero.id = "player"
	hero.bodyBounds = bodyBounds

	physics.addBody( hero, "dynamic", {
		shape = buildBodyShape(),
		density = heroSettings.body.density,
		friction = 0,
		bounce = 0,
	}, {
		box = buildFootBox(),
		isSensor = true,
	} )
	hero.isFixedRotation = true

	hero:setSequence( "idle" )
	hero:play()

	local jumpCount = 0
	local ropeTouchCount = 0
	local isJumpHeld = false

	-- How many contacts the ground sensor has with each platform it touches. A polygon's chain body
	-- touches the sensor once for every edge the sensor overlaps.
	local groundContacts = {}

	-- The trampoline the hero touches, if any. The next jump uses it.
	hero.nearbyTrampoline = nil

	local function isOnRope()
		return ropeTouchCount > 0 and not isJumpHeld
	end

	-- Gravity stops on a rope, so the hero hangs there until climbing or jumping away.
	local function updateGravity()
		hero.gravityScale = isOnRope() and 0 or 1
	end

	-- A one-way platform holds the hero only once the feet are above it; every other platform always does.
	local function isStandingOn( platform )
		return not platform.oneWay or hero:isAbove( platform )
	end

	local function isOnGround()
		for platform in pairs( groundContacts ) do
			if isStandingOn( platform ) then
				return true
			end
		end

		return false
	end

	-- Pick the sequence from what the hero does. Climbing pauses on its frame while the hero hangs still.
	local function updateAnimation( directionX, directionY, velocityY )
		local sequence = "idle"
		local isMoving = true

		if isOnRope() then
			sequence = "climb"
			isMoving = directionX ~= 0 or directionY ~= 0

		elseif not isOnGround() then
			sequence = velocityY < 0 and "jump" or "fall"

		elseif directionX ~= 0 then
			sequence = "run"
		end

		if hero.sequence ~= sequence then
			hero:setSequence( sequence )
		end

		if isMoving and not hero.isPlaying then
			hero:play()

		elseif not isMoving and hero.isPlaying then
			hero:pause()
		end
	end

	-- True when the hero's feet are at or above the platform's top edge.
	function hero:isAbove( platform )
		return self.y + feetOffset <= platform.y - platform.height * 0.5 + heroSettings.landingTolerance
	end

	-- Called every frame with the direction the player presses. Off a rope only the sideways
	-- direction counts, so holding Up while running does not slow the hero down.
	function hero:move( directionX, directionY )
		local _, velocityY = self:getLinearVelocity()
		local velocityX

		if isOnRope() then
			velocityX = directionX * heroSettings.runSpeed
			velocityY = directionY * heroSettings.climbSpeed
		else
			local side = directionX > 0 and 1 or directionX < 0 and -1 or 0
			velocityX = side * heroSettings.runSpeed
		end

		self:setLinearVelocity( velocityX, velocityY )

		if directionX ~= 0 then
			self.xScale = directionX > 0 and 1 or -1
		end

		updateAnimation( directionX, directionY, velocityY )
	end

	function hero:jump( didJumpBegin )
		if not didJumpBegin then
			isJumpHeld = false
			updateGravity()
			return
		end

		if jumpCount >= heroSettings.maxJumps then
			return
		end

		jumpCount = jumpCount + 1
		isJumpHeld = true
		updateGravity()
		audio.play( sfxJump )

		local speed = heroSettings.jumpSpeed
		if self.nearbyTrampoline then
			self.nearbyTrampoline:use()
			self.nearbyTrampoline = nil
			speed = speed * trampolineSettings.jumpMultiplier
		end

		local velocityX = self:getLinearVelocity()
		self:setLinearVelocity( velocityX, -speed )
	end

	-- Only the ground sensor tells where the ground is: the body also touches walls and ceilings.
	-- Landing on ground while not moving up gives the jumps back.
	function hero:touchPlatform( platform, didTouchBegin, element )
		if element ~= footElement then
			return
		end

		if not didTouchBegin then
			local count = groundContacts[platform] - 1
			groundContacts[platform] = count > 0 and count or nil
			return
		end

		groundContacts[platform] = ( groundContacts[platform] or 0 ) + 1

		local _, velocityY = self:getLinearVelocity()
		if velocityY >= 0 and isStandingOn( platform ) then
			jumpCount = 0
		end
	end

	-- Only the ground sensor arms a trampoline, so the boost needs the feet on it. A trampoline
	-- is forgotten only if it is the one the feet touched last.
	function hero:touchTrampoline( trampoline, didTouchBegin, element )
		if element ~= footElement then
			return
		end

		if didTouchBegin then
			self.nearbyTrampoline = trampoline

		elseif self.nearbyTrampoline == trampoline then
			self.nearbyTrampoline = nil
		end
	end

	function hero:touchRope( didTouchBegin )
		ropeTouchCount = ropeTouchCount + ( didTouchBegin and 1 or -1 )

		if didTouchBegin then
			jumpCount = 0
		end

		updateGravity()
	end

	-- Stop the hero where it is, with gravity and the animation off, while the screen fades.
	function hero:freeze()
		self:setLinearVelocity( 0, 0 )
		self.gravityScale = 0
		self:pause()
	end

	-- Put the hero at spawnX, spawnY, facing right and standing still with a fresh set of jumps. The jump key is released by the
	-- freeze, because the controls stop and never report its release.
	function hero:respawn( spawnX, spawnY )
		self.x, self.y = spawnX, spawnY
		self.xScale = 1
		self:setLinearVelocity( 0, 0 )
		self.nearbyTrampoline = nil
		jumpCount = 0
		isJumpHeld = false
		updateGravity()
	end

	-- One-way platforms let the hero through from below and the sides. The ground sensor of a hero that
	-- rose through a platform and lands while still overlapping it starts no new collision, so landing
	-- on it gives the jumps back here. A sensor has no contact to disable, so this runs for the body only.
	function hero:preCollision( event )
		local platform = event.other

		if platform.oneWay then
			if not self:isAbove( platform ) then
				event.contact.isEnabled = false

			else
				local _, velocityY = self:getLinearVelocity()

				if velocityY >= 0 then
					jumpCount = 0
				end
			end
		end
	end

	hero:addEventListener( "preCollision" )

	return hero
end

return player
