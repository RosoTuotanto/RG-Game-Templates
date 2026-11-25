local composer = require("composer")
local scene = composer.newScene()

---------------------------------------------------------------------------

-- Common plugins, modules, libraries & classes.
local screen = require( "classes.screen" )
local settings = require( "libs.settings" )
local music = require( "classes.music" )
local menuBackground = require( "widgets.menuBackground" )
local widget = require( "widget" )

---------------------------------------------------------------------------

-- Forward declarations & variables.

local menuButton = {}

-- Shared handles for the core UI sounds.
local audioHandles = require( "libs.audioHandles" )

-- Button labels and platforms where a button must not appear.
local buttonDefinitions = {
	play = { label = "Play" },
	load = { label = "Load" },
	options = { label = "Options" },
	credits = { label = "Credits" },
	exit = { label = "Exit" },
}

---------------------------------------------------------------------------

-- Functions.

-- Function to handle button events
local function menuListener( event )
	if event.phase == "ended" then
		local id = event.target.id

		audio.play( audioHandles.click )

		if id == "play" or id == "load" or id == "credits" then
			local sceneName
			local params
			if id == "play" then
				sceneName = settings.menu.playScene

				-- The fade out overlaps the scene fade, and the game scene starts its own music when it shows.
				music.stop()

			elseif id == "load" then
				sceneName = "load"
				params = { mode = "load" }
			else
				sceneName = id
			end
			composer.gotoScene( "scenes." .. sceneName, { effect = "fade", time = 500, params = params } )

		elseif id == "options" then
			composer.showOverlay( "scenes.options", {
				effect = "fade",
				time = 250
			} )

		elseif id == "exit" then
			native.requestExit()

		end
	end
	return true
end

---------------------------------------------------------------------------

function scene:create( event )
	local sceneGroup = self.view

	-----------------------------------------------------------------------
	-- Create the slowly panning background image that fills the screen.

	menuBackground.new( sceneGroup )

	-----------------------------------------------------------------------
	-- Create the menu buttons from settings.menu.buttons. The list defines
	-- which buttons exist and in what order (see data/settingsCore.lua).

	-- native.requestExit is not supported on these platforms, so the exit
	-- button is always hidden on them.
	local truePlatform = system.getTruePlatform()
	local hideExit = (truePlatform == "ios" or truePlatform == "tvos" or truePlatform == "html5")

	local visibleButtons = {}
	for i = 1, #settings.menu.buttons do
		local id = settings.menu.buttons[i]
		if not buttonDefinitions[id] then
			print( "WARNING: unknown menu button id \"" .. tostring( id ) .. "\" in settings.menu.buttons." )
		elseif not (id == "exit" and hideExit) then
			visibleButtons[#visibleButtons+1] = id
		end
	end

	local spacing = 12
	local prevButton = nil

	for i = 1, #visibleButtons do
		local id = visibleButtons[i]
		menuButton[id] = widget.newButton(
			{
				x = screen.centerX,
				y = prevButton and (prevButton.y + prevButton.height + spacing) or (screen.centerY + spacing),
				id = id,
				label = buttonDefinitions[id].label,
				labelAlign = "center",
				labelColor = { default={ 0.9 }, over={ 1 } },
				onEvent = menuListener,
				width = 160,
				height = 52,
				fontSize = 32,
				font = settings.fonts.bold,
				shape = "rect",
				fillColor = { default={ 0, 0.7 }, over={ 0, 0.9 } },
				isEnabled = false,
			}
		)
		sceneGroup:insert( menuButton[id] )
		prevButton = menuButton[id]
	end

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
		for _, button in pairs( menuButton ) do
			button:setEnabled( true )
		end

		-- Start the menu music, or let it continue if it is already playing.
		-- Calling this on every visit brings the menu music back after a game played its own.
		music.play( settings.menu.music )

	end
end

---------------------------------------------------------------------------

function scene:hide( event )
	local sceneGroup = self.view

	if event.phase == "will" then
		for _, button in pairs( menuButton ) do
			button:setEnabled( false )
		end

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
