-- The platformer game scene: a Tiled area with the camera, doors, respawns, items, characters to
-- talk to, the inventory, the pause menu, saves and music.

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local composer = require( "composer" )

-- json reads a map file exported from Tiled into a Lua table.
local json = require( "json" )

-- physics moves the hero and gives the tiles their physics bodies.
local physics = require( "physics" )

-- ponytiled builds a ready display object from a Tiled map.
local ponytiled = require( "com.ponywolf.ponytiled" )

-- settings holds the game's settings, such as the start area and the music of each area.
local settings = require( "libs.settings" )

local screen = require( "classes.screen" )
local controls = require( "classes.controls" )
local camera = require( "classes.camera" )
local music = require( "classes.music" )

-- transitionOverlay is the black screen that hides an area change or a respawn.
local transitionOverlay = require( "classes.transitionOverlay" )

local pauseWidget = require( "widgets.pause" )
local menuButton = require( "widgets.menuButton" )

-- dialogue loads the story and draws the conversations on the screen.
local dialogue = require( "classes.dialogue" )

-- inventory keeps the items the player carries and the record of items already picked up.
local inventory = require( "classes.inventory" )

-- inventoryPanel draws the inventory grid and handles its keys.
local inventoryPanel = require( "widgets.inventoryPanel" )

-- hints shows the game's controls in the corner of the screen.
local hints = require( "widgets.hints" )

-- prompt draws the bubbles such as "Up / W: talk" over map objects.
local prompt = require( "widgets.prompt" )

-- libs.utils replaces table.copy with a version that also copies nested tables.
require( "libs.utils" )

local playerModule = require( "classes.player" )
local spikesModule = require( "classes.spikes" )
local trampolineModule = require( "classes.trampoline" )
local itemModule = require( "classes.item" )
local npcModule = require( "classes.npc" )

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local platformerSettings = settings.platformer

-- The scene's own group. The camera moves only the map, so the backdrop, the Menu button and the
-- pause menu stay in place on the screen.
local uiGroup

-- The group behind the map that holds the backdrop, and its layers, each with its group, parallax
-- and the width of one image copy.
local backdropGroup
local backdropLayers = {}

local map
local player

-- The map's size in content units, for the camera's bounds.
local mapPixelWidth
local mapPixelHeight

-- The door objects of the area. Pressing Up inside one goes through it.
local doors

-- The characters of the area, and the one the hero is talking to, if any.
local npcs
local talkingNpc

-- The prompt bubbles of the area's map objects.
local prompts

-- The area that is open, and the door or spawn the hero last arrived at. Spikes and falls put the
-- hero back there, and both go into the save.
local areaName
local spawnName

-- The hero is put back once it falls this far down, in map coordinates.
local fallLimitY

-- True while the screen fades for a door, a respawn or the scene's start. The controls are off then,
-- and the overlay blocks the Menu button, so the game cannot be paused in the middle of a fade.
local isFading = false

local pauseMenu
local sfxHurt

-- The keyboard functions are written further down, but resuming the game already needs them.
local onMovementEvent
local onKeyEvent

--------------------------------------------------------------------------------------
-- Functions

-- The story's own <<...>> commands, by name. Each function gets the command's arguments.
-- <<addItem, parcel>> puts the item with the id "parcel" from data/items.lua in the
-- inventory, and <<removeItem, parcel>> takes it away. Add a function here for a new command.
local storyCommands = {
	addItem = function( itemId )
		inventory.add( itemId )
	end,

	removeItem = function( itemId )
		inventory.remove( itemId )
	end,
}


-- The story gives its own <<...>> commands to the game as tables, such as { "addItem", "parcel" }.
-- Weaver's <<print>> arrives here too, and lines that no function handles are skipped.
local function onDialogueCommand( command )
	local storyCommand = storyCommands[command[1]]
	if storyCommand then
		storyCommand( unpack( command, 2 ) )
	end
end


-- True while a conversation or the inventory is open. The prompt bubbles hide then.
local function isWindowOpen()
	return dialogue.isOpen() or inventoryPanel.isOpen()
end


-- Show each prompt bubble while the hero is in its reach, and hide them all while a window is
-- open. A character in reach turns to face the hero.
local function updatePrompts()
	local isBlocked = isWindowOpen()

	for i = 1, #prompts do
		prompts[i]:update( player, isBlocked )
	end

	for i = 1, #npcs do
		if not talkingNpc and prompt.isInReach( npcs[i].object, player ) then
			npcs[i]:face( player.x )
		end
	end
end


-- The character in reach that Up talks to, if any. One the hero faces or overlaps sideways wins over
-- one behind the hero, and among those the one with the smallest sideways gap to the hero's body.
-- The hero's xScale is 1 while it faces right and -1 while it faces left.
local function findNpc()
	local bestNpc = nil
	local bestIsFaced = false
	local bestDistance = math.huge

	for i = 1, #npcs do
		local object = npcs[i].object

		if prompt.isInReach( object, player ) then
			local distance = prompt.getGapX( object, player )
			local isFaced = distance == 0 or ( object.x - player.x ) * player.xScale > 0

			if ( isFaced and not bestIsFaced ) or ( isFaced == bestIsFaced and distance < bestDistance ) then
				bestNpc = npcs[i]
				bestIsFaced = isFaced
				bestDistance = distance
			end
		end
	end

	return bestNpc
end


-- Stop the hero where it stands when a window opens. A jump key held then is let go, because its
-- release goes to the window.
local function stopHero()
	player:jump( false )
	player:move( 0, 0 )
end


-- The character lowers her arm when the conversation closes.
local function onDialogueClosed()
	if talkingNpc then
		talkingNpc:endTalk()
		talkingNpc = nil
	end

	updatePrompts()
end


local function talkTo( character )
	stopHero()
	character:face( player.x )
	character:startTalk()
	talkingNpc = character

	dialogue.open( character.node, uiGroup, onDialogueCommand, onDialogueClosed )
	updatePrompts()
end

-- Build the backdrop: each image is repeated sideways enough times to cover the screen while it
-- scrolls, and scaled up if the screen is taller than the image. A rebuild replaces the old one.
-- An area listed in noBackdrop gets none, so the screen around a small map stays black.
local function buildBackdrop()
	for i = backdropGroup.numChildren, 1, -1 do
		display.remove( backdropGroup[i] )
	end

	backdropLayers = {}

	if platformerSettings.noBackdrop[areaName] then
		return
	end

	local layers = platformerSettings.backdrop
	for i = 1, #layers do
		local layer = layers[i]
		local scale = math.max( 1, screen.height / layer.height )
		local copyWidth = layer.width * scale
		local group = display.newGroup()
		backdropGroup:insert( group )

		for copy = 1, math.ceil( screen.width / copyWidth ) + 1 do
			local image = display.newImageRect( group, layer.filename, copyWidth, layer.height * scale )
			image.anchorX = 0
			image.x = ( copy - 1 ) * copyWidth
			image.y = screen.centerY
		end

		backdropLayers[i] = { group = group, parallax = layer.parallax, width = copyWidth }
	end
end


-- Scroll the backdrop sideways against the camera. A layer wraps around after one image width,
-- so it never runs out. It stays fixed to the screen vertically.
local function updateBackdrop()
	local cameraX = camera.getPosition().x

	for i = 1, #backdropLayers do
		local layer = backdropLayers[i]
		local offset = ( cameraX * layer.parallax ) % layer.width
		layer.group.x = math.floor( screen.minX - offset + 0.5 )
	end
end


-- A door's targetSpawn and the start spawn name an object on the area's objects layer.
local function findSpawn( name )
	return map:findObject( name ) or error( "no object named \"" .. tostring( name ) .. "\" in area \"" .. areaName .. "\"" )
end


-- Keep the camera's centre far enough from the map's edges that nothing past them shows. A map no
-- larger than the screen on an axis is centred on that axis.
local function setCameraBounds()
	local halfScreenWidth = screen.width * 0.5
	local halfScreenHeight = screen.height * 0.5

	local bounds = {
		xMin = halfScreenWidth,
		xMax = mapPixelWidth - halfScreenWidth,
		yMin = halfScreenHeight,
		yMax = mapPixelHeight - halfScreenHeight,
	}

	if bounds.xMin > bounds.xMax then
		bounds.xMin = mapPixelWidth * 0.5
		bounds.xMax = bounds.xMin
	end

	if bounds.yMin > bounds.yMax then
		bounds.yMin = mapPixelHeight * 0.5
		bounds.yMax = bounds.yMin
	end

	camera.setBounds( bounds )
end


-- The state that goes into a save slot, as plain data for JSON: the area, the hero's spawn and
-- position, the inventory, the record of picked up items, and the story. The state holds copies,
-- so the game going on does not change a state that is being saved.
local function buildGameState()
	return {
		area = areaName,
		spawn = spawnName,
		playerX = player.x,
		playerY = player.y,
		inventory = table.copy( inventory.slots ),
		collected = table.copy( inventory.getCollected() ),
		story = dialogue.getState(),
	}
end


-- screen.lua also listens for resize in no fixed order, so refresh the screen sizes before reading them.
local function onResize()
	screen.update()
	buildBackdrop()
	setCameraBounds()
	camera.snapToTarget()
	updateBackdrop()
	hints.resize()
	dialogue.resize()
	inventoryPanel.resize()
end


local function startPlaying()
	isFading = false
	controls.start( onMovementEvent, onKeyEvent )
end


-- Freeze the game world while the pause menu or the inventory is open. Every timer and transition
-- that runs when the world freezes is paused; the ones a menu or scene change starts afterwards keep
-- running. The camera stays where it is.
local function freezeWorld()
	physics.pause()
	camera.pause()
	player:pause()

	for i = 1, #npcs do
		npcs[i]:pauseAnimation()
	end

	transition.pauseAll()
	timer.pauseAll()
end


-- Let the game world run again. The camera follows the hero again from where it stopped, and the
-- hero's animation starts again on the next frame, when the hero moves.
local function unfreezeWorld()
	for i = 1, #npcs do
		npcs[i]:resumeAnimation()
	end

	physics.start()
	transition.resumeAll()
	timer.resumeAll()
	camera.resume()
end


-- Freeze the game world and stop listening to the keys while the pause menu is open.
local function pauseGame()
	controls.stop()
	freezeWorld()
end


-- The player may have changed keys in the options while the game was paused, so the hints and the
-- prompts are drawn again with the current keys.
local function resumeGame()
	hints.refresh()

	for i = 1, #prompts do
		prompts[i]:refresh()
	end

	unfreezeWorld()
	controls.start( onMovementEvent, onKeyEvent )
end


-- The inventory has closed: the game world runs again and the prompt bubbles come back.
local function onInventoryClosed()
	unfreezeWorld()
	updatePrompts()
end


-- Cancel the timers and transitions tagged "game"; a new one is either tagged so or cancelled in its object's finalize.
local function cancelGameTimers()
	-- Resume everything first: the engine keeps a cancelled paused timer in its list of paused
	-- timers for good, and nothing may stay paused when the scene is left.
	timer.resumeAll()
	transition.resumeAll()
	timer.cancel( "game" )
	transition.cancel( "game" )
end


local function closePauseMenu()
	if pauseMenu then
		pauseMenu:destroy()
		pauseMenu = nil
	end
end


-- Show the save, load or options screen on top of the pause menu. The pause menu stays
-- visible behind it, and its buttons work again once the screen closes.
local function showPauseOverlay( sceneName, params )
	pauseMenu:disable()

	params.onClose = function()
		if pauseMenu then
			pauseMenu:enable()
		end
	end

	composer.showOverlay( sceneName, { effect = "fade", time = 250, params = params } )
end


local function openPauseMenu()
	pauseGame()

	pauseMenu = pauseWidget.new( {
		onResume = function()
			closePauseMenu()
			resumeGame()
		end,

		onSave = function( screenshotFile )
			showPauseOverlay( "scenes.load", {
				mode = "save",
				gameState = buildGameState(),
				screenshotFile = screenshotFile,
				isOverlay = true,
			} )
		end,

		onLoad = function()
			showPauseOverlay( "scenes.load", {
				mode = "load",
				gameState = buildGameState(),
				isOverlay = true,
			} )
		end,

		onOptions = function()
			showPauseOverlay( "scenes.options", {} )
		end,

		-- The game world stays paused while the screen fades to the menu.
		onQuit = function()
			closePauseMenu()
			composer.gotoScene( "scenes.menu", { effect = "fade", time = 500 } )
		end,
	} )

	uiGroup:insert( pauseMenu )
end


-- Fade to black, then build the door's target area through the refresh scene, so it is made from
-- scratch. The new scene fades the overlay away.
local function enterDoor( door )
	isFading = true
	controls.stop()
	player:freeze()

	transitionOverlay.show( {
		onMidpoint = function()
			composer.gotoScene( "scenes.refresh", { params = { area = door.targetMap, spawn = door.targetSpawn } } )
		end,
	} )
end


-- Fade to black, put the hero at the last door or spawn, and fade back in.
local function respawn()
	isFading = true
	controls.stop()
	player:freeze()
	audio.play( sfxHurt )

	transitionOverlay.show( {
		onMidpoint = function()
			local spawn = findSpawn( spawnName )
			player:respawn( spawn.x, spawn.y )
			camera.snapToTarget()
			transitionOverlay.dismiss( startPlaying )
		end,
	} )
end


-- The door the hero stands in: the hero's centre is inside the door's rectangle.
local function findDoor()
	for i = 1, #doors do
		local door = doors[i]

		if math.abs( player.x - door.x ) <= door.width * 0.5 and math.abs( player.y - door.y ) <= door.height * 0.5 then
			return door
		end
	end
end


local function onCollision( self, event )
	local other = event.other
	local id = other.id
	local hasBegun = event.phase == "began"

	if id == "platform" then
		self:touchPlatform( other, hasBegun, event.selfElement )

	elseif id == "rope" then
		self:touchRope( hasBegun )

	elseif id == "trampoline" then
		self:touchTrampoline( other, hasBegun, event.selfElement )

	elseif id == "spikes" and hasBegun and not isFading then
		respawn()

	elseif id == "item" and hasBegun then
		other:take()
	end
end


-- controls calls this on every frame with the direction the player is pressing.
function onMovementEvent( directionX, directionY )
	-- While the inventory is open, the game world is frozen. Moving the hero, even to stand still,
	-- would start its paused animation again.
	if inventoryPanel.isOpen() then
		return
	end

	-- The hero stands still while a conversation is open.
	if dialogue.isOpen() then
		player:move( 0, 0 )
	else
		player:move( directionX, directionY )
	end

	updatePrompts()

	if player.y > fallLimitY then
		respawn()
	end
end


-- controls calls this when the player presses or releases one of the game's keys.
function onKeyEvent( action, phase )
	-- While a conversation is open, the keys go to the dialogue. Jump advances a line and confirms
	-- a choice, and Up and Down move between the choices.
	if dialogue.isOpen() then
		dialogue.handleKey( action == "jump" and "interact" or action, phase )
		return
	end

	-- While the inventory is open, the keys go to the inventory, Jump picks up and puts down an
	-- item, and the menu key closes the inventory. Closing it lets the game world run again.
	if inventoryPanel.isOpen() then
		if action == "menu" and phase == "down" then
			inventoryPanel.close()
		else
			inventoryPanel.handleKey( action == "jump" and "interact" or action, phase )
		end
		return
	end

	if action == "jump" then
		player:jump( phase == "down" )
		return
	end

	if phase ~= "down" then
		return
	end

	if action == "menu" then
		openPauseMenu()

	-- The game world is frozen while the inventory is open, and it runs again once the inventory
	-- closes. The keys keep working, so a direction key still held then moves the hero at once.
	elseif action == "inventory" then
		stopHero()
		inventoryPanel.open( uiGroup, nil, onInventoryClosed )
		updatePrompts()
		freezeWorld()

	-- A character in reach wins over a door.
	elseif action == "up" then
		local character = findNpc()
		local door = findDoor()

		if character then
			talkTo( character )

		elseif door then
			enterDoor( door )
		end
	end
end

--------------------------------------------------------------------------------------
-- Scene functions

local scene = composer.newScene()

