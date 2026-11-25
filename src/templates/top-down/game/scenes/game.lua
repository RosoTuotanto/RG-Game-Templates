-- The top-down game scene. It builds a map made in the Tiled editor, moves the hero with the
-- keyboard, lets the player talk to characters and pick up items, and connects the game to the
-- pause menu, the save slots and the music.

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local composer = require( "composer" )

-- json reads a map file exported from Tiled into a Lua table.
local json = require( "json" )

-- physics gives the hero and the walls their physics bodies.
local physics = require( "physics" )

-- ponytiled builds a ready display object from a Tiled map.
local ponytiled = require( "com.ponywolf.ponytiled" )

-- settings holds the game's settings, such as the start map and the music of each map.
local settings = require( "libs.settings" )

-- screen helps place things on the screen, such as the edges and the centre.
local screen = require( "classes.screen" )

-- controls listens to the keyboard and gives the direction the hero moves in.
local controls = require( "classes.controls" )

-- camera follows the hero and scrolls the map on big maps.
local camera = require( "classes.camera" )

-- music plays the background music of each map.
local music = require( "classes.music" )

-- transitionOverlay is the black screen that hides the map change. The new map fades it away.
local transitionOverlay = require( "classes.transitionOverlay" )

-- dialogue loads the story and draws the conversations on the screen.
local dialogue = require( "classes.dialogue" )

-- inventory keeps the items the player carries and the record of items already picked up.
local inventory = require( "classes.inventory" )

-- inventoryPanel draws the inventory grid and handles its keys.
local inventoryPanel = require( "widgets.inventoryPanel" )

-- hints shows the game's controls in the corner of the screen.
local hints = require( "widgets.hints" )

-- pauseWidget builds the pause menu with its Resume, Save, Load, Options and Quit buttons.
local pauseWidget = require( "widgets.pause" )

-- menuButton builds the Menu button in the top right corner, which opens the pause menu.
local menuButton = require( "widgets.menuButton" )

-- exit and zone are the same modules that ponytiled runs for the map's "exit" and "zone"
-- objects. The game scene tells them how to show their messages on the screen.
local exit = require( "maps.extensions.exit" )
local zone = require( "maps.extensions.zone" )

-- libs.utils replaces table.copy with a version that also copies nested tables.
require( "libs.utils" )

--------------------------------------------------------------------------------------
-- Forward declarations & variables

-- The scene's own group. The camera moves only the map, so the dialogue, the inventory and
-- the pause menu are drawn in this group and stay in place on the screen.
local uiGroup

-- The map, the hero and the name of the map that is open. The save needs the map's name.
local map
local player
local mapName

-- The map's size in content units, which the camera's limits are worked out from.
local mapPixelWidth
local mapPixelHeight

-- The colour behind a map smaller than the screen, when the map has one in the settings.
local background

-- True when the game starts from the beginning. The intro line is then shown once the
-- scene is on the screen, and it tells the player where to go.
local isNewGame = false

-- The pause menu while it is open.
local pauseMenu

-- The sound that plays when the player talks to a character or picks up an item.
local interactSound

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


-- Fill the screen behind the map with the background colour, at the current screen size.
local function placeBackground()
	background.x, background.y = screen.centerX, screen.centerY
	background.width, background.height = screen.width, screen.height
end


-- Work out the camera's limits from the map's size and the screen's size, so the camera never
-- shows past the map's edges. The limits tell how close to an edge the camera's centre may go.
local function setCameraBounds()
	local halfScreenWidth = screen.width * 0.5
	local halfScreenHeight = screen.height * 0.5

	local boundsXMin = halfScreenWidth
	local boundsXMax = mapPixelWidth - halfScreenWidth
	local boundsYMin = halfScreenHeight
	local boundsYMax = mapPixelHeight - halfScreenHeight

	-- A map no larger than the screen on an axis, such as indoor1, is centred on that axis.
	if boundsXMin > boundsXMax then
		boundsXMin = mapPixelWidth * 0.5
		boundsXMax = boundsXMin
	end

	if boundsYMin > boundsYMax then
		boundsYMin = mapPixelHeight * 0.5
		boundsYMax = boundsYMin
	end

	camera.setBounds( { xMin = boundsXMin, yMin = boundsYMin, xMax = boundsXMax, yMax = boundsYMax } )
end


-- A window resize or a fullscreen toggle in the options changes the visible area while the scene
-- stays alive. screen.lua also listens for resize, and the two listeners can run in either order,
-- so screen.update() refreshes the screen sizes before they are read.
local function onResize()
	screen.update()

	if background then
		placeBackground()
	end

	setCameraBounds()
	camera.snapToTarget()
	hints.resize()
	dialogue.resize()
	inventoryPanel.resize()
end


-- Build the game's state for a save slot: the map, the hero's position and facing, the
-- inventory, the records of picked up items and fired zones, and the story. The save is
-- written as JSON, so the state holds only copies of plain data.
local function buildGameState()
	local facingX, facingY = player:getFacing()

	return {
		mapName = mapName,
		playerX = player.x,
		playerY = player.y,
		facing = { x = facingX, y = facingY },
		inventory = table.copy( inventory.slots ),
		collected = table.copy( inventory.getCollected() ),
		zones = table.copy( zone.getTriggered() ),
		story = dialogue.getState(),
	}
end


-- Freeze the game world: the hero stops, its animation and the physics pause, and the camera
-- stays where it is. The pause menu and the inventory both freeze the world while they are open.
local function freezeWorld()
	player:stop()
	player.sprite:pause()
	physics.pause()
	camera.pause()
end


-- Let the game world run again. The camera follows the hero again from where it stopped.
local function unfreezeWorld()
	physics.start()
	player.sprite:play()
	camera.resume()
end


-- Freeze the game world and stop listening to the keys while the pause menu is open.
local function pauseGame()
	controls.stop()
	freezeWorld()
end


-- Let the game world run again and listen to the keys. The player may have changed keys in the
-- options while the game was paused, so the hints are drawn again with the current keys.
local function resumeGame()
	hints.refresh()
	unfreezeWorld()
	controls.start( onMovementEvent, onKeyEvent )
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


-- How far a point is from the nearest point of a candidate's physics body, in content units, or 0
-- when the point is inside the body. The point is in content coordinates.
local function getDistanceToBody( candidate, pointX, pointY )
	-- A round body, such as a character's or an item's, is centred on the object's position, and
	-- the extension that adds it keeps its radius in bodyRadius.
	if candidate.bodyRadius then
		local centreX, centreY = candidate:localToContent( 0, 0 )
		local distanceX = pointX - centreX
		local distanceY = pointY - centreY
		return math.max( 0, math.sqrt( distanceX * distanceX + distanceY * distanceY ) - candidate.bodyRadius )
	end

	-- Any other body, such as a sign's, is a rectangle the size of the object's image. The nearest
	-- point of the rectangle is the point moved inside the rectangle's edges.
	local bounds = candidate.contentBounds
	local distanceX = pointX - math.min( math.max( pointX, bounds.xMin ), bounds.xMax )
	local distanceY = pointY - math.min( math.max( pointY, bounds.yMin ), bounds.yMax )
	return math.sqrt( distanceX * distanceX + distanceY * distanceY )
end


-- Find the object the interact key acts on. The key looks at a point interactReach in front of
-- the edge of the hero's body, the way the hero faces, and picks the character, sign or item
-- whose body is closest to that point, if it is within interactRadius. Returns nil otherwise.
local function findInteractTarget()
	-- The camera moves the map, and objects can sit on different layers, so all positions are
	-- compared in content coordinates. The hero's body is centred on the hero's position.
	local heroX, heroY = player:localToContent( 0, 0 )
	local facingX, facingY = player:getFacing()
	local pointDistance = settings.topDown.heroBodyRadius + settings.topDown.interactReach
	local pointX = heroX + facingX * pointDistance
	local pointY = heroY + facingY * pointDistance

	local target
	local targetDistance = math.huge

	-- The map's own object lists hold every character, sign and item on it. An item that has been
	-- picked up has been removed from the map, so it is not in the list.
	local candidates = map:listTypes( "npc", "sign", "item" )

	for i = 1, #candidates do
		local candidate = candidates[i]

		-- Visibility plays no part, so a hidden object can be a target. An object whose
		-- ignoreInteract is true, set in Tiled or in code, is never one.
		if not candidate.ignoreInteract then
			local distance = getDistanceToBody( candidate, pointX, pointY )

			if distance <= settings.topDown.interactRadius and distance < targetDistance then
				target = candidate
				targetDistance = distance
			end
		end
	end

	return target
end


