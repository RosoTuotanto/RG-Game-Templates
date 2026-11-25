-- Per-developer launch parameters, loaded from data/launchParams.json.
--
-- That file is gitignored and excluded from device builds on purpose: it is
-- each developer's private testing configuration (skip the launch screen,
-- jump straight into a scene, mute the game, etc.) and must never change the
-- game for anyone else. The Simulator creates it with the defaults below when
-- it is missing, so every developer has one to edit. See the README for the fields.

local json = require("json")
local settings = require("libs.settings")

local launchParams = {
	debugMode = false,
	cleanLaunch = false,
	muteGame = false,
	gotoScene = nil,
	launchParams = {},
}

local expectedTypes = {
	debugMode = "boolean",
	cleanLaunch = "boolean",
	muteGame = "boolean",
	gotoScene = "string",
	launchParams = "table",
}

-- The order the keys are written in when the Simulator creates the file.
local fileKeyOrder = { "debugMode", "cleanLaunch", "muteGame", "gotoScene", "launchParams" }

-- Writes the defaults to the file, with gotoScene set to the start scene so every field is visible.
local function createFile( filePath )
	local lines = {}

	for i = 1, #fileKeyOrder do
		local key = fileKeyOrder[i]
		local value = launchParams[key]

		if key == "gotoScene" then
			value = settings.startScene
		end

		-- An empty Lua table has no way to tell json.encode that it is an object, not an array.
		local encoded = ( type( value ) == "table" and next( value ) == nil ) and "{}" or json.encode( value )
		lines[i] = "\t\"" .. key .. "\": " .. encoded
	end

	local file, errorMessage = io.open( filePath, "w" )
	if not file then
		print( "WARNING: could not create data/launchParams.json (" .. tostring( errorMessage ) .. "). Using default launch parameters." )
		return
	end

	file:write( "{\n" .. table.concat( lines, ",\n" ) .. "\n}\n" )
	file:close()
end

-- pathForFile with an empty string returns the resource directory path
-- without printing a missing file warning to the console.
local resourceDirectory = system.pathForFile( "", system.ResourceDirectory )

-- On Android the resources are packed inside the app, so the resource directory has
-- no path and the game uses the default launch parameters.
local file = nil
if resourceDirectory then
	local filePath = resourceDirectory .. "/data/launchParams.json"
	file = io.open( filePath, "r" )

	if not file and system.getInfo( "environment" ) == "simulator" then
		createFile( filePath )
	end
end

if file then
	local contents = file:read( "*a" )
	file:close()

	local data, _, errorMessage = json.decode( contents )
	if type( data ) ~= "table" then
		print( "WARNING: data/launchParams.json contains invalid JSON (" .. tostring( errorMessage ) .. "). Using default launch parameters." )
	else
		for key, value in pairs( data ) do
			local expected = expectedTypes[key]
			if not expected then
				print( "WARNING: data/launchParams.json contains an unknown key: \"" .. tostring( key ) .. "\"." )
			elseif type( value ) ~= expected then
				print( "WARNING: data/launchParams.json key \"" .. key .. "\" should be a " .. expected .. ", got " .. type( value ) .. ". Ignoring it." )
			else
				launchParams[key] = value
			end
		end
	end
end

return launchParams
