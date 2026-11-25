-- The visual novel scene: plays the Spyric Story Weaver story named in data/settingsTemplate.lua.

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local composer = require( "composer" )
local weaver = require( "libs.spyricStoryWeaver" )
local screen = require( "classes.screen" )
local controls = require( "classes.controls" )
local music = require( "classes.music" )
local pauseCreate = require( "widgets.pause" )
local menuButton = require( "widgets.menuButton" )
local inventoryButton = require( "widgets.inventoryButton" )
local inventoryPanel = require( "widgets.inventoryPanel" )
local inventory = require( "classes.inventory" )
local settings = require( "libs.settings" )
local audioHandles = require( "libs.audioHandles" )

-- libs.utils replaces table.copy with a version that also copies nested tables, and adds display.scaleDisplayObject.
require( "libs.utils" )

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local storySettings = settings.visualNovel
local storyName = storySettings.storyName

-- Weaver keeps the story, its variables and visit counts in a global table named after the story without whitespace.
local storyGlobalKey = "WEAVERx" .. string.gsub( storyName, "%s+", "" )

-- Every character animation carries this tag, so leaving the scene cancels them all.
local animationTag = "visualNovelCharacters"

local sceneGroup
local backgroundGroup, characterGroup, textGroup, minigameLayer
local touchSensor, textBox

-- The open inventory goes in panelLayer, below the inventory button and the money, so the button can close it.
local panelLayer, hudGroup
local moneyPlate, moneyText

-- True from the moment the scene is on screen until it starts to leave.
local isRunning = false

local pauseMenu
local activeMinigame

local currentNode
local node, nodeIndex

-- What was in place just before the current node was entered; a load restores it and enters the node again.
local nodeEntryData
local nodeEntryBackgroundFile
local nodeEntryCharacters
local nodeEntryInventory

local background
local backgroundFile

-- The characters on screen by name: { name, expression, position, object }.
local characters = {}

-- Characters fading out by name, kept until their fade ends or a tap finishes it.
local leavingCharacters = {}

-- The story text and links on screen.
local texts = {}

local getNode
local getContent
local onKeyAction
local openPauseMenu

--------------------------------------------------------------------------------------
-- Functions

local function canAdvance()
	return isRunning and not pauseMenu and not activeMinigame and not inventoryPanel.isOpen()
end

local function storySaveData()
	return _G[storyGlobalKey].saveData
end

-- The story variable $money as the settings write it, such as "$ 100".
local function moneyString()
	return string.format( storySettings.money.format, storySaveData().money or 0 )
end

-- Place the money beside the inventory button, on a plate as wide as the amount.
local function layoutMoney()
	local config = storySettings.money
	local buttonX, buttonY = inventoryButton.getPosition()
	local plateLeft = buttonX + settings.inventoryButton.size * 0.5 + config.gap

	moneyPlate.width = moneyText.width + config.platePadding * 2
	moneyPlate.height = settings.inventoryButton.size
	moneyPlate.x = plateLeft + moneyPlate.width * 0.5
	moneyPlate.y = buttonY

	moneyText.x = plateLeft + config.platePadding
	moneyText.y = buttonY
end

-- Show the current amount beside the button, and in the inventory while it is open.
local function refreshMoney()
	moneyText.text = moneyString()
	layoutMoney()
	inventoryPanel.setStatus( moneyString() )
end

local function fitBackground()
	display.scaleDisplayObject( background, screen.width, screen.height )
	background.x = screen.centerX
	background.y = screen.centerY
end

local function showBackground( filename )
	display.remove( background )
	background = nil
	backgroundFile = filename

	if filename then
		local config = storySettings.background
		background = display.newImageRect( backgroundGroup, filename, config.width, config.height )
		fitBackground()
	end
end

local function positionX( position )
	return screen.minX + screen.width * storySettings.characters.positions[position]
end

-- A new character image at its position, at the given drawing order in characterGroup or on top of it.
local function newCharacterObject( name, expression, position, index )
	local config = storySettings.characters
	local filename = config.folder .. name .. "-" .. expression .. ".png"

	local object = display.newImageRect( characterGroup, filename, config.height * config.imageWidth / config.imageHeight, config.height )
	object.anchorY = 1
	object.x = positionX( position )
	object.y = screen.maxY
	object.characterName = name

	if index then
		characterGroup:insert( index, object )
	end

	return object
end

local function drawingOrder( object )
	for i = 1, characterGroup.numChildren do
		if characterGroup[i] == object then
			return i
		end
	end
end

