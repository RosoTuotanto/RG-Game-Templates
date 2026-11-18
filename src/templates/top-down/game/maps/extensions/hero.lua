-- PonyTiled extension for the map's "hero" object. PonyTiled calls heroExtension.new for the
-- object and passes it the Tiled object. The extension removes it and builds the hero in its place.

local heroExtension = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local settings = require( "libs.settings" )
local animations = require( "data.animations" )

--------------------------------------------------------------------------------------
-- Private functions

-- Work out the facing direction from the movement direction. The facing is locked to the
-- four main directions (right, left, down, up), which are the directions the hero has walk and
-- idle animations for. When the hero does not move, the previous facing is kept.
local function resolveFacing( directionX, directionY, currentFacingX, currentFacingY )
	if directionX == 0 and directionY == 0 then
		return currentFacingX, currentFacingY
	end

	-- Pick the axis with the stronger movement. On a tie, the horizontal axis wins.
	if math.abs( directionX ) >= math.abs( directionY ) then
		return directionX < 0 and -1 or 1, 0
	else
		return 0, directionY < 0 and -1 or 1
	end
end


-- Turn a facing direction into the direction word used in the sequence names.
local function getDirectionName( facingX, facingY )
	if facingX > 0 then
		return "East"
	elseif facingX < 0 then
		return "West"
	elseif facingY < 0 then
		return "North"
	end

	return "South"
end

--------------------------------------------------------------------------------------
-- Public functions

function heroExtension.new( instance )
	-- Take the position and layer where PonyTiled placed the hero.
	local parentLayer = instance.parent
	local x, y = instance.x, instance.y

	-- Remove the placeholder object that Tiled created. We build our own in its place.
	display.remove( instance )

	local sheetData = animations.heroSheet
	local heroSheet = graphics.newImageSheet( sheetData.filename, sheetData.options )

	-- Build the hero in its own group. The physics body goes on the group, and the sprite
	-- inside it can be mirrored without turning the body around.
	local hero = display.newGroup()
	hero.sprite = display.newSprite( hero, heroSheet, animations.heroSequences )

	-- Stand the sprite on its feet, so the group's position is the point where the hero's feet are.
	hero.sprite.anchorY = sheetData.feetY / sheetData.options.height

	-- A group's anchor moves nothing on screen, but the map's sort reads it: anchorY 1 makes the
	-- hero sort by its feet, against the base line of props that have anchorY 1 in Tiled.
	hero.anchorY = 1

	parentLayer:insert( hero )
	hero.x, hero.y = x, y

	hero.name = "hero"
	hero.type = "hero"
	hero.speed = settings.topDown.heroSpeed

	-- The movement direction, and the facing direction for interactions. The hero starts facing down.
	hero.directionX = 0
	hero.directionY = 0
	hero.facingX = 0
	hero.facingY = 1

	-- Make the hero a dynamic physics object, so the walls stop it.
	-- A round body slides smoothly along the corners of walls.
	physics.addBody( hero, "dynamic", { radius = settings.topDown.heroBodyRadius, density = 1, friction = 0, bounce = 0 } )

	-- Stop the hero from spinning when it bumps into a wall.
	hero.isFixedRotation = true

	-- Play the walk animation while the hero moves and the idle frame while it stands still,
	-- both facing the way the hero faces. The sheet has no east row, so east plays the west
	-- sequences mirrored.
	local function updateAnimation()
		local isMoving = hero.directionX ~= 0 or hero.directionY ~= 0
		local direction = getDirectionName( hero.facingX, hero.facingY )

		if direction == "East" then
			direction = "West"
			hero.sprite.xScale = -1
		else
			hero.sprite.xScale = 1
		end

		local sequenceName = ( isMoving and "walk" or "idle" ) .. direction

		-- Switch only when the sequence changes, so a running walk loop is not restarted every frame.
		if hero.sprite.sequence ~= sequenceName then
			hero.sprite:setSequence( sequenceName )
			hero.sprite:play()
		end
	end

	-- Move the hero with the direction from the controls. The direction is already
	-- normalised, so we only multiply it by the hero's speed.
	function hero:move( directionX, directionY )
		self.directionX = directionX
		self.directionY = directionY

		-- The facing changes only when the hero actually moves.
		self.facingX, self.facingY = resolveFacing( directionX, directionY, self.facingX, self.facingY )
		self:setLinearVelocity( directionX * self.speed, directionY * self.speed )
		updateAnimation()
	end


	-- Stop the hero completely. The facing stays as it was.
	function hero:stop()
		self.directionX = 0
		self.directionY = 0
		self:setLinearVelocity( 0, 0 )
		updateAnimation()
	end


	-- Return the hero's current facing as a unit vector.
	function hero:getFacing()
		return self.facingX, self.facingY
	end


	-- Set the facing. Loading a saved game uses this to turn the hero back the way
	-- it faced when the game was saved.
	function hero:setFacing( facingX, facingY )
		self.facingX = facingX
		self.facingY = facingY
		updateAnimation()
	end

	updateAnimation()

	return hero
end

return heroExtension
