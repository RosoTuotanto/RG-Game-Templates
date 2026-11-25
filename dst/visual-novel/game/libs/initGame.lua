local initGame = {}

---------------------------------------------------------------------------

-- Fill in every setting the player's file lacks from the defaults, also inside nested
-- tables, without overwriting anything the player already has. Returns true if it added any.
local function copyMissingDefaults( target, defaults )
	local changed = false

	for key, value in pairs( defaults ) do
		if target[key] == nil then
			-- A missing table starts empty and the recursive call below fills it.
			if type( value ) == "table" then
				target[key] = {}
			else
				target[key] = value
			end
			changed = true
		end

		if type( value ) == "table" and type( target[key] ) == "table" then
			changed = copyMissingDefaults( target[key], value ) or changed
		end
	end

	return changed
end

-- An action's default keys: the main key and the optional secondary key.
local function getDefaultKeys( action )
	return { action.keys[1], action.keys[2] }
end

-- Build the default key bindings from the settings.controls list.
local function createDefaultControls( controlsList )
	local controls = {}

	for i = 1, #controlsList do
		local action = controlsList[i]
		controls[action.id] = getDefaultKeys( action )
	end

	return controls
end

-- Match the player's saved key bindings to the current settings.controls list. The main key
-- always comes from the list, and the player's secondary key is kept, even when they unbound it.
-- A new action gets its default keys, minus a secondary key the player already uses elsewhere.
-- Returns the new bindings and whether they differ from the saved ones.
local function reconcileControls( storedControls, controlsList )
	local controls = {}
	local changed = false

	-- A secondary key can never be the same key as any action's main key.
	local mainKeys = {}
	for i = 1, #controlsList do
		mainKeys[controlsList[i].keys[1]] = true
	end

	-- The secondary keys the player keeps on actions that are already in their file.
	local storedSecondaryKeys = {}
	for i = 1, #controlsList do
		local storedKeys = storedControls[controlsList[i].id]
		if storedKeys and storedKeys[2] and not mainKeys[storedKeys[2]] then
			storedSecondaryKeys[storedKeys[2]] = true
		end
	end

	for i = 1, #controlsList do
		local action = controlsList[i]
		local storedKeys = storedControls[action.id]

		if storedKeys then
			local secondaryKey = storedKeys[2]
			if secondaryKey and mainKeys[secondaryKey] then
				secondaryKey = nil
			end

			controls[action.id] = { action.keys[1], secondaryKey }

			if storedKeys[1] ~= action.keys[1] or storedKeys[2] ~= secondaryKey then
				changed = true
			end
		else
			-- The action is new, so it gets its default keys. A key can only control one action,
			-- so if the player already uses the default secondary key, the new action has none.
			local defaultKeys = getDefaultKeys( action )
			if defaultKeys[2] and storedSecondaryKeys[defaultKeys[2]] then
				defaultKeys[2] = nil
			end

			controls[action.id] = defaultKeys
			changed = true
		end
	end

	-- Actions that are no longer in the list are left out of the new bindings.
	for actionId in pairs( storedControls ) do
		if not controls[actionId] then
			changed = true
		end
	end

	return controls, changed
end

---------------------------------------------------------------------------