function scene:create( event )
	local sceneGroup = self.view
	local sceneParams = event.params or {}

	uiGroup = sceneGroup

	-- There are three ways into this scene. The menu's Play button passes nothing and starts at the
	-- start spawn. A door passes the target area and spawn. A save slot passes the saved state.
	local savedState = sceneParams.savedState

	if savedState then
		-- Bring back the inventory, the record of picked up items and the story before the map is
		-- built, so that items already picked up do not appear on the map again.
		inventory.restore( savedState.inventory, savedState.collected )
		dialogue.setState( savedState.story )
		areaName = savedState.area
		spawnName = savedState.spawn

	elseif sceneParams.area then
		areaName = sceneParams.area
		spawnName = sceneParams.spawn

	else
		-- A new game empties everything the previous game left behind, starts the story from the
		-- beginning and gives the player the starting items.
		inventory.reset()
		dialogue.init()
		inventory.addStartingItems()
		areaName = platformerSettings.startArea
		spawnName = platformerSettings.startSpawn
	end

	isFading = true
	sfxHurt = audio.loadSound( "assets/audio/template/sfx/hurt.wav" )

	-- Start physics before building the map, because PonyTiled creates the bodies of the collision objects
	-- and the rope and trampoline tiles as soon as the map is built.
	physics.start()
	physics.setGravity( 0, platformerSettings.gravity )

	backdropGroup = display.newGroup()
	sceneGroup:insert( backdropGroup )
	buildBackdrop()

	-- The second argument tells ponytiled which folder the map's image paths start from.
	local mapData = json.decodeFile( system.pathForFile( "assets/maps/" .. areaName .. ".json", system.ResourceDirectory ) )
	map = ponytiled.new( mapData, "assets/maps" )
	sceneGroup:insert( map )

	mapPixelWidth = mapData.width * mapData.tilewidth
	mapPixelHeight = mapData.height * mapData.tileheight
	fallLimitY = mapPixelHeight + platformerSettings.fallMargin

	local spikeTiles = map:getAllTiles( "id", "spikes" )
	for i = 1, #spikeTiles do
		spikesModule.new( spikeTiles[i] )
	end

	local trampolineTiles = map:getAllTiles( "id", "trampoline" )
	for i = 1, #trampolineTiles do
		trampolineModule.new( trampolineTiles[i] )
	end

	doors = map:listTypes( "door" )

	-- The items and the characters go on the level layer before the hero, so the hero is drawn in
	-- front of them. The inventory needs the area's name to know which items were picked up here.
	local levelLayer = map:findLayer( "level" )
	inventory.setMap( areaName )

	local itemObjects = map:listTypes( "item" )
	for i = 1, #itemObjects do
		itemModule.new( levelLayer, itemObjects[i] )
	end

	npcs = {}
	local npcObjects = map:listTypes( "npc" )
	for i = 1, #npcObjects do
		npcs[i] = npcModule.new( levelLayer, npcObjects[i] )
	end

	-- The hero goes on the level layer, so the background tiles are behind it and the foreground
	-- tiles in front of it.
	local spawn = findSpawn( spawnName )
	player = playerModule.new( levelLayer, spawn.x, spawn.y )

	if savedState then
		player.x, player.y = savedState.playerX, savedState.playerY
	end

	player.collision = onCollision
	player:addEventListener( "collision" )

	-- The prompt bubbles go in their own group on top of the map, so they move with the map and
	-- are drawn in front of everything on it. Every object on the objects layer with a prompt
	-- property gets one.
	local promptGroup = display.newGroup()
	map:insert( promptGroup )
	prompts = {}

	local objectsLayer = map:findLayer( "objects" )
	for i = 1, objectsLayer.numChildren do
		local object = objectsLayer[i]
		if object.prompt then
			prompts[#prompts+1] = prompt.new( promptGroup, object )
		end
	end

	updatePrompts()

	-- The camera follows the hero by moving the whole map, so the map is its only layer.
	camera.init( { { group = map, delta = 1 } } )
	setCameraBounds()
	camera.setTarget( player, platformerSettings.camera )
	camera.snapToTarget()
	updateBackdrop()

	-- The hints are in the scene's group, so they stay in place and do not move with the camera.
	hints.create( sceneGroup )

	-- The Menu button does what the menu key does. It does nothing while the scene fades in. The
	-- pause menu and the inventory's dim are drawn over it and take its touches, so it never opens
	-- a second pause menu, and only the menu key closes an open inventory.
	menuButton.new( {
		parent = sceneGroup,
		onPress = function()
			if not isFading then
				onKeyEvent( "menu", "down" )
			end
		end,
	} )
end


function scene:show( event )
	local phase = event.phase

	if phase == "will" then
		-- Coming straight from the launch screen, remove it first.
		if composer._previousScene == "scenes.launchScreen" then
			composer.removeScene( "scenes.launchScreen" )
		end

		Runtime:addEventListener( "enterFrame", updateBackdrop )
		Runtime:addEventListener( "resize", onResize )

	elseif phase == "did" then
		camera.start()

		-- Areas that share a music file keep the music playing without a break between them.
		music.play( platformerSettings.music[areaName] )

		-- The controls start once the black screen of an area change has faded away. Without one,
		-- they start at once.
		transitionOverlay.dismiss( startPlaying )
	end
end


function scene:hide( event )
	local phase = event.phase

	if phase == "will" then
		-- Close any open window, so nothing is left on the screen.
		closePauseMenu()

		-- The scene is being left, so the dialogue closes without running its close handler.
		if dialogue.isOpen() then
			dialogue.close( true )
		end

		talkingNpc = nil

		-- The inventory closes without letting the game world run again.
		if inventoryPanel.isOpen() then
			inventoryPanel.close( true )
		end

		controls.stop()
		camera.stop()
		physics.pause()
		cancelGameTimers()

	elseif phase == "did" then
		Runtime:removeEventListener( "enterFrame", updateBackdrop )
		Runtime:removeEventListener( "resize", onResize )
	end
end


function scene:destroy()
	audio.dispose( sfxHurt )
	sfxHurt = nil

	-- The hero, the doors, the characters and the prompts are inside the map, so the scene's
	-- removal took them with it.
	backdropGroup = nil
	backdropLayers = {}
	map = nil
	player = nil
	doors = nil
	npcs = nil
	talkingNpc = nil
	prompts = nil
	pauseMenu = nil
	uiGroup = nil
end

--------------------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene
