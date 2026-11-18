-- The game scene. In the core template this is an empty placeholder:
-- every template (top-down, platformer, ...) overwrites this file with
-- its own game scene. If you are building a game directly on the core,
-- replace the placeholder content below with your game.

local composer = require("composer")
local scene = composer.newScene()

---------------------------------------------------------------------------

-- Common plugins, modules, libraries & classes.
local screen = require( "classes.screen" )
local loadsave = require( "classes.loadsave" )
local settings = require( "libs.settings" )

---------------------------------------------------------------------------

-- Forward declarations & variables.


---------------------------------------------------------------------------

-- Functions.


---------------------------------------------------------------------------

function scene:create( event )
	local sceneGroup = self.view

	-- Placeholder content: shows that RG CORE booted successfully.
	-- Delete everything in this function when you build your game scene.
	local placeholder = display.newText({
		parent = sceneGroup,
		text = "RG CORE is running.\n\nThis is scenes/game.lua, the empty game scene that game templates overwrite.\n\nTap anywhere to return to the menu.",
		x = screen.centerX,
		y = screen.centerY,
		width = screen.width - 160,
		font = settings.fonts.bold,
		fontSize = 32,
		align = "center",
	})

	local returnSensor = display.newRect( sceneGroup, screen.centerX, screen.centerY, screen.width, screen.height )
	returnSensor.isVisible = false
	returnSensor.isHitTestable = true
	returnSensor:addEventListener( "touch", function( touchEvent )
		if touchEvent.phase == "ended" then
			composer.gotoScene( "scenes.menu", { effect = "fade", time = 250 } )
		end
		return true
	end )
end

---------------------------------------------------------------------------

function scene:show( event )
	local sceneGroup = self.view

	if event.phase == "will" then
		-- If coming from launchScreen scene, then start by removing it.
		if composer._previousScene == "scenes.launchScreen" then
			composer.removeScene( "scenes.launchScreen" )
		end

	elseif event.phase == "did" then


	end
end

---------------------------------------------------------------------------

function scene:hide( event )
	local sceneGroup = self.view

	if event.phase == "will" then


	elseif event.phase == "did" then


	end
end

---------------------------------------------------------------------------

function scene:destroy( event )


end

---------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

---------------------------------------------------------------------------

return scene