function initGame.init( settings, launchParams )

	---------------------------------------------------------------------------
	-- Step #1: Texture filtering and image sheet sampling.
	---------------------------------------------------------------------------

	-- Must run before any display object is created, which is why it is
	-- the very first step of the game's initialisation.
	if settings.usesPixelArt then
		display.setDefault( "magTextureFilter", "nearest" )
		display.setDefault( "minTextureFilter", "nearest" )
	end

	-- Must also run before any image sheet is created.
	if settings.sampleImageSheetsInsideFrame then
		display.setDefault( "isImageSheetSampledInsideFrame", true )
	end

	---------------------------------------------------------------------------
	-- Step #2: Debug mode browser console prints.
	---------------------------------------------------------------------------

	-- If debug mode is active and the project is running on the
	-- HTML5 platform then send any prints to the browser console.

	if launchParams.debugMode and system.getInfo("platform") == "html5" then
		local _tostring = tostring
		local _concat = table.concat
		local _gsub = string.gsub

		-- Using lfs workaround to load JS modules outside of project root.
		local lfs = require("lfs")
		lfs.chdir( "widgets" )
		local printToBrowser = require("printToBrowser")
		local _print = printToBrowser.print

		-- Hijack the standard print function.
		local printList = {}
		function print( ... ) -- luacheck: ignore
			for i = 1, arg.n do
				printList[i] = _tostring( arg[i] )
			end
			_print( _gsub( _concat( printList, "    " ), "\t", "    " ) )
			-- Reduce, reuse and recycle.
			for i = 1, arg.n do
				printList[i] = nil
			end
		end

		-- Release widgets folder from LFS' control and clean up the library.
		lfs.chdir( system.pathForFile( "" ) )
		_G.package.loaded["lfs"] = nil
	end

	---------------------------------------------------------------------------
	-- Step #3: Initialize core modules and settings.
	---------------------------------------------------------------------------

	-- Initialize all core plugins, classes and libraries.
	require("widgets.eventListenerWrapper")
	require("classes.screen")
	require("libs.utils")

	-- Set up useful properties that are likely needed later.
	local composer = require("composer")
	composer.recycleOnSceneChange = true
	transition.ignoreEmptyReference = true
	math.randomseed( math.generateSeed() )

	---------------------------------------------------------------------------
	-- Create a single global variable to track if the game is in debug mode.
	_G._debugMode = not not launchParams.debugMode
	---------------------------------------------------------------------------

	---------------------------------------------------------------------------
	-- Step #4: Overwrite display.remove().
	---------------------------------------------------------------------------

	-- Overwriting Solar2D's original display.remove() convenience wrapper, which
	-- eliminates the need to check if a display object is nil before removing it.

	-- This version adds a property to the object upon removing it that explicitly states
	-- the object has been removed. There are some edge cases and race conditions where
	-- an object might have been removed, but doesn't yet appear so, and this property
	-- can be used to always verify if the object has been removed or not.

	display.remove = function( object )
		if type( object ) == "table" and not object._isRemoved then
			local method = object.removeSelf

			if type( method ) == "function" then
				object._isRemoved = true
				method( object ) -- same as object:removeSelf()
			end
		end
	end

	---------------------------------------------------------------------------
	-- Step #5: Load user settings from disk and apply them.
	---------------------------------------------------------------------------

	local loadsave = require("classes.loadsave")

	-- Create the folder for save game files.
	system.createFolder( "saves", system.DocumentsDirectory )

	-- Clean up possible old userdata and save files if requested.
	-- cleanLaunch simulates a fresh install: default settings, no saves.
	if launchParams.cleanLaunch then
		loadsave.delete( "userdata.json" )

		local lfs = require("lfs")
		local folderPath = system.pathForFile( "saves", system.DocumentsDirectory )
		for entry in lfs.dir( folderPath ) do
			if entry ~= "." and entry ~= ".." then
				os.remove( folderPath .. "/" .. entry )
			end
		end
	end

	-- Load user settings or create them from default settings if not found.
	local userdata = loadsave.load( "userdata.json" )
	if not userdata then
		userdata = table.copy( settings.defaultUserdata )
		userdata.controls = createDefaultControls( settings.controls )
		loadsave.save( userdata, "userdata.json" )

	else
		-- Bring an existing file up to date with the current settings, and save it only if something changed.
		local addedDefaults = copyMissingDefaults( userdata, settings.defaultUserdata )
		local controls, controlsChanged = reconcileControls( userdata.controls or {}, settings.controls )
		userdata.controls = controls

		if addedDefaults or controlsChanged then
			loadsave.save( userdata, "userdata.json" )
		end
	end

	if userdata.fullscreen then
		native.setProperty( "windowMode", "fullscreen" )
	else
		native.setProperty( "windowMode", "normal" )
	end

	-- Reserve channel 1 so music always plays on it and is never auto-assigned
	-- to a sound effect. Sound effects play on channels 2 to 32.
	audio.reserveChannels( 1 )

	local volumes = userdata.audio.volume
	if volumes then
		local totalChannels = 32

		-- Master scales every channel's volume.
		if type( volumes.master ) == "number" then
			audio.setVolume( volumes.master / 100 )
		end

		-- Music plays on the reserved channel 1.
		if type( volumes.music ) == "number" then
			audio.setVolume( volumes.music / 100, { channel = 1 } )
		end

		-- Sound effects play on channels 2 to 32.
		if type( volumes.sfx ) == "number" then
			for channel = 2, totalChannels do
				audio.setVolume( volumes.sfx / 100, { channel = channel } )
			end
		end
	end

	-- Silence the game by setting the master volume to zero.
	if launchParams.muteGame then
		audio.setVolume( 0 )
	end

	---------------------------------------------------------------------------
	-- Step #6: Store userdata in Loadsave module for easy access.
	---------------------------------------------------------------------------

	loadsave.userdata = table.copy( userdata )

end

return initGame