-- Put every character in its animation's end state, so the next command never meets a half-finished picture.
local function finishAnimations()
	for name, object in pairs( leavingCharacters ) do
		transition.cancel( object )
		display.remove( object )
		leavingCharacters[name] = nil
	end

	for _, character in pairs( characters ) do
		local object = character.object
		transition.cancel( object )
		object.x = positionX( character.position )
		object.y = screen.maxY
		object.alpha = 1
		object.xScale = 1
		object.yScale = 1
	end
end

local function showCharacter( name, expression, position )
	local config = storySettings.characters
	local character = characters[name]

	-- A character shown again while it fades out replaces the fading image.
	if leavingCharacters[name] then
		transition.cancel( leavingCharacters[name] )
		display.remove( leavingCharacters[name] )
		leavingCharacters[name] = nil
	end

	if not character then
		expression = expression or config.defaultExpression
		position = position or config.defaultPosition

		local object = newCharacterObject( name, expression, position )
		characters[name] = { name = name, expression = expression, position = position, object = object }

		-- Slide in from the side of the screen the character stands on.
		local targetX = object.x
		local side = targetX < screen.centerX and -1 or 1
		object.x = targetX + config.enterDistance * side
		object.alpha = 0
		transition.to( object, { x = targetX, alpha = 1, time = config.enterTime, transition = easing.outQuad, tag = animationTag } )
		return
	end

	expression = expression or character.expression
	position = position or character.position

	-- The new expression pops in where the old image stood, so a position change still moves it there.
	if expression ~= character.expression then
		local oldObject = character.object
		local index = drawingOrder( oldObject )
		local currentX = oldObject.x
		transition.cancel( oldObject )
		display.remove( oldObject )

		local object = newCharacterObject( name, expression, character.position, index )
		object.x = currentX
		character.object = object
		character.expression = expression

		object.xScale = config.switchScale
		object.yScale = config.switchScale
		transition.to( object, { xScale = 1, yScale = 1, time = config.switchTime, transition = easing.outQuad, tag = animationTag } )
	end

	if position ~= character.position then
		character.position = position
		transition.to( character.object, { x = positionX( position ), time = config.moveTime, transition = easing.inOutQuad, tag = animationTag } )
	end
end

local function hideCharacter( name )
	local character = characters[name]
	if not character then
		return
	end

	characters[name] = nil

	local object = character.object
	transition.cancel( object )
	leavingCharacters[name] = object

	transition.to( object, {
		alpha = 0,
		time = storySettings.characters.leaveTime,
		tag = animationTag,
		onComplete = function()
			if leavingCharacters[name] == object then
				leavingCharacters[name] = nil
			end
			display.remove( object )
		end,
	} )
end

-- The characters on screen in drawing order, as plain data for the save system.
local function listCharacters()
	local list = {}

	for i = 1, characterGroup.numChildren do
		local object = characterGroup[i]
		local character = characters[object.characterName]

		if character and character.object == object then
			list[#list+1] = { name = character.name, expression = character.expression, position = character.position }
		end
	end

	return list
end

-- Show saved characters at once, without their enter animation.
local function restoreCharacters( list )
	for i = 1, #list do
		local saved = list[i]
		local object = newCharacterObject( saved.name, saved.expression, saved.position )
		characters[saved.name] = { name = saved.name, expression = saved.expression, position = saved.position, object = object }
	end
end

local function clearText()
	for i = 1, #texts do
		display.remove( texts[i] )
		texts[i] = nil
	end
end

local function removeMinigame()
	if activeMinigame then
		activeMinigame:remove()
		activeMinigame = nil
	end
end

-- The minigame's result becomes story variables, and the passage continues where the minigame command was.
local function onMinigameComplete( result )
	removeMinigame()

	local saveData = storySaveData()
	for variableName, value in pairs( result ) do
		saveData[variableName] = value
	end

	textGroup.isVisible = true
	hudGroup.isVisible = true
	finishAnimations()
	refreshMoney()
	getContent()
end

-- The story's own <<...>> commands, by name. Each function gets the command's arguments.
-- A function that returns true stops the passage until something calls getContent again.
-- Add a function here for a new command; commands no function handles are skipped.
local storyCommands = {
	img = function( filename )
		showBackground( filename )
	end,

	del = function()
		showBackground( nil )
	end,

	character = function( action, name, expression, position )
		if action == "hide" then
			hideCharacter( name )
		else
			showCharacter( name, expression, position )
		end
	end,

	-- The minigame's counters use the top-left corner, so the inventory button and the money hide during a round.
	minigame = function( moduleName )
		local minigame = require( "classes.minigames." .. moduleName )
		textGroup.isVisible = false
		hudGroup.isVisible = false
		activeMinigame = minigame.start( minigameLayer, onMinigameComplete )
		return true
	end,

	-- <<addItem, badge>> puts the item with the id "badge" from data/items.lua in the inventory,
	-- and <<removeItem, badge>> takes it away. inventory.add returns whether the item fit, so the
	-- functions return nothing and the passage goes on.
	-- Weaver reads a passage's <<if>> conditions before these commands run, so <<if $inventory.badge>>
	-- sees the change from the next passage on, not in the passage that adds or removes the item.
	addItem = function( itemId )
		inventory.add( itemId )
	end,

	removeItem = function( itemId )
		inventory.remove( itemId )
	end,

	-- <<money, 50>> adds 50 to $money, and <<money, -50>> takes 50 away. Amounts are whole numbers;
	-- any other amount prints a warning and the command is skipped, so a typo in the story never stops the game.
	-- Weaver fills in $money and the <<if>> conditions before this command runs, so the new amount
	-- can be shown or tested from the next passage on; the display in the corner changes at once.
	money = function( amount )
		local number = tonumber( amount )
		if not number or number ~= math.floor( number ) then
			print( "WARNING: passage \"" .. tostring( currentNode ) .. "\" has <<money>> with \"" .. tostring( amount )
				.. "\", which is not a whole number. The command is skipped." )
			return
		end

		local saveData = storySaveData()
		saveData.money = ( saveData.money or 0 ) + number
		refreshMoney()
	end,
}

local function touchLink( event )
	if event.phase == "began" and canAdvance() then
		getNode( event.target.id )
	end
	return true
end

-- A text line replaces the text and links on screen, and a link goes below the line or link before it.
local function showLine( line )
	local config = storySettings.textBox
	local isLink = line[1] == "link"
	local y = screen.maxY - config.height + config.padding

	if isLink then
		local previous = texts[#texts]
		if previous then
			y = previous.y + previous.height + config.linkSpacing
		end
	else
		clearText()
	end

	local textObject = display.newText( {
		parent = textGroup,
		text = line[2],
		x = screen.centerX,
		y = y,
		width = screen.width - config.padding * 2,
		font = settings.fonts.regular,
		fontSize = config.fontSize,
		align = "center",
	} )
	textObject.anchorY = 0
	textObject.line = line
	texts[#texts+1] = textObject

	if isLink then
		textObject:setFillColor( unpack( config.linkColor ) )
		textObject.id = line[3]
		textObject:addEventListener( "touch", touchLink )
	end
end

-- Step through the current node's lines in order. Text stops and waits for the next tap
-- unless the following line is a link.
function getContent()
	while nodeIndex <= #node do
		local line = node[nodeIndex]
		nodeIndex = nodeIndex + 1

		local command = line[1]
		if command == "text" or command == "link" then
			showLine( line )

			local nextLine = node[nodeIndex]
			if nextLine and nextLine[1] ~= "link" then
				return
			end

		else
			local storyCommand = storyCommands[command]
			if storyCommand and storyCommand( unpack( line, 2 ) ) then
				return
			end
		end
	end
end

function getNode( nodeName )
	finishAnimations()
	clearText()

	-- Copy the items the player holds into the story variable $inventory first, so the passage's
	-- conditions can ask about them, such as <<if $inventory.badge>>.
	storySaveData().inventory = inventory.getHeldItems()

	currentNode = nodeName
	nodeEntryData = table.copy( storySaveData() )
	nodeEntryBackgroundFile = backgroundFile
	nodeEntryCharacters = listCharacters()
	nodeEntryInventory = table.copy( inventory.slots )

	node = weaver.getNode( nodeName, storyName )
	nodeIndex = 1

	-- A <<set>> in the passage may have changed $money.
	refreshMoney()
	getContent()
end

-- The full-screen sensor: tapping empty space advances the story.
local function sensorEvent( event )
	if event.phase == "began" and canAdvance() then
		audio.play( audioHandles.click )
		finishAnimations()
		getContent()
	end
	return true
end

-- Build the save state from the current node and what was on screen when it was entered.
-- The story text itself is not saved.
local function buildGameState()
	return {
		storyName = storyName,
		currentNode = currentNode,
		saveData = table.copy( nodeEntryData ),
		backgroundFile = nodeEntryBackgroundFile,
		characters = table.copy( nodeEntryCharacters ),
		inventory = table.copy( nodeEntryInventory ),
	}
end

-- Weaver reads the live global table, so the saved values are written into it; nodes the save lacks keep their defaults.
local function restoreSaveData( savedData )
	local saveData = storySaveData()

	for key, value in pairs( table.copy( savedData ) ) do
		if key == "node" then
			for nodeName, nodeData in pairs( value ) do
				saveData.node[nodeName] = nodeData
			end
		else
			saveData[key] = value
		end
	end
end

-- A text object keeps the wrap width it was made with, so the lines on screen are made again at the new width.
local function layoutScreen()
	touchSensor.x = screen.centerX
	touchSensor.y = screen.centerY
	touchSensor.width = screen.width
	touchSensor.height = screen.height

	local textBoxHeight = storySettings.textBox.height
	textBox.x = screen.centerX
	textBox.y = screen.maxY - textBoxHeight * 0.5
	textBox.width = screen.width

	local lines = {}
	for i = 1, #texts do
		lines[i] = texts[i].line
	end
	clearText()
	for i = 1, #lines do
		showLine( lines[i] )
	end

	if background then
		fitBackground()
	end

	-- Running animations end at once, at the positions on the new screen.
	finishAnimations()

	layoutMoney()
	inventoryPanel.resize()

	if activeMinigame then
		activeMinigame:resize()
	end
end

-- A fullscreen toggle in the options changes the visible area while the scene stays alive. screen.lua also
-- listens for resize, and the two listeners can run in either order, so screen.update() refreshes it first.
local function onResize()
	screen.update()
	layoutScreen()
end

-- The visual novel has no keyboard movement, so the movement callback is empty.
local function onMovement() end

local function closePauseMenu()
	if pauseMenu then
		pauseMenu:destroy()
		pauseMenu = nil
	end
end

-- The inventory opens only while the story waits for the player, never during a minigame round or the pause menu.
local function openInventory()
	if isRunning and not pauseMenu and not activeMinigame then
		inventoryPanel.open( panelLayer, moneyString() )
	end
end

function onKeyAction( action, phase )
	-- While the inventory is open, the inventory key closes it, and so does the menu key instead of pausing.
	if inventoryPanel.isOpen() then
		if action == "menu" and phase == "down" then
			inventoryPanel.close()
		else
			inventoryPanel.handleKey( action, phase )
		end
		return
	end

	if phase ~= "down" then
		return
	end

	if action == "menu" then
		openPauseMenu()

	elseif action == "inventory" then
		openInventory()
	end
end

-- Show a core overlay above the pause menu, which stays disabled until the overlay closes.
local function showPauseOverlay( sceneName, params )
	pauseMenu:disable()

	params.onClose = function()
		if pauseMenu then
			pauseMenu:enable()
		end
	end

	composer.showOverlay( sceneName, {
		effect = "fade",
		time = 250,
		params = params,
	} )
end

function openPauseMenu()
	if pauseMenu or not isRunning then
		return
	end

	controls.stop()

	if activeMinigame then
		activeMinigame:pause()
	end

	local params = {
		onResume = function()
			closePauseMenu()
			controls.start( onMovement, onKeyAction )

			if activeMinigame then
				activeMinigame:resume()
			end
		end,

		onLoad = function()
			-- Loading routes through scenes.refresh, which rebuilds this scene from the saved state.
			showPauseOverlay( "scenes.load", { mode = "load", gameState = buildGameState(), isOverlay = true } )
		end,

		onOptions = function()
			showPauseOverlay( "scenes.options", {} )
		end,

		onQuit = function()
			closePauseMenu()
			composer.gotoScene( "scenes.menu", {
				effect = "fade",
				time = 500,
			} )
		end,
	}

	-- A save made during a minigame would load at the start of its passage, so the pause menu offers no Save then.
	if not activeMinigame then
		params.onSave = function( screenshotFile )
			showPauseOverlay( "scenes.load", { mode = "save", gameState = buildGameState(), screenshotFile = screenshotFile, isOverlay = true } )
		end
	end

	pauseMenu = pauseCreate.new( params )
	sceneGroup:insert( pauseMenu )
end

--------------------------------------------------------------------------------------
-- Scene functions

local scene = composer.newScene()

function scene:create( event )
	sceneGroup = self.view
	local sceneParams = event.params or {}
	local savedState = sceneParams.savedState

	-- The scene may be rebuilt after a load, so reset the per-run state.
	characters = {}
	leavingCharacters = {}
	texts = {}
	background = nil
	backgroundFile = nil
	pauseMenu = nil
	activeMinigame = nil
	isRunning = false

	-- Load the story. This (re)creates the weaver's global story table and
	-- starts the story from the beginning.
	weaver.initStory( {
		name = storyName,
		source = storySettings.storyFile,
	} )

	backgroundGroup = display.newGroup()
	sceneGroup:insert( backgroundGroup )

	characterGroup = display.newGroup()
	sceneGroup:insert( characterGroup )

	-- Full-screen invisible sensor for tap-to-advance, below the text, links, minigame, inventory and buttons.
	touchSensor = display.newRect( sceneGroup, screen.centerX, screen.centerY, screen.width, screen.height )
	touchSensor.isVisible = false
	touchSensor.isHitTestable = true
	touchSensor:addEventListener( "touch", sensorEvent )

	textGroup = display.newGroup()
	sceneGroup:insert( textGroup )

	local textBoxConfig = storySettings.textBox
	textBox = display.newRect( textGroup, screen.centerX, screen.maxY - textBoxConfig.height * 0.5, screen.width, textBoxConfig.height )
	textBox:setFillColor( unpack( textBoxConfig.color ) )

	minigameLayer = display.newGroup()
	sceneGroup:insert( minigameLayer )

	panelLayer = display.newGroup()
	sceneGroup:insert( panelLayer )

	-- The inventory button does what the inventory key does, so pressing it again closes the inventory.
	hudGroup = display.newGroup()
	sceneGroup:insert( hudGroup )

	inventoryButton.new( {
		parent = hudGroup,
		onPress = function()
			onKeyAction( "inventory", "down" )
		end,
	} )

	local moneyConfig = storySettings.money
	moneyPlate = display.newRoundedRect( hudGroup, 0, 0, 1, settings.inventoryButton.size, moneyConfig.plateCornerRadius )
	moneyPlate:setFillColor( unpack( moneyConfig.plateColor ) )

	moneyText = display.newText( {
		parent = hudGroup,
		text = "",
		font = settings.fonts.bold,
		fontSize = moneyConfig.fontSize,
	} )
	moneyText.anchorX = 0

	-- Restore a saved game with the picture that was on screen when its node was
	-- entered, or start a new one at the start node.
	-- The inventory lives outside the scene, so a new game empties what the previous game left in it.
	if savedState then
		inventory.restore( savedState.inventory )
		restoreSaveData( savedState.saveData )
		showBackground( savedState.backgroundFile )
		restoreCharacters( savedState.characters )
		getNode( savedState.currentNode )
	else
		inventory.reset()
		inventory.addStartingItems()
		getNode( storySettings.startPassage )
	end

	-- The Menu button does what the menu key does, so it closes an open inventory. The pause menu is
	-- drawn over the button and blocks touches, so the button cannot open a second pause menu.
	menuButton.new( {
		parent = sceneGroup,
		onPress = function()
			onKeyAction( "menu", "down" )
		end,
	} )
end

function scene:show( event )
	local phase = event.phase

	if phase == "will" then
		-- If coming from launchScreen scene, then start by removing it.
		if composer._previousScene == "scenes.launchScreen" then
			composer.removeScene( "scenes.launchScreen" )
		end

		Runtime:addEventListener( "resize", onResize )

	elseif phase == "did" then
		isRunning = true
		controls.start( onMovement, onKeyAction )

		-- Switch from the menu music to the story's own track. The menu plays
		-- its own track again when it is shown.
		music.play( storySettings.music )
	end
end

function scene:hide( event )
	local phase = event.phase

	if phase == "will" then
		isRunning = false
		closePauseMenu()

		if inventoryPanel.isOpen() then
			inventoryPanel.close()
		end

		controls.stop()
		removeMinigame()
		finishAnimations()
		transition.cancel( animationTag )

	elseif phase == "did" then
		Runtime:removeEventListener( "resize", onResize )
	end
end

function scene:destroy()
	node = nil
	background = nil
	backgroundFile = nil
	characters = {}
	leavingCharacters = {}
	texts = {}
	currentNode = nil
	nodeEntryData = nil
	nodeEntryBackgroundFile = nil
	nodeEntryCharacters = nil
	nodeEntryInventory = nil
	backgroundGroup = nil
	characterGroup = nil
	textGroup = nil
	minigameLayer = nil
	panelLayer = nil
	hudGroup = nil
	moneyPlate = nil
	moneyText = nil
	touchSensor = nil
	textBox = nil
	sceneGroup = nil
end

--------------------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene
