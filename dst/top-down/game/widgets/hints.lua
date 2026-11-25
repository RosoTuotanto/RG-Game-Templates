-- Control hints. Draws a small, see-through box in the bottom left corner of the screen
-- that tells the player what the keys do. The keys are read from the player's key
-- bindings when the box is created and again when hints.refresh is called, so the game
-- scene calls hints.refresh after the pause menu, where the player can rebind keys.

local hints = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local screen = require( "classes.screen" )
local settings = require( "libs.settings" )

-- loadsave.userdata.controls holds the player's key bindings.
local loadsave = require( "classes.loadsave" )

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local fontSize = 16
local padding = 10
local margin = 12

-- The group that holds the hint box. hints.refresh draws the box again inside it.
local hintGroup

-- Display names for keys. The bindings use Solar2D's key names (such as "escape"),
-- which are turned into clearer names for the player here.
local keyDisplayNames = {
	escape = "Esc",
	space = "Space",
	up = "Up",
	down = "Down",
	left = "Left",
	right = "Right",
}

-- In the hint rows the arrow keys are grouped together under the word "Arrows".
local keyGroupNames = {
	up = "Arrows",
	down = "Arrows",
	left = "Arrows",
	right = "Arrows",
}

--------------------------------------------------------------------------------------
-- Private functions

-- Build one row's key text from the bindings. Single letter keys (such as w, a, s, d)
-- are joined into one word ("WASD") and other keys (Space, Arrows, Esc) are listed
-- separately. This way moving shows as "WASD / Arrows" and talking as "E / Space".
local function formatKeys( actions )
	local controls = loadsave.userdata.controls

	local letters = ""
	local named = {}
	local seen = {}

	for actionIndex = 1, #actions do
		local boundKeys = controls[actions[actionIndex]]

		for keyIndex = 1, #boundKeys do
			local keyName = boundKeys[keyIndex]

			if #keyName == 1 then
				letters = letters .. keyName:upper()
			else
				local displayName = keyGroupNames[keyName] or hints.getKeyName( keyName )
				if not seen[displayName] then
					seen[displayName] = true
					named[#named+1] = displayName
				end
			end
		end
	end

	local parts = {}
	if letters ~= "" then
		parts[#parts+1] = letters
	end
	for i = 1, #named do
		parts[#parts+1] = named[i]
	end

	return table.concat( parts, " / " )
end


-- Put all the rows from the settings together into one text with a line for each row.
local function buildText()
	local rows = settings.hints.rows
	local lines = {}
	for i = 1, #rows do
		lines[i] = formatKeys( rows[i].actions ) .. " - " .. rows[i].label
	end
	return table.concat( lines, "\n" )
end


-- Draw the text and its see-through background inside the hint group. Whatever was drawn
-- there before is removed first, so the box can be drawn again with new keys.
local function drawBox()
	for i = hintGroup.numChildren, 1, -1 do
		display.remove( hintGroup[i] )
	end

	local label = display.newText({
		parent = hintGroup,
		text = buildText(),
		font = settings.fonts.regular,
		fontSize = fontSize,
		align = "left",
	} )
	label.anchorX = 0
	label.anchorY = 1
	label.x = padding
	label.y = -padding

	-- A see-through background behind the text, so that the hints stand out from the map.
	local background = display.newRoundedRect( hintGroup, 0, 0, label.width + padding * 2, label.height + padding * 2, 6 )
	background.anchorX = 0
	background.anchorY = 1
	background:setFillColor( 0, 0.55 )
	background:toBack()
end

--------------------------------------------------------------------------------------
-- Public functions

-- The name the player sees for one key, such as "W", "Space" or "Up". Other text that names
-- keys, such as a prompt over a map object, uses this too, so every key reads the same way.
function hints.getKeyName( keyName )
	if #keyName == 1 then
		return keyName:upper()
	end

	return keyDisplayNames[keyName] or keyName:upper()
end


-- Create the hint box and add it to the given scene group. The group does not move
-- with the camera, so the hints stay in place in the bottom left corner. The box is
-- removed together with the scene, so it needs no removal of its own.
-- With hints.enabled set to false in the settings, nothing is drawn and nil is returned.
function hints.create( sceneGroup )
	if not settings.hints.enabled then
		hintGroup = nil
		return nil
	end

	hintGroup = display.newGroup()
	sceneGroup:insert( hintGroup )

	hints.resize()
	drawBox()

	return hintGroup
end


-- Keep the box in the bottom left corner after the screen's size has changed.
function hints.resize()
	if not hintGroup then
		return
	end

	hintGroup.x = screen.minX + margin
	hintGroup.y = screen.maxY - margin
end


-- Draw the hints again from the player's current key bindings. The box keeps its place
-- on the screen.
function hints.refresh()
	if hintGroup then
		drawBox()
	end
end

--------------------------------------------------------------------------------------

return hints