-- Talk to, read or pick up the object in front of the hero.
local function interact()
	local target = findInteractTarget()

	if not target then
		return
	end

	if target.type == "npc" then
		-- Stop the hero and give feedback: the character hops and a sound plays, so the
		-- player both sees and hears that the talk started.
		player:stop()
		target:bounce()
		audio.play( interactSound )

		-- Background characters have no passage of their own, so they share one with random lines.
		dialogue.open( target.node or settings.story.npcPassage, uiGroup, onDialogueCommand )

	elseif target.type == "sign" then
		-- A sign is a plain map object with a node property: reading it opens that passage.
		player:stop()
		audio.play( interactSound )
		dialogue.open( target.node, uiGroup, onDialogueCommand )

	elseif target.type == "item" then
		-- The sound plays only when the item fits in the inventory. A full inventory leaves
		-- the item on the map, and the hero says so.
		if target:pickup() then
			audio.play( interactSound )
		else
			dialogue.showMonologue( settings.topDown.inventoryFullMessage, uiGroup )
		end
	end
end


-- controls calls this on every frame with the direction the player is pressing. The direction
-- is passed on to the hero, which does the actual moving.
function onMovementEvent( directionX, directionY )
	-- While the inventory is open, the game world is frozen, so nothing on the map moves.
	if inventoryPanel.isOpen() then
		return
	end

	-- The hero stands still while a conversation is open.
	if dialogue.isOpen() then
		player:stop()
		return
	end

	player:move( directionX, directionY )

	-- Sort the objects on the game layer so that an object lower on the screen is drawn in front
	-- of an object higher up. During a conversation the code never gets here, so a character's
	-- hop does not move it behind the hero.
	map:sortLayer( "game" )
end


-- controls calls this when the player presses or releases one of the game's keys.
function onKeyEvent( action, phase )
	-- While a conversation is open, every key goes to the dialogue.
	if dialogue.isOpen() then
		dialogue.handleKey( action, phase )
		return
	end

	-- While the inventory is open, every key goes to the inventory, and the menu key closes it.
	-- Closing the inventory lets the game world run again.
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

	-- The game world is frozen while the inventory is open, and it runs again once the inventory
	-- closes. The keys keep working, so a direction key still held then moves the hero at once.
	elseif action == "inventory" then
		inventoryPanel.open( uiGroup, nil, unfreezeWorld )
		freezeWorld()

	elseif action == "interact" then
		interact()
	end
end

--------------------------------------------------------------------------------------
-- Scene functions

local scene = composer.newScene()

