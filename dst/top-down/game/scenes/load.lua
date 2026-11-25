local composer = require("composer")
local scene = composer.newScene()

---------------------------------------------------------------------------

-- Common plugins, modules, libraries & classes.
local screen = require( "classes.screen" )
local saveManager = require( "classes.saveManager" )
local music = require( "classes.music" )
local widget = require( "widget" )
local settings = require( "libs.settings" )
local menuBackground = require( "widgets.menuBackground" )
local sceneTitle = require( "widgets.sceneTitle" )

---------------------------------------------------------------------------

-- Shared handles for the core UI sounds.
local audioHandles = require( "libs.audioHandles" )

---------------------------------------------------------------------------

-- Forward declarations & variables.
local currentMode
local currentGameState
local currentScreenshotFile
local currentFromGame
local currentIsOverlay
local currentOnClose
local buttonBack

local slotGroups = {}
local slotButtons = {}
local confirmGroup
local savedPanel
local savedPanelTransition

local maxSlots = saveManager.getMaxSlots()

-- Layout constants.
local slotWidth = 272
local horizontalGap = 32
local verticalGap = 32

---------------------------------------------------------------------------

-- Functions.

-- Turn all slot buttons and the Back button on or off.
local function setButtonsEnabled( isEnabled )
	for _, buttons in pairs( slotButtons ) do
		for _, slotButton in pairs( buttons ) do
			slotButton:setEnabled( isEnabled )
		end
	end
	if buttonBack then
		buttonBack:setEnabled( isEnabled )
	end
end

-- Navigate back to game with the current game state.
local function returnToGame()
	if currentIsOverlay then
		composer.hideOverlay( "fade", 250 )
	elseif currentGameState then
		composer.gotoScene( "scenes.game", {
			effect = "fade",
			time = 500,
			params = {
				savedState = currentGameState,
			}
		})
	else
		composer.gotoScene( "scenes.menu", { effect = "fade", time = 500 } )
	end
end

---------------------------------------------------------------------------

-- A dimmed screen with a rounded panel and a message in front of it, shared by the confirmation prompt and the saved panel.
-- The dimmer swallows touches, so nothing behind the panel can be pressed while it shows.
local function newMessagePanel( parent, message, messageY )
	local panelGroup = display.newGroup()
	parent:insert( panelGroup )

	local dimmer = display.newRect( panelGroup, screen.centerX, screen.centerY, screen.width, screen.height )
	dimmer:setFillColor( 0, 0.6 )
	dimmer:addEventListener( "touch", function() return true end )
	dimmer:addEventListener( "tap", function() return true end )

	local box = display.newRoundedRect( panelGroup, screen.centerX, screen.centerY, 400, 180, 12 )
	box:setFillColor( 0.1, 0.95 )

	display.newText({
		parent = panelGroup,
		text = message,
		fontSize = 24,
		font = settings.fonts.regular,
		width = 360,
		align = "center",
		x = screen.centerX,
		y = messageY,
	})

	return panelGroup
end

-- Show the saved panel for a moment and then return to game.
-- The buttons stay off until the screen closes, so the player cannot save a second time.
local function showSaveSuccess( sceneGroup )
	setButtonsEnabled( false )

	local saveSlotSettings = settings.saveSlots
	savedPanel = newMessagePanel( sceneGroup, saveSlotSettings.savedText, screen.centerY )

	savedPanelTransition = transition.to( savedPanel, {
		delay = saveSlotSettings.savedHoldTime,
		time = saveSlotSettings.savedFadeTime,
		alpha = 0,
		onComplete = function()
			savedPanelTransition = nil
			display.remove( savedPanel )
			savedPanel = nil
			returnToGame()
		end
	})
end

---------------------------------------------------------------------------

-- Dismiss the confirmation dialog.
local function hideConfirmation()
	if confirmGroup then
		display.remove( confirmGroup )
		confirmGroup = nil
	end
	-- Re-enable slot buttons.
	setButtonsEnabled( true )
end

