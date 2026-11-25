-------------------------------------------------------------------------------------------------------

-- $$$$$$$\                                       $$$$$$\
-- $$  __$$\                                     $$  __$$\
-- $$ |  $$ | $$$$$$\   $$$$$$$\  $$$$$$\        $$ /  \__| $$$$$$\  $$$$$$\$$$$\   $$$$$$\   $$$$$$$\
-- $$$$$$$  |$$  __$$\ $$  _____|$$  __$$\       $$ |$$$$\  \____$$\ $$  _$$  _$$\ $$  __$$\ $$  _____|
-- $$  __$$< $$ /  $$ |\$$$$$$\  $$ /  $$ |      $$ |\_$$ | $$$$$$$ |$$ / $$ / $$ |$$$$$$$$ |\$$$$$$\
-- $$ |  $$ |$$ |  $$ | \____$$\ $$ |  $$ |      $$ |  $$ |$$  __$$ |$$ | $$ | $$ |$$   ____| \____$$\
-- $$ |  $$ |\$$$$$$  |$$$$$$$  |\$$$$$$  |      \$$$$$$  |\$$$$$$$ |$$ | $$ | $$ |\$$$$$$$\ $$$$$$$  |
-- \__|  \__| \______/ \_______/  \______/        \______/  \_______|\__| \__| \__| \_______|\_______/

-------------------------------------------------------------------------------------------------------
-- MIT License. Copyright (c) 2025-2026 Eetu Rantanen and Roso Games (Kukunori ry).
-- Third-party components included in this project keep their own licences.
-------------------------------------------------------------------------------------------------------

-- Load the merged game settings (data/settingsCore.lua + data/settingsTemplate.lua)
-- and the per-developer launch parameters (data/launchParams.json, optional).
local settings = require("libs.settings")
local launchParams = require("libs.launchParams")

-- We're initialising the game's other core modules and settings inside a different
-- module in order to keep this main.lua file cleaner and easier to read.
require("libs.initGame").init( settings, launchParams )

-------------------------------------------------------------------------

-- Load composer and skip past the launch screen in debug mode.
local composer = require("composer")

if launchParams.debugMode then
	composer.gotoScene( "scenes." .. (launchParams.gotoScene or settings.startScene), {
		params = {
			launchParams = launchParams.launchParams,
		}
	} )

else
	-- Always show error messages and stop the game's execution when running on the simulator.
	if system.getInfo( "environment" ) ~= "simulator" and settings.suppressErrors then
		-- Suppress error messages and try to ignore errors when not in debug mode.
		-- If you plan to include proper error reporting and analytics tools in your
		-- game, then feel free to replace the function below with your error handler.
		Runtime:addEventListener( "unhandledError", function()
			return true
		end )
	end

	composer.gotoScene( "scenes.launchScreen", {
		params = {
			launchParams = launchParams.launchParams,
		}
	} )
end

---------------------------------------------------------------------------
