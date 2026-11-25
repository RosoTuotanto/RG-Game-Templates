-- Per-developer launch parameters, loaded from data/launchParams.json.
--
-- That file is gitignored and excluded from device builds on purpose: it is
-- each developer's private testing configuration (skip the launch screen,
-- jump straight into a scene, mute the game, etc.) and must never change the
-- game for anyone else. When the file does not exist, the defaults below are
-- used. See data/launchParams.example.json and the README for the fields.

local json = require("json")

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

-- pathForFile with an empty string returns the resource directory path
-- without printing a missing file warning to the console.
local resourceDirectory = system.pathForFile( "", system.ResourceDirectory )

-- On Android the resources are packed inside the app, so the resource directory has
-- no path and the game uses the default launch parameters.
local file = nil
if resourceDirectory then
	file = io.open( resourceDirectory .. "/data/launchParams.json", "r" )
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