-- Show a confirmation dialog with a message and Yes/No buttons.
local function showConfirmation( sceneGroup, message, onConfirm )
	-- Disable slot buttons while confirmation is showing.
	setButtonsEnabled( false )

	confirmGroup = newMessagePanel( sceneGroup, message, screen.centerY - 30 )

	local yesBtn = widget.newButton({
		x = screen.centerX - 80,
		y = screen.centerY + 50,
		id = "confirm_yes",
		label = "Yes",
		labelAlign = "center",
		labelColor = { default={ 0.9 }, over={ 1 } },
		width = 120,
		height = 44,
		fontSize = 24,
		font = settings.fonts.bold,
		shape = "rect",
		fillColor = { default={ 0.5, 0, 0, 0.7 }, over={ 0.7, 0, 0, 0.9 } },
		onEvent = function( event )
			if event.phase == "ended" then
				audio.play( audioHandles.click )
				hideConfirmation()
				if onConfirm then onConfirm() end
			end
			return true
		end,
	})
	confirmGroup:insert( yesBtn )

	local noBtn = widget.newButton({
		x = screen.centerX + 80,
		y = screen.centerY + 50,
		id = "confirm_no",
		label = "No",
		labelAlign = "center",
		labelColor = { default={ 0.9 }, over={ 1 } },
		width = 120,
		height = 44,
		fontSize = 24,
		font = settings.fonts.bold,
		shape = "rect",
		fillColor = { default={ 0, 0.7 }, over={ 0, 0.9 } },
		onEvent = function( event )
			if event.phase == "ended" then
				audio.play( audioHandles.click )
				hideConfirmation()
			end
			return true
		end,
	})
	confirmGroup:insert( noBtn )
end

---------------------------------------------------------------------------

-- Forward declare so the slot handler and createSlot can reference each other.
local createSlot

-- Handle save/load/remove button presses inside a slot.
local function handleSlotButton( event )
	if event.phase == "ended" then
		local id = event.target.id or ""
		local action, slotStr = id:match( "^(%a+)_(%d+)$" )
		local slotIndex = tonumber( slotStr )

		if not action or not slotIndex then return true end

		audio.play( audioHandles.click )

		local sceneGroup = scene.view

		if action == "save" then
			local slotData = saveManager.loadFromSlot( slotIndex )
			if slotData then
				-- Slot has existing data, confirm overwrite.
				showConfirmation( sceneGroup, "Overwrite save in slot " .. slotIndex .. "?", function()
					saveManager.saveToSlot( slotIndex, currentGameState, currentScreenshotFile )
					showSaveSuccess( sceneGroup )
				end)
			else
				-- Empty slot, save immediately.
				saveManager.saveToSlot( slotIndex, currentGameState, currentScreenshotFile )
				showSaveSuccess( sceneGroup )
			end

		elseif action == "load" then
			local saveData = saveManager.loadFromSlot( slotIndex )
			if saveData and saveData.gameState then
				local loadParams = {
					savedState = saveData.gameState,
				}
				local targetScene = "scenes.game"

				-- gotoScene to the current scene runs its hide and show events again but keeps its view,
				-- so create does not run and the scene is not rebuilt. A reload of the scene under this
				-- overlay goes through the refresh scene, which removes the scene before it returns to it.
				if currentIsOverlay and composer.getSceneName( "current" ) == targetScene then
					targetScene = "scenes.refresh"
				end

				-- The fade out overlaps the scene fade, and the game scene starts its own music when it shows.
				music.stop()
				composer.gotoScene( targetScene, {
					effect = "fade",
					time = 500,
					params = loadParams,
				})
			end

		elseif action == "remove" then
			showConfirmation( sceneGroup, "Remove save in slot " .. slotIndex .. "?", function()
				saveManager.removeSlot( slotIndex )
				-- Refresh this slot's display.
				if slotGroups[slotIndex] then
					local pos = slotGroups[slotIndex]._slotPos
					local slotHeight = slotGroups[slotIndex]._slotHeight
					display.remove( slotGroups[slotIndex] )
					slotGroups[slotIndex] = nil
					slotButtons[slotIndex] = nil
					createSlot( sceneGroup, slotIndex, false, currentMode, pos.x, pos.y, slotWidth, slotHeight )
					-- Enable the newly created buttons since we are in the "did" phase.
					if slotButtons[slotIndex] then
						for _, slotButton in pairs( slotButtons[slotIndex] ) do
							slotButton:setEnabled( true )
						end
					end
				end
			end)

		end
	end
	return true
end

---------------------------------------------------------------------------

