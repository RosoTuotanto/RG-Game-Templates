-- controls.lua
-- Keyboard input module. Reads key bindings from user settings and provides
-- normalized movement vectors and key action callbacks.
--
-- Usage:
--   local controls = require("classes.controls")
--   controls.start( onMovement, onKeyAction )
--   controls.stop()
--
-- onMovement( vx, vy ) is called every frame with normalized direction values.
-- onKeyAction( action, phase ) is called with "down" when the first key of an action is pressed
-- and with "up" when the last of its held keys is released.
-- The available actions are defined by the controls list in data/settingsCore.lua
-- (or the template's data/settingsTemplate.lua override).

local controls = {}

local callbackMovement = nil
local callbackKey = nil

local hasStarted = false
local isPressed = {}

-- The keys held down right now, as key name -> the action the key controlled when it went down.
local heldKeys = {}

-- How many keys of each action are held down right now, as action name -> count.
local heldKeyCount = {}

-- When each action's key last went down, as action name -> press number. A higher number is a later press,
-- so when both directions of an axis are held, the one pressed last can win.
local pressOrder = {}
local pressCount = 0

local loadsave = require( "classes.loadsave" )

-- Build a reverse lookup table: key name -> action name.
-- The user settings store controls as { action = { key1, key2, ... } },
-- but at runtime we need to quickly look up which action a pressed key maps to.
local key = {}

-- Forget every held key, so no action stays pressed after the controls stop or the keys change.
local function clearHeldKeys()
	for keyName in pairs( heldKeys ) do
		heldKeys[keyName] = nil
	end

	for action in pairs( heldKeyCount ) do
		heldKeyCount[action] = nil
	end

	for action in pairs( isPressed ) do
		isPressed[action] = false
	end

	for action in pairs( pressOrder ) do
		pressOrder[action] = nil
	end

	pressCount = 0
end

local function rebuildKeyMap()
	clearHeldKeys()

	-- Clear existing mappings (wipe in-place to preserve upvalue reference).
	for k in pairs( key ) do
		key[k] = nil
	end
	-- Rebuild from current userdata.
	for action, keyNames in pairs( loadsave.userdata.controls ) do
		for i = 1, 2 do
			if keyNames[i] then
				key[keyNames[i]] = action
			end
		end
	end
end

-- Build initial key map.
rebuildKeyMap()


-- Return -1, 0 or 1 for one axis. While both directions are held, the one pressed last wins,
-- so on a quick turn the character turns at once instead of stopping until the old key is released.
local function axisDirection( negative, positive )
	if isPressed[negative] and isPressed[positive] then
		if pressOrder[negative] > pressOrder[positive] then
			return -1
		end
		return 1

	elseif isPressed[negative] then
		return -1

	elseif isPressed[positive] then
		return 1
	end

	return 0
end


local function monitorMovement()
	local vx = axisDirection( "left", "right" )
	local vy = axisDirection( "up", "down" )

	-- Normalize to prevent faster diagonal movement
	local mag = math.sqrt(vx * vx + vy * vy)
	if mag > 0 then
		vx = vx / mag
		vy = vy / mag
	end

	-- Epsilon check to avoid tiny float errors
	local epsilon = 1e-6
	if math.abs(vx) < epsilon then vx = 0 end
	if math.abs(vy) < epsilon then vy = 0 end

	callbackMovement(vx, vy)
end


local function onKeyEvent( event )
	local keyName = event.keyName

	-- An action is pressed while at least one of its keys is held, so the game hears "down"
	-- only for the first of its keys and "up" only when the last one is released.
	if event.phase == "down" then
		local action = key[keyName]

		-- A key that is already held is skipped, so it is never counted twice.
		if action and not heldKeys[keyName] then
			heldKeys[keyName] = action
			heldKeyCount[action] = (heldKeyCount[action] or 0) + 1

			-- Every new key press counts, also the second key of an action that is already pressed.
			pressCount = pressCount + 1
			pressOrder[action] = pressCount

			if heldKeyCount[action] == 1 then
				isPressed[action] = true
				callbackKey( action, "down" )
			end
		end

	elseif event.phase == "up" then
		-- A key that went down before the controls started has no "down", so its "up" is skipped too.
		local action = heldKeys[keyName]

		if action then
			heldKeys[keyName] = nil
			heldKeyCount[action] = heldKeyCount[action] - 1

			if heldKeyCount[action] == 0 then
				isPressed[action] = false
				callbackKey( action, "up" )
			end
		end
	end
end


-- Start listening for keyboard input. Call this when the scene becomes active.
-- listenerMovement( vx, vy ) is called every frame with normalized direction.
-- listenerKey( action, phase ) is called on key press/release for bound keys.
function controls.start( listenerMovement, listenerKey )
	if not hasStarted then
		hasStarted = true

		callbackMovement = listenerMovement
		callbackKey = listenerKey

		Runtime:addEventListener( "enterFrame", monitorMovement )
		Runtime:addEventListener( "key", onKeyEvent )
	end
end


-- Stop listening for keyboard input and reset all key states.
function controls.stop()
	if hasStarted then
		hasStarted = false

		Runtime:removeEventListener( "enterFrame", monitorMovement )
		Runtime:removeEventListener( "key", onKeyEvent )

		clearHeldKeys()
	end
end

-- Rebuild the reverse lookup table from current userdata.
-- Call this after modifying loadsave.userdata.controls at runtime.
function controls.rebuildKeyMap()
	rebuildKeyMap()
end


-- Return the current control bindings table.
function controls.getBindings()
	return loadsave.userdata.controls
end


-- Return whether controls are currently listening for input.
function controls.isActive()
	return hasStarted
end

return controls