local composer = require("composer")
local scene = composer.newScene()

---------------------------------------------------------------------------

-- Common plugins, modules, libraries & classes.
local screen = require( "classes.screen" )
local loadsave = require( "classes.loadsave" )
local music = require( "classes.music" )
local controls = require( "classes.controls" )
local settings = require( "libs.settings" )
local widget = require( "widget" )
local sceneTitle = require( "widgets.sceneTitle" )

---------------------------------------------------------------------------

-- Shared handles for the core UI sounds.
local audioHandles = require( "libs.audioHandles" )

---------------------------------------------------------------------------

-- Forward declarations & variables.
local buttonBack
local onClose
local audioGroup, controlsGroup
local underlineAudio, underlineControls
local keySlotButtons = {}
local captureGroup, captureKeyListener, captureMessage

-- How far, in content units, a touch on a key button may move before it counts as scrolling the list.
local scrollDragThreshold = 10

-- Left cap, middle, right cap and fill, then the handle. widget.newSlider takes the frame sizes from these frames.
local sliderSheetOptions = {
	frames = {
		{ x = 0, y = 0, width = 16, height = 32 },
		{ x = 16, y = 0, width = 16, height = 32 },
		{ x = 32, y = 0, width = 16, height = 32 },
		{ x = 48, y = 0, width = 16, height = 32 },
		{ x = 64, y = 0, width = 32, height = 32 },
	},
	sheetContentWidth = 96,
	sheetContentHeight = 32,
}
local sliderSheet = graphics.newImageSheet( "assets/images/template/ui/slider.png", sliderSheetOptions )

-- The fullscreen checkbox off, then on.
local toggleSheetOptions = {
	width = 64,
	height = 32,
	numFrames = 2,
	sheetContentWidth = 128,
	sheetContentHeight = 32,
}
local toggleSheet = graphics.newImageSheet( "assets/images/template/ui/toggle.png", toggleSheetOptions )

---------------------------------------------------------------------------

-- Key name display formatting.

local keyDisplayNames = {
	["left"] = "LEFT",
	["right"] = "RIGHT",
	["up"] = "UP",
	["down"] = "DOWN",
	["space"] = "SPACE",
	["enter"] = "ENTER",
	["escape"] = "ESC",
	["tab"] = "TAB",
	["deleteBack"] = "BKSP",
	["deleteForward"] = "DEL",
	["leftShift"] = "L-SHIFT",
	["rightShift"] = "R-SHIFT",
	["leftControl"] = "L-CTRL",
	["rightControl"] = "R-CTRL",
	["leftAlt"] = "L-ALT",
	["rightAlt"] = "R-ALT",
}

local function formatKeyName( keyName )
	return keyDisplayNames[keyName] or string.upper( keyName )
end

---------------------------------------------------------------------------

-- Action order and labels for the controls tab, derived from the
-- settings.controls list (see data/settingsCore.lua).

local actionOrder = {}
local actionLabels = {}

for i = 1, #settings.controls do
	local action = settings.controls[i]
	actionOrder[i] = action.id
	actionLabels[action.id] = action.label
end

---------------------------------------------------------------------------

-- Functions.

local function switchTab( tabName )
	audioGroup.isVisible = (tabName == "audio")
	controlsGroup.isVisible = (tabName == "controls")
	underlineAudio.isVisible = (tabName == "audio")
	underlineControls.isVisible = (tabName == "controls")
end


local function refreshKeySlotLabels()
	local bindings = loadsave.userdata.controls
	for action, slotButtons in pairs( keySlotButtons ) do
		local keys = bindings[action] or {}
		for slot = 1, 2 do
			local keyName = keys[slot]
			local displayText = keyName and formatKeyName( keyName ) or "-"
			slotButtons[slot]:setLabel( displayText )
		end
	end
end


local function cancelKeyCapture()
	if captureKeyListener then
		Runtime:removeEventListener( "key", captureKeyListener )
		captureKeyListener = nil
	end
	if captureGroup then
		display.remove( captureGroup )
		captureGroup = nil
		captureMessage = nil
	end
end


local function isMainKey( keyName )
	for _, keys in pairs( loadsave.userdata.controls ) do
		if keys[1] == keyName then
			return true
		end
	end
	return false
end


local function applyKeyBinding( action, slotIndex, newKey )
	local bindings = loadsave.userdata.controls

	-- If the same key is already in this exact slot, clear it (toggle off).
	if bindings[action] and bindings[action][slotIndex] == newKey then
		bindings[action][slotIndex] = nil
	else
		-- Remove this key from other Secondary (slot 2) bindings to prevent conflicts.
		for _, keys in pairs( bindings ) do
			if keys[2] == newKey then
				keys[2] = nil
			end
		end

		-- Assign the new key.
		bindings[action] = bindings[action] or {}
		bindings[action][slotIndex] = newKey
	end

	-- Persist, rebuild key map, and refresh UI.
	loadsave.save( loadsave.userdata, "userdata.json" )
	controls.rebuildKeyMap()
	refreshKeySlotLabels()
end


local function startKeyCapture( action, slotIndex )
	if captureGroup then return end

	captureGroup = display.newGroup()
	scene.view:insert( captureGroup )

	-- Semi-transparent backdrop.
	local backdrop = display.newRect(
		captureGroup,
		screen.centerX, screen.centerY,
		screen.width, screen.height
	)
	backdrop:setFillColor( 0, 0.7 )

	-- The menu action's main key closes menus, so here it closes the capture view.
	local menuKey = loadsave.userdata.controls.menu[1]

	-- Instruction text.
	display.newText({
		parent = captureGroup,
		text = "Press a key for \"" .. actionLabels[action] .. "\"",
		fontSize = 28,
		font = settings.fonts.bold,
		x = screen.centerX,
		y = screen.centerY - 20,
		width = 500,
		align = "center",
	})

	local cancelText = display.newText({
		parent = captureGroup,
		text = "Press " .. formatKeyName( menuKey ) .. " or tap outside to cancel",
		fontSize = 20,
		font = settings.fonts.regular,
		x = screen.centerX,
		y = screen.centerY + 28,
	})
	cancelText:setFillColor( 0.6 )

	captureMessage = display.newText({
		parent = captureGroup,
		text = "",
		fontSize = 22,
		font = settings.fonts.bold,
		x = screen.centerX,
		y = screen.centerY + 72,
	})
	captureMessage:setFillColor( 1, 0.45, 0.45 )

	-- Cancel on touch.
	backdrop:addEventListener( "touch", function( event )
		if event.phase == "ended" then
			cancelKeyCapture()
		end
		return true
	end )

	-- Capture the next key press.
	captureKeyListener = function( event )
		if event.phase == "down" then
			local keyName = event.keyName
			captureMessage.text = ""

			if keyName == menuKey then
				cancelKeyCapture()

			elseif isMainKey( keyName ) then
				captureMessage.text = formatKeyName( keyName ) .. " is already in use"

			else
				applyKeyBinding( action, slotIndex, keyName )
				cancelKeyCapture()
			end
		end
		return true
	end
	Runtime:addEventListener( "key", captureKeyListener )
end


local function resetControlsToDefaults()
	for i = 1, #settings.controls do
		local action = settings.controls[i]
		loadsave.userdata.controls[action.id] = {}
		for slot = 1, math.min( 2, #action.keys ) do
			loadsave.userdata.controls[action.id][slot] = action.keys[slot]
		end
	end

	loadsave.save( loadsave.userdata, "userdata.json" )
	controls.rebuildKeyMap()
	refreshKeySlotLabels()
end


local function buttonEvent( event )
	if event.phase == "ended" then
		local id = event.target.id

		audio.play( audioHandles.click )

		if id == "back" then
			composer.hideOverlay( "fade", 250 )

		end
	end
end


-- Apply the volume on every slider event so the player hears it change while dragging.
local function sliderListener( event )
	local id = event.target.id

	loadsave.userdata.audio.volume[id] = event.value

	if id == "master" then
		audio.setVolume( event.value / 100 )
	elseif id == "music" then
		music.updateVolume()
	elseif id == "sfx" then
		for channel = 2, 32 do
			audio.setVolume( event.value / 100, { channel = channel } )
		end
	end

	-- Save only when the drag ends or is cancelled, so dragging does not write the file on every event.
	if event.phase == "ended" or event.phase == "cancelled" then
		loadsave.save( loadsave.userdata, "userdata.json" )

		-- Play one click at the new SFX level on release, so the player hears what they set.
		if id == "sfx" and event.phase == "ended" then
			audio.play( audioHandles.click )
		end
	end
end


-- A volume slider with its label above it. The id is the userdata volume key the slider sets.
local function newVolumeSlider( parent, id, labelText, y )
	local frames = sliderSheetOptions.frames
	local slider = widget.newSlider({
		sheet = sliderSheet,
		leftFrame = 1,
		middleFrame = 2,
		rightFrame = 3,
		fillFrame = 4,
		handleFrame = 5,
		frameWidth = frames[1].width,
		frameHeight = frames[1].height,
		handleWidth = frames[5].width,
		handleHeight = frames[5].height,
		x = screen.centerX,
		y = y,
		width = 320,
		id = id,
		value = loadsave.userdata.audio.volume[id],
		listener = sliderListener,
	})
	parent:insert( slider )

	local label = display.newText({
		parent = parent,
		text = labelText,
		fontSize = 24,
		font = settings.fonts.bold,
	})
	label.x = screen.centerX
	label.y = slider.y - slider.height*0.5 - 8

	return slider
end


local function switchPress( event )
	local switch = event.target

	loadsave.userdata["fullscreen"] = switch.isOn
	loadsave.save( loadsave.userdata, "userdata.json" )

	if switch.isOn then
		native.setProperty( "windowMode", "fullscreen" )
	else
		native.setProperty( "windowMode", "normal" )
	end
end

---------------------------------------------------------------------------

function scene:create( event )
	local sceneGroup = self.view

	-----------------------------------------------------------------------
	-- Create background and window.

	local background = display.newRect( sceneGroup, screen.centerX, screen.centerY, screen.width, screen.height )
	background:setFillColor( 0, 0.5 )
	background:addEventListener( "touch", function() return true end )
	background:addEventListener( "tap", function() return true end )

	local window = display.newRect( sceneGroup, screen.centerX, screen.centerY, 600, 600 )
	window:setFillColor( 0, 0.9 )

	-----------------------------------------------------------------------
	-- Create title text.

	local title = sceneTitle.new( sceneGroup, "Options", screen.centerX, window.y - window.height*0.5 + 20 )

	-----------------------------------------------------------------------
	-- Create tab buttons.

	local tabY = title.y + title.height + 32
	local tabWidth = 200
	local tabSpacing = 8
	local tabHeight = 40

	local tabAudioX = screen.centerX - tabWidth*0.5 - tabSpacing*0.5
	local tabControlsX = screen.centerX + tabWidth*0.5 + tabSpacing*0.5

	local tabAudioBtn = widget.newButton({
		x = tabAudioX,
		y = tabY,
		width = tabWidth,
		height = tabHeight,
		label = "Audio",
		labelAlign = "center",
		fontSize = 22,
		font = settings.fonts.bold,
		labelColor = { default={ 0.9 }, over={ 1 } },
		shape = "rect",
		fillColor = { default={ 0.1, 0.1, 0.15 }, over={ 0.15, 0.15, 0.2 } },
		onEvent = function( event )
			if event.phase == "ended" then
				audio.play( audioHandles.click )
				switchTab( "audio" )
			end
			return true
		end,
	})
	sceneGroup:insert( tabAudioBtn )

	local tabControlsBtn = widget.newButton({
		x = tabControlsX,
		y = tabY,
		width = tabWidth,
		height = tabHeight,
		label = "Controls",
		labelAlign = "center",
		fontSize = 22,
		font = settings.fonts.bold,
		labelColor = { default={ 0.9 }, over={ 1 } },
		shape = "rect",
		fillColor = { default={ 0.1, 0.1, 0.15 }, over={ 0.15, 0.15, 0.2 } },
		onEvent = function( event )
			if event.phase == "ended" then
				audio.play( audioHandles.click )
				switchTab( "controls" )
			end
			return true
		end,
	})
	sceneGroup:insert( tabControlsBtn )

	-- Tab underline indicators.
	underlineAudio = display.newRect( sceneGroup, tabAudioX, tabY + tabHeight*0.5 + 4, tabWidth - 8, 4 )
	underlineAudio:setFillColor( 0.8, 0.8, 1 )

	underlineControls = display.newRect( sceneGroup, tabControlsX, tabY + tabHeight*0.5 + 4, tabWidth - 8, 4 )
	underlineControls:setFillColor( 0.8, 0.8, 1 )
	underlineControls.isVisible = false

	local contentTopY = tabY + tabHeight*0.5 + 16

	-----------------------------------------------------------------------
	-- Audio tab content.

	audioGroup = display.newGroup()
	sceneGroup:insert( audioGroup )

	local masterSlider = newVolumeSlider( audioGroup, "master", "Master Volume", contentTopY + settings.options.audioTop )
	local musicSlider = newVolumeSlider( audioGroup, "music", "Music Volume", masterSlider.y + masterSlider.height + 64 )
	local sfxSlider = newVolumeSlider( audioGroup, "sfx", "SFX Volume", musicSlider.y + musicSlider.height + 64 )

	-----------------------------------------------------------------------
	-- Fullscreen checkbox.

	local fullscreenCheckbox = widget.newSwitch({
		x = window.x + 84,
		y = sfxSlider.y + sfxSlider.height + 48,
		width = toggleSheetOptions.width,
		height = toggleSheetOptions.height,
		style = "checkbox",
		sheet = toggleSheet,
		frameOff = 1,
		frameOn = 2,
		id = "fullscreen",
		onPress = switchPress,
		initialSwitchState = loadsave.userdata["fullscreen"],
	})
	audioGroup:insert( fullscreenCheckbox )

	local titleFullscreen = display.newText({
		parent = audioGroup,
		text = "Fullscreen",
		fontSize = 24,
		font = settings.fonts.bold,
	})
	titleFullscreen.anchorX = 1
	titleFullscreen.x = fullscreenCheckbox.x - fullscreenCheckbox.width*0.5 - 16
	titleFullscreen.y = fullscreenCheckbox.y

	-----------------------------------------------------------------------
	-- Controls tab content.

	controlsGroup = display.newGroup()
	sceneGroup:insert( controlsGroup )
	controlsGroup.isVisible = false

	-- Normalize bindings to 2 slots max.
	for _, keys in pairs( loadsave.userdata.controls ) do
		for i = #keys, 3, -1 do
			keys[i] = nil
		end
	end

	-- Column positions.
	local labelX = 210
	local slot1X = 540
	local slot2X = 680
	local slotWidth = 108
	local slotHeight = 36

	-- Column headers.
	local headerKey1 = display.newText({
		parent = controlsGroup,
		text = "Main",
		fontSize = 18,
		font = settings.fonts.regular,
		x = slot1X,
		y = contentTopY + 12,
	})
	headerKey1:setFillColor( 0.6 )

	local headerKey2 = display.newText({
		parent = controlsGroup,
		text = "Secondary",
		fontSize = 18,
		font = settings.fonts.regular,
		x = slot2X,
		y = contentTopY + 12,
	})
	headerKey2:setFillColor( 0.6 )

	-- Reset to Defaults sits just above the Back button at the window bottom.
	local resetHeight = 44
	local resetY = window.y + window.height*0.5 - 88

	-- The action rows scroll between the column headers and the Reset button,
	-- so a template can list more actions than the tab has room for.
	local rowSpacing = 52
	local scrollWidth = window.width - 40
	local scrollTop = contentTopY + 24
	local scrollBottom = resetY - resetHeight*0.5 - 8
	local scrollHeight = scrollBottom - scrollTop

	local controlsScroll = widget.newScrollView({
		x = screen.centerX,
		y = scrollTop + scrollHeight*0.5,
		width = scrollWidth,
		height = scrollHeight,
		scrollWidth = scrollWidth,
		scrollHeight = #actionOrder * rowSpacing,
		horizontalScrollDisabled = true,
		hideBackground = true,
	})
	controlsGroup:insert( controlsScroll )

	-- Objects added with scrollView:insert measure x and y from the scroll view's top-left corner,
	-- so the column positions are moved by the scroll view's left edge.
	local scrollLeft = screen.centerX - scrollWidth*0.5
	local labelLocalX = labelX - scrollLeft
	local slot1LocalX = slot1X - scrollLeft
	local slot2LocalX = slot2X - scrollLeft

	keySlotButtons = {}

	for i = 1, #actionOrder do
		local action = actionOrder[i]
		local rowY = rowSpacing*0.5 + (i - 1) * rowSpacing
		local bindings = loadsave.userdata.controls[action] or {}

		-- Action label.
		local label = display.newText({
			text = actionLabels[action],
			fontSize = 22,
			font = settings.fonts.bold,
			x = labelLocalX,
			y = rowY,
		})
		label.anchorX = 0
		controlsScroll:insert( label )

		-- Key slot buttons.
		keySlotButtons[action] = {}
		for slot = 1, 2 do
			local keyName = bindings[slot]
			local displayText = keyName and formatKeyName( keyName ) or "-"

			if slot == 1 then
				-- Main keys: static, non-interactive display.
				local slotBackground = display.newRoundedRect( slot1LocalX, rowY, slotWidth, slotHeight, 4 )
				slotBackground:setFillColor( 0.12, 0.15, 0.22 )
				controlsScroll:insert( slotBackground )

				local slotLabel = display.newText({
					text = displayText,
					fontSize = 20,
					font = settings.fonts.regular,
					x = slot1LocalX,
					y = rowY,
				})
				slotLabel:setFillColor( 0.65, 0.72, 0.85 )
				controlsScroll:insert( slotLabel )

				-- Store a lightweight object so refreshKeySlotLabels can update the text.
				keySlotButtons[action][slot] = { setLabel = function( _, labelText ) slotLabel.text = labelText end }
			else
				-- Secondary keys: interactive buttons.
				local slotButton = widget.newButton({
					x = slot2LocalX,
					y = rowY,
					width = slotWidth,
					height = slotHeight,
					label = displayText,
					labelAlign = "center",
					fontSize = 20,
					font = settings.fonts.regular,
					labelColor = { default={ 0.9 }, over={ 1 } },
					shape = "rect",
					fillColor = { default={ 0.15, 0.15, 0.2 }, over={ 0.25, 0.25, 0.3 } },
					id = action .. "_" .. slot,
					onEvent = function( buttonEvent )
						if buttonEvent.phase == "moved" then
							-- A drag is a scroll, not a press, so hand the touch back to the scroll view.
							if math.abs( buttonEvent.y - buttonEvent.yStart ) > scrollDragThreshold then
								controlsScroll:takeFocus( buttonEvent )
							end

						elseif buttonEvent.phase == "ended" then
							startKeyCapture( action, slot )
						end
						return true
					end,
				})
				controlsScroll:insert( slotButton )
				keySlotButtons[action][slot] = slotButton
			end
		end
	end

	-- Reset to Defaults button.
	local resetBtn = widget.newButton({
		x = screen.centerX,
		y = resetY,
		width = 260,
		height = resetHeight,
		label = "Reset to Defaults",
		labelAlign = "center",
		fontSize = 20,
		font = settings.fonts.bold,
		labelColor = { default={ 0.9, 0.6, 0.6 }, over={ 1, 0.7, 0.7 } },
		shape = "rect",
		fillColor = { default={ 0.3, 0.1, 0.1 }, over={ 0.4, 0.15, 0.15 } },
		id = "resetControls",
		onEvent = function( buttonEvent )
			if buttonEvent.phase == "ended" then
				audio.play( audioHandles.click )
				resetControlsToDefaults()
			end
			return true
		end,
	})
	controlsGroup:insert( resetBtn )

	-----------------------------------------------------------------------
	-- Create back button.

	buttonBack = widget.newButton({
		x = screen.centerX,
		y = window.y + window.height*0.5 - 32,
		id = "back",
		label = "Back",
		labelAlign = "center",
		labelColor = { default={ 0.9 }, over={ 1 } },
		onEvent = buttonEvent,
		width = 200,
		height = 60,
		fontSize = 28,
		font = settings.fonts.bold,
		shape = "rect",
		fillColor = { default={ 0, 0.7 }, over={ 0, 0.9 } },
		isEnabled = false,
	})
	sceneGroup:insert( buttonBack )

end

---------------------------------------------------------------------------

function scene:show( event )
	local sceneGroup = self.view

	if event.phase == "will" then
		local params = event.params or {}
		onClose = params.onClose

	elseif event.phase == "did" then
		buttonBack:setEnabled( true )

	end
end

---------------------------------------------------------------------------

function scene:hide( event )
	local sceneGroup = self.view

	if event.phase == "will" then
		cancelKeyCapture()
		buttonBack:setEnabled( false )

	elseif event.phase == "did" then
		if onClose then
			onClose()
			onClose = nil
		end
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
