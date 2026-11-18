-- The small bubble shown in the world above a map object that has a prompt property, such as
-- "{up}: talk" over a character. It shows only while the hero is close enough to the object.

local prompt = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local settings = require( "libs.settings" )
local controls = require( "classes.controls" )

-- hints names the keys, so a key reads the same in the bubbles as in the controls tooltip.
local hints = require( "widgets.hints" )

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local promptSettings = settings.platformer.prompt

--------------------------------------------------------------------------------------
-- Private functions

-- Turn every {action} in the text into the keys bound to that action, such as {up} into "Up / W".
local function buildText( text )
	local bindings = controls.getBindings()

	return ( text:gsub( "{(%w+)}", function( action )
		local boundKeys = bindings[action] or {}
		local keyNames = {}

		for i = 1, #boundKeys do
			keyNames[i] = hints.getKeyName( boundKeys[i] )
		end

		return table.concat( keyNames, " / " )
	end ) )
end

--------------------------------------------------------------------------------------
-- Public functions

-- The sideways gap between the hero's body and the object, 0 while they overlap sideways. The object's
-- x and y are its centre, in the hero's space.
function prompt.getGapX( object, hero )
	return math.max( math.abs( object.x - hero.x ) - object.width * 0.5 - hero.bodyBounds.halfWidth, 0 )
end


-- The vertical gap between the hero's body and the object, 0 while they overlap vertically.
function prompt.getGapY( object, hero )
	local bounds = hero.bodyBounds
	local objectTop = object.y - object.height * 0.5
	local objectBottom = object.y + object.height * 0.5

	return math.max( objectTop - ( hero.y + bounds.bottom ), ( hero.y + bounds.top ) - objectBottom, 0 )
end


-- True when the gap between the hero's body and the object is at most reachX sideways and at most reachY vertically.
function prompt.isInReach( object, hero )
	return prompt.getGapX( object, hero ) <= promptSettings.reachX and prompt.getGapY( object, hero ) <= promptSettings.reachY
end


-- Build the bubble for a map object in the given group. The bubble starts hidden.
function prompt.new( parent, object )
	local bubble = display.newGroup()
	parent:insert( bubble )

	bubble.x = object.x
	bubble.y = object.y - object.height * 0.5 - promptSettings.offset
	bubble.isVisible = false
	bubble.object = object

	-- Draw the text and the box again from the current key bindings, for example after the
	-- player has changed keys in the options.
	function bubble:refresh()
		for i = self.numChildren, 1, -1 do
			display.remove( self[i] )
		end

		local label = display.newText( self, buildText( object.prompt ), 0, 0, settings.fonts.regular, promptSettings.textSize )

		local box = display.newRoundedRect( self, 0, 0, label.width + promptSettings.paddingX * 2, promptSettings.height, promptSettings.cornerRadius )
		local color = promptSettings.boxColor
		box:setFillColor( color[1], color[2], color[3], promptSettings.boxAlpha )
		label:toFront()
	end

	-- Show the bubble only while the hero is in reach and isBlocked is false. The game scene
	-- passes true while a dialogue or the inventory is open.
	function bubble:update( hero, isBlocked )
		self.isVisible = not isBlocked and prompt.isInReach( object, hero )
	end

	bubble:refresh()

	return bubble
end

return prompt