-- Create a single save slot's UI at the given position.
createSlot = function( sceneGroup, slotIndex, slotData, mode, posX, posY, slotWidth, slotHeight )
	local slotGroup = display.newGroup()
	sceneGroup:insert( slotGroup )

	-- Store position info for potential refresh.
	slotGroup._slotPos = { x = posX, y = posY }
	slotGroup._slotHeight = slotHeight

	slotGroups[slotIndex] = slotGroup
	slotButtons[slotIndex] = {}

	-- Slot background.
	local slotBackground = display.newRoundedRect( slotGroup, posX, posY, slotWidth, slotHeight, 8 )
	slotBackground:setFillColor( 0, 0.8 )

	local buttonInset = settings.saveSlots.buttonInset
	local slotLeft = posX - slotWidth * 0.5 + buttonInset
	local slotRight = posX + slotWidth * 0.5 - buttonInset
	local slotBottom = posY + slotHeight * 0.5 - buttonInset
	local hasData = slotData and true or false

	if hasData then
		-- Timestamp at the top of the slot.
		display.newText({
			parent = slotGroup,
			text = saveManager.formatTimestamp( slotData.timestamp ),
			fontSize = 18,
			font = settings.fonts.regular,
			x = posX,
			y = posY - slotHeight * 0.5 + 24,
		})

		-- Attempt to load the screenshot.
		local screenshotLoaded = false
		if slotData.screenshotFile then
			local fullPath = system.pathForFile( slotData.screenshotFile, system.DocumentsDirectory )
			if fullPath then
				local file = io.open( fullPath, "r" )
				if file then
					file:close()
					local img = display.newImage( slotGroup, slotData.screenshotFile, system.DocumentsDirectory )
					if img then
						local maxW = slotWidth - 16
						local maxH = slotHeight - 100
						local scale = math.min( maxW / img.width, maxH / img.height )
						img.xScale, img.yScale = scale, scale
						img.x, img.y = posX, posY - 4
						screenshotLoaded = true
					end
				end
			end
		end

		if not screenshotLoaded then
			local placeholder = display.newText({
				parent = slotGroup,
				text = "Save #" .. slotIndex,
				fontSize = 28,
				font = settings.fonts.regular,
				x = posX,
				y = posY - 4,
			})
			placeholder:setFillColor( 0.5 )
		end

		-- Remove button (slot has data).
		local removeBtn = widget.newButton({
			id = "remove_" .. slotIndex,
			label = "Remove",
			labelAlign = "center",
			labelColor = { default={ 0.9 }, over={ 1 } },
			onEvent = handleSlotButton,
			width = 92,
			height = 36,
			fontSize = 18,
			font = settings.fonts.regular,
			shape = "rect",
			fillColor = { default={ 0.4, 0, 0, 0.8 }, over={ 0.6, 0, 0, 0.9 } },
			isEnabled = false,
		})
		removeBtn.anchorX, removeBtn.anchorY = 0, 1
		removeBtn.x, removeBtn.y = slotLeft, slotBottom
		slotGroup:insert( removeBtn )
		slotButtons[slotIndex].remove = removeBtn

		-- Action button (Save or Load).
		local actionLabel = mode == "save" and "Save" or "Load"
		local actionBtn = widget.newButton({
			id = (mode == "save" and "save_" or "load_") .. slotIndex,
			label = actionLabel,
			labelAlign = "center",
			labelColor = { default={ 0.9 }, over={ 1 } },
			onEvent = handleSlotButton,
			width = 84,
			height = 36,
			fontSize = 18,
			font = settings.fonts.regular,
			shape = "rect",
			fillColor = { default={ 0, 0.7 }, over={ 0, 0.9 } },
			isEnabled = false,
		})
		actionBtn.anchorX, actionBtn.anchorY = 1, 1
		actionBtn.x, actionBtn.y = slotRight, slotBottom
		slotGroup:insert( actionBtn )
		slotButtons[slotIndex].action = actionBtn

	else
		-- Empty slot.
		if mode == "save" then
			-- Show placeholder and Save button.
			local placeholder = display.newText({
				parent = slotGroup,
				text = "Save #" .. slotIndex,
				fontSize = 28,
				font = settings.fonts.regular,
				x = posX,
				y = posY - 4,
			})
			placeholder:setFillColor( 0.5 )

			local actionBtn = widget.newButton({
				id = "save_" .. slotIndex,
				label = "Save",
				labelAlign = "center",
				labelColor = { default={ 0.9 }, over={ 1 } },
				onEvent = handleSlotButton,
				width = 84,
				height = 36,
				fontSize = 18,
				font = settings.fonts.regular,
				shape = "rect",
				fillColor = { default={ 0, 0.7 }, over={ 0, 0.9 } },
				isEnabled = false,
			})
			actionBtn.anchorX, actionBtn.anchorY = 1, 1
			actionBtn.x, actionBtn.y = slotRight, slotBottom
			slotGroup:insert( actionBtn )
			slotButtons[slotIndex].action = actionBtn

		else
			-- Load mode: empty slot, just show "Empty".
			local placeholder = display.newText({
				parent = slotGroup,
				text = "Empty",
				fontSize = 28,
				font = settings.fonts.regular,
				x = posX,
				y = posY,
			})
			placeholder:setFillColor( 0.4 )
		end
	end

	-- Bring confirmation group to front if it exists.
	if confirmGroup then
		confirmGroup:toFront()
	end

	return slotGroup
end

---------------------------------------------------------------------------

-- Back button handler.
local function handleButtonEvent( event )
	if event.phase == "ended" then
		local id = event.target.id

		audio.play( audioHandles.click )

		if id == "back" then
			if currentIsOverlay or currentFromGame then
				returnToGame()
			else
				composer.gotoScene( "scenes.menu", { effect = "fade", time = 500 } )
			end
		end
	end
	return true
end

---------------------------------------------------------------------------

function scene:create( event )
	local sceneGroup = self.view

	-- Create local references to passed parameters.
	local sceneParams = event.params or {}
	currentMode = sceneParams.mode or "load"
	currentGameState = sceneParams.gameState
	currentScreenshotFile = sceneParams.screenshotFile
	currentFromGame = sceneParams.fromGame or false
	currentIsOverlay = sceneParams.isOverlay or false
	currentOnClose = sceneParams.onClose

	-- Reset slot tracking tables.
	slotGroups = {}
	slotButtons = {}
	confirmGroup = nil

	-----------------------------------------------------------------------
	-- Create the panning background image to fill the screen.

	menuBackground.new( sceneGroup )

	-----------------------------------------------------------------------
	-- Create title text.

	local titleText = currentMode == "save" and "Save" or "Load"
	sceneTitle.new( sceneGroup, titleText, screen.centerX, screen.minY + settings.saveSlots.titleTop )

	-----------------------------------------------------------------------
	-- Calculate grid layout.

	local gridTop = screen.minY + 100
	local gridBottom = screen.maxY - 76
	local slotHeight = math.floor( (gridBottom - gridTop - verticalGap) / 2 )

	local col1X = screen.centerX - slotWidth * 0.5 - horizontalGap * 0.5
	local col2X = screen.centerX + slotWidth * 0.5 + horizontalGap * 0.5
	local row1Y = gridTop + slotHeight * 0.5
	local row2Y = gridTop + slotHeight + verticalGap + slotHeight * 0.5

	local positions = {
		{ x = col1X, y = row1Y },
		{ x = col2X, y = row1Y },
		{ x = col1X, y = row2Y },
		{ x = col2X, y = row2Y },
	}

	-----------------------------------------------------------------------
	-- Get save slot data and build the grid.

	local slotsInfo = saveManager.getAllSlotInfo()

	for i = 1, maxSlots do
		createSlot( sceneGroup, i, slotsInfo[i], currentMode, positions[i].x, positions[i].y, slotWidth, slotHeight )
	end

	-----------------------------------------------------------------------
	-- Create back button.

	buttonBack = widget.newButton({
		id = "back",
		label = "Back",
		labelAlign = "center",
		fontSize = 28,
		font = settings.fonts.bold,
		labelColor = { default={ 0.9 }, over={ 1 } },
		fillColor = { default={ 0, 0.7 }, over={ 0, 0.9 } },
		width = 120,
		height = 52,
		onEvent = handleButtonEvent,
		shape = "rect",
		isEnabled = false,
	})
	buttonBack.x = screen.minX + 10
	buttonBack.y = screen.maxY - 10
	buttonBack.anchorX, buttonBack.anchorY = 0, 1
	sceneGroup:insert( buttonBack )
end

---------------------------------------------------------------------------

function scene:show( event )
	local sceneGroup = self.view

	if event.phase == "will" then


	elseif event.phase == "did" then
		-- Enable all buttons.
		setButtonsEnabled( true )

	end
end

---------------------------------------------------------------------------

function scene:hide( event )
	local sceneGroup = self.view

	if event.phase == "will" then
		-- Stop the saved panel, so it cannot close a screen that opens after this one.
		if savedPanelTransition then
			transition.cancel( savedPanelTransition )
			savedPanelTransition = nil
		end
		display.remove( savedPanel )
		savedPanel = nil

		-- Disable all buttons.
		setButtonsEnabled( false )

	elseif event.phase == "did" then
		if currentOnClose then
			currentOnClose()
			currentOnClose = nil
		end

	end
end

---------------------------------------------------------------------------

function scene:destroy( event )
	slotGroups = {}
	slotButtons = {}
	confirmGroup = nil
	savedPanel = nil
end

---------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

---------------------------------------------------------------------------

return scene
