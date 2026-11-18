---------------------------------------------------------------------------
-- Pause Menu Widget
-- A display group based pause menu (not a Composer scene).
-- Blocks all touch propagation behind it.
-- Only the buttons whose callbacks are provided in params are created;
-- Resume and Quit are always created. onSave gets the path of the screenshot for the save slot.
---------------------------------------------------------------------------

local screen = require( "classes.screen" )
local controls = require( "classes.controls" )
local saveManager = require( "classes.saveManager" )
local settings = require( "libs.settings" )
local sceneTitle = require( "widgets.sceneTitle" )
local widget = require( "widget" )

local pauseMenu = {}

---------------------------------------------------------------------------

-- Shared handles for the core UI sounds.
local audioHandles = require( "libs.audioHandles" )

---------------------------------------------------------------------------

function pauseMenu.new( params )
	params = params or {}

	local onResume = params.onResume
	local onSave = params.onSave
	local onLoad = params.onLoad
	local onOptions = params.onOptions
	local onQuit = params.onQuit

	local group = display.newGroup()
	local buttons = {}

	-- The capture renders the scene by itself, so the menu hidden around it stays out of the thumbnail and never flickers on screen.
	local function saveWithScreenshot()
		group.isVisible = false
		local screenshotFile = saveManager.captureScreenshot()
		group.isVisible = true

		onSave( screenshotFile )
	end

	-----------------------------------------------------------------------
	-- Build the button list from the provided callbacks.

	local buttonData = {}
	buttonData[#buttonData+1] = { id = "resume", label = "Resume", callback = onResume }
	if onSave then
		buttonData[#buttonData+1] = { id = "save", label = "Save", callback = saveWithScreenshot }
	end
	if onLoad then
		buttonData[#buttonData+1] = { id = "load", label = "Load", callback = onLoad }
	end
	if onOptions then
		buttonData[#buttonData+1] = { id = "options", label = "Options", callback = onOptions }
	end
	buttonData[#buttonData+1] = { id = "quit", label = "Quit to Menu", callback = onQuit }

	-----------------------------------------------------------------------
	-- Dimmer background (blocks touches from propagating through).

	local dimmer = display.newRect( group, screen.centerX, screen.centerY, screen.width, screen.height )
	dimmer:setFillColor( 0, 0.5 )
	dimmer:addEventListener( "touch", function() return true end )
	dimmer:addEventListener( "tap", function() return true end )

	-----------------------------------------------------------------------
	-- Window, sized by button count.

	local windowHeight = 120 + #buttonData * 64
	local window = display.newRect( group, screen.centerX, screen.centerY, 320, windowHeight )
	window:setFillColor( 0, 0.9 )

	-----------------------------------------------------------------------
	-- Title.

	local title = sceneTitle.new( group, "Paused", screen.centerX, window.y - window.height * 0.5 + 20 )

	-----------------------------------------------------------------------
	-- Buttons.

	local startY = title.y + title.height + 40

	for i = 1, #buttonData do
		local data = buttonData[i]
		local callback = data.callback
		buttons[data.id] = widget.newButton({
			x = screen.centerX,
			y = startY + (i - 1) * 64,
			id = data.id,
			label = data.label,
			labelAlign = "center",
			labelColor = { default={ 0.9 }, over={ 1 } },
			onEvent = function( event )
				if event.phase == "ended" then
					audio.play( audioHandles.click )
					if callback then callback() end
				end
				return true
			end,
			width = 240,
			height = 52,
			fontSize = 28,
			font = settings.fonts.bold,
			shape = "rect",
			fillColor = { default={ 0, 0.7 }, over={ 0, 0.9 } },
		})
		group:insert( buttons[data.id] )
	end

	-----------------------------------------------------------------------
	-- Key listener: any key bound to the "menu" action closes the pause menu.
	-- The bindings are read on every key press, so a key the player rebinds in the options works at once.
	-- The key press that opened the pause menu does not close it, because a key listener
	-- added while Solar2D is sending a key event only hears the key events after it.

	local function onKey( event )
		if event.phase == "down" then
			local menuKeys = controls.getBindings().menu

			-- Each action has a main key and an optional secondary key.
			for i = 1, 2 do
				if menuKeys[i] == event.keyName then
					if onResume then onResume() end
					return true
				end
			end
		end
		return false
	end

	Runtime:addEventListener( "key", onKey )

	-----------------------------------------------------------------------
	-- Disable the widget (suspend key listener and buttons).
	-- Used when showing an overlay on top of the pause menu.

	function group:disable()
		Runtime:removeEventListener( "key", onKey )
		for _, button in pairs( buttons ) do
			button:setEnabled( false )
		end
	end

	-----------------------------------------------------------------------
	-- Enable the widget (restore key listener and buttons).

	function group:enable()
		Runtime:addEventListener( "key", onKey )
		for _, button in pairs( buttons ) do
			button:setEnabled( true )
		end
	end

	-----------------------------------------------------------------------
	-- Destroy method.

	function group:destroy()
		Runtime:removeEventListener( "key", onKey )
		for _, button in pairs( buttons ) do
			button:setEnabled( false )
		end

		-- The screenshot taken for the save screen is only needed while the pause menu is open.
		saveManager.removeTempScreenshot()

		display.remove( group )
	end

	return group
end

---------------------------------------------------------------------------

return pauseMenu