function scene:create( event )
	local sceneGroup = self.view
	local sceneParams = event.params or {}

	uiGroup = sceneGroup

	-- There are three ways into this scene. The menu's Play button passes nothing and starts a
	-- new game. An exit passes the next map and the spawn point where the hero appears. A save
	-- slot passes the saved state.
	local savedState = sceneParams.savedState
	isNewGame = not savedState and not sceneParams.mapName

	if isNewGame then
		-- Empty everything the previous game left behind, then start the story from the beginning
		-- and give the player the starting items.
		inventory.reset()
		zone.reset()
		dialogue.init()
		inventory.addStartingItems()
		mapName = settings.topDown.startMap

	elseif savedState then
		-- Bring back the inventory, the records and the story before the map is built, so that
		-- items already picked up do not appear on the map again.
		inventory.restore( savedState.inventory, savedState.collected )
		zone.restore( savedState.zones )
		dialogue.setState( savedState.story )
		mapName = savedState.mapName

	else
		mapName = sceneParams.mapName
	end

	interactSound = audio.loadSound( "assets/audio/template/sfx/interact.wav" )

	-- Start physics before building the map, because the map's physics layer creates the
	-- walls' physics bodies as soon as the map is built. A top-down game has no gravity,
	-- so gravity is set to zero on both axes.
	physics.start()
	physics.setGravity( 0, 0 )

	-- A map narrower than the screen would leave black edges. A colour from the settings fills
	-- the screen behind such a map, so its edges blend into the terrain.
	local backgroundColor = settings.topDown.mapBackground[mapName]
	background = nil

	if backgroundColor then
		background = display.newRect( sceneGroup, 0, 0, 1, 1 )
		background:setFillColor( unpack( backgroundColor ) )
		placeBackground()
	end

	-- Read the map's JSON file into a Lua table and build a display object from it. The second
	-- argument tells ponytiled which folder the map's image files are in.
	local mapData = json.decodeFile( system.pathForFile( "maps/" .. mapName .. ".json", system.ResourceDirectory ) )
	map = ponytiled.new( mapData, "maps" )

	-- Hide the physics layer, which holds the invisible walls and exits. The map already marks
	-- the layer as hidden, but hiding it here too shows how to find a single layer and hide it.
	local physicsLayer = map:findLayer( "physics" )
	if physicsLayer then
		physicsLayer.isVisible = false
	end

	-- Tell ponytiled which folder its extensions are in.
	map.extensions = "maps.extensions."

	-- Tell the inventory and the zones which map is being built. The item extension needs it so
	-- that items already picked up stay away, and the zones record their firings under this map.
	inventory.setMap( mapName )
	zone.setMap( mapName )

	-- A zone's message and a locked exit's message are shown in the dialogue window as the
	-- hero's own line.
	function zone.onMessage( message )
		dialogue.showMonologue( message, uiGroup )
	end

	function exit.onLocked( message )
		dialogue.showMonologue( message, uiGroup )
	end

	-- Run the extensions: hero replaces the "hero" object with the player, npc builds a character
	-- from every "npc" object, exit turns the "exit" objects into map exits, item builds the items
	-- that can be picked up, and zone connects the message zones.
	map:extend( "hero", "npc", "exit", "item", "zone" )
	player = map:findObject( "hero" )

	-- Coming through an exit, the hero appears at the spawn point that the exit named. If the map
	-- has no spawn point with that name, the hero is left at 0,0 and a warning is printed, so a
	-- missing spawn point is noticed right away while making the game.
	if sceneParams.spawnName then
		local spawn = map:findObject( sceneParams.spawnName )
		if spawn then
			player.x, player.y = spawn.x, spawn.y
		else
			player.x, player.y = 0, 0
			print( "WARNING: spawn point \"" .. tostring( sceneParams.spawnName ) .. "\" was not found." )
		end
	end

	-- Coming from a save slot, the hero returns to the saved position and facing.
	if savedState then
		player.x, player.y = savedState.playerX, savedState.playerY
		player:setFacing( savedState.facing.x, savedState.facing.y )
	end

	-- Sort the objects right away, so they are drawn in the right order already while the scene fades in.
	map:sortLayer( "game" )
	sceneGroup:insert( map )

	-- The camera follows the hero by moving the whole map, so the map is given to it as a single
	-- layer (a delta of 1 moves with the camera).
	camera.init( { { group = map, delta = 1 } } )

	mapPixelWidth = mapData.width * mapData.tilewidth
	mapPixelHeight = mapData.height * mapData.tileheight
	setCameraBounds()

	-- Move the camera onto the hero right away, so the view does not jump when the game starts.
	camera.setTarget( player, { smoothing = 0.3 } )
	camera.snapToTarget()

	-- The hints are in the scene's group, so they stay in place and do not move with the camera.
	hints.create( sceneGroup )

	-- The Menu button does what the menu key does. The pause menu is drawn over the button and
	-- blocks touches, so the button cannot open a second pause menu.
	menuButton.new( {
		parent = sceneGroup,
		onPress = function()
			onKeyEvent( "menu", "down" )
		end,
	} )
end


function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if phase == "will" then
		-- Coming straight from the launch screen, remove it first.
		if composer._previousScene == "scenes.launchScreen" then
			composer.removeScene( "scenes.launchScreen" )
		end

		Runtime:addEventListener( "resize", onResize )

	elseif phase == "did" then
		-- Fade away the black screen of a map change. Without one, nothing happens.
		transitionOverlay.dismiss()

		controls.start( onMovementEvent, onKeyEvent )
		camera.start()

		-- Maps that share a music file keep the music playing without a break between them.
		music.play( settings.topDown.music[mapName] )

		if isNewGame then
			isNewGame = false
			dialogue.open( settings.story.introPassage, sceneGroup, onDialogueCommand )
		end
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

		-- The inventory closes without letting the game world run again.
		if inventoryPanel.isOpen() then
			inventoryPanel.close( true )
		end

		-- Stop listening to the keys, stop the camera and the hero, and stop the game world.
		controls.stop()
		camera.stop()
		player:stop()
		physics.pause()

	elseif phase == "did" then
		Runtime:removeEventListener( "resize", onResize )
	end
end


function scene:destroy()
	audio.dispose( interactSound )
	interactSound = nil

	-- The map's messages were drawn into this scene's group, which is now gone.
	zone.onMessage = nil
	exit.onLocked = nil

	-- The hero is inside the map, so the map's removal with the scene took the hero with it.
	map = nil
	player = nil
	background = nil
	pauseMenu = nil
	uiGroup = nil
end

--------------------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene
