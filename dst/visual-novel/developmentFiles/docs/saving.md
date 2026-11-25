# Saving

Two modules save the game. `classes/loadsave.lua` writes a Lua table to a JSON file and reads it back. `classes/saveManager.lua` uses it to keep four save slots in the `saves/` folder, each with a screenshot of the game. The slot screen `scenes/load.lua` shows the slots and is used for both saving and loading. General information about the project is in the [README](../../game/README.md).

The examples bind the modules like this:

```lua
local loadsave = require( "classes.loadsave" )
local saveManager = require( "classes.saveManager" )
```

## Contents

- [Limitations & Gotchas](#limitations--gotchas)
	- [Loaded saves always open scenes.game](#loaded-saves-always-open-scenesgame)
	- [The pause menu takes the screenshot](#the-pause-menu-takes-the-screenshot)
	- [A game state holds only plain data](#a-game-state-holds-only-plain-data)
	- [Files and folders](#files-and-folders)
- [Properties](#properties)
	- [userdata](#userdata)
- [Functions/API](#functionsapi)
	- [Reading and writing files](#reading-and-writing-files)
		- [save](#save)
		- [load](#load)
		- [delete](#delete)
	- [Save slots](#save-slots)
		- [captureScreenshot](#capturescreenshot)
		- [saveToSlot](#savetoslot)
		- [loadFromSlot](#loadfromslot)
		- [removeSlot](#removeslot)
		- [removeTempScreenshot](#removetempscreenshot)
		- [getAllSlotInfo](#getallslotinfo)
		- [formatTimestamp](#formattimestamp)
		- [getMaxSlots](#getmaxslots)
	- [Slot screen](#slot-screen)
		- [Slot screen parameters](#slot-screen-parameters)
- [Examples](#examples)
	- [Saving and loading from the pause menu](#saving-and-loading-from-the-pause-menu)
	- [Keeping a high score](#keeping-a-high-score)

## Limitations & Gotchas

### Loaded saves always open scenes.game

When the player loads a slot, the slot screen goes to `scenes.game` and passes the saved state as `event.params.savedState`. It does not use `settings.menu.playScene`, so if your game starts in a scene with another name, that scene never receives a loaded save. Read `savedState` in `scenes/game.lua`.

---

### The pause menu takes the screenshot

When the player presses Save in the core pause menu (`widgets/pause.lua`), the menu hides itself, calls [`captureScreenshot`](#capturescreenshot), shows itself again, and passes the screenshot's path to your `onSave` callback. Nothing is captured when the pause menu opens, so it appears at once. If you save from anywhere else, call `captureScreenshot` yourself while nothing covers the game, because it captures whatever is on the screen at that moment.

---

### A game state holds only plain data

The game state is written to a JSON file, so it may hold only numbers, strings, booleans and tables of those. Display objects, functions and other Solar2D objects cannot be saved: store the values you need to rebuild them, such as a position or a map name.

---

### Files and folders

Every file is read from and written to `system.DocumentsDirectory`. A filename may include a folder (`saves/save_1.json`), but the folder must already exist. The game creates the `saves/` folder at launch.

- [`save`](#save) prints an error and returns `false` when it cannot open the file.
- [`load`](#load) returns `nil` both for a file that does not exist yet and for a file it cannot read, so give a default with `or`.

## Properties

### userdata

The player's settings from `userdata.json`: `audio.volume` (`master`, `music`, `sfx`), `controls` and `fullscreen`, plus any keys your settings add to `defaultUserdata`. The game fills it in at launch. After you change it, save it so the change is kept.

```lua
loadsave.userdata.fullscreen = true
loadsave.save( loadsave.userdata, "userdata.json" )
```

## Functions/API

### Reading and writing files

#### save

Writes `data` to `filename` as JSON. Returns `true` on success and `false` when the file cannot be opened.

```lua
loadsave.save( data, filename )
```

---

#### load

Reads `filename` and returns its contents as a table, or `nil` when the file is missing or cannot be read.

```lua
loadsave.load( filename )
```

---

#### delete

Deletes `filename`.

```lua
loadsave.delete( filename )
```

---

### Save slots

#### captureScreenshot

Captures the screen to a temporary file and returns that file's path, or `nil` if the capture failed. Pass the path to the slot screen as `screenshotFile`. The core pause menu calls this for you when the player presses Save.

```lua
saveManager.captureScreenshot()
```

---

#### saveToSlot

Saves `gameState` to slot `slotIndex` (1 to 4) with the time of saving, and copies the temporary screenshot to the slot when `screenshotFile` is given. Returns `true` on success. The slot screen calls this for you.

```lua
saveManager.saveToSlot( slotIndex, gameState, screenshotFile )
```

---

#### loadFromSlot

Returns the slot's save data, or `false` when the slot is empty. A slot counts as empty when its file is missing, when the file cannot be read, and when it was saved with another `SAVE_VERSION`. The save data is a table with these keys:

- `gameState` is the table the game saved.
- `timestamp` is the time of saving, from `os.time()`.
- `screenshotFile` is the path of the slot's screenshot.
- `version` is the `SAVE_VERSION` the slot was saved with.

`SAVE_VERSION` at the top of `classes/saveManager.lua` is the version of the saved game state. Raise it whenever the shape of your game state changes, such as a renamed or removed key: slots saved with the old number then read as empty, so an old save never reaches code that expects the new shape.

```lua
saveManager.loadFromSlot( slotIndex )
```

---

#### removeSlot

Deletes the slot's save file and screenshot.

```lua
saveManager.removeSlot( slotIndex )
```

---

#### removeTempScreenshot

Deletes the temporary screenshot that [`captureScreenshot`](#capturescreenshot) wrote.

```lua
saveManager.removeTempScreenshot()
```

---

#### getAllSlotInfo

Returns a table with one entry per slot, each the slot's save data or `false` for an empty slot, the same as [`loadFromSlot`](#loadfromslot) returns. The slot screen shows every empty slot as `Empty` in load mode and as a free slot in save mode, where saving to it writes over an old-version file without asking.

```lua
saveManager.getAllSlotInfo()
```

---

#### formatTimestamp

Turns a save's `timestamp` into text such as `2026-03-14 18:05`.

```lua
saveManager.formatTimestamp( timestamp )
```

---

#### getMaxSlots

Returns the number of save slots, 4.

```lua
saveManager.getMaxSlots()
```

---

### Slot screen

#### Slot screen parameters

The game opens the slot screen with `composer.showOverlay` on top of the pause menu. The menu's Load button opens it as a normal scene in load mode. These are the params it reads:

| Param | Meaning |
| --- | --- |
| `mode` | `"save"` or `"load"`. Defaults to `"load"`. |
| `gameState` | The table that a save writes to the slot. |
| `screenshotFile` | The path from [`captureScreenshot`](#capturescreenshot), saved with the slot. |
| `isOverlay` | `true` when the screen is shown with `composer.showOverlay`. Back and a finished save then close the overlay. |
| `fromGame` | When the screen is not an overlay, Back returns to `scenes.game` with `gameState` as `savedState`. Without `gameState`, Back goes to the menu. |
| `onClose` | A function the screen calls after it closes. |

```lua
composer.showOverlay( "scenes.load", { params = { mode = "save", gameState = gameState, screenshotFile = screenshotFile, isOverlay = true } } )
```

## Examples

### Saving and loading from the pause menu

A complete `scenes/game.lua`. Touching the screen raises the score, and the Pause text opens the core pause menu with Save and Load. A loaded slot re-enters the scene with the saved score.

```lua
local composer = require( "composer" )
local screen = require( "classes.screen" )
local pauseWidget = require( "widgets.pause" )

local scene = composer.newScene()

local score = 0
local scoreText
local pauseMenu

local function buildGameState()
	return {
		score = score,
	}
end

local function closePauseMenu()
	if pauseMenu then
		pauseMenu:destroy()
		pauseMenu = nil
	end
end

-- The pause menu stays behind the slot screen and comes back to life when the slot screen closes.
local function showSlotScreen( mode, screenshotFile )
	pauseMenu:disable()

	composer.showOverlay( "scenes.load", {
		effect = "fade",
		time = 250,
		params = {
			mode = mode,
			gameState = buildGameState(),
			screenshotFile = screenshotFile,
			isOverlay = true,
			onClose = function()
				if pauseMenu then
					pauseMenu:enable()
				end
			end,
		},
	} )
end

local function openPauseMenu()
	pauseMenu = pauseWidget.new( {
		onResume = closePauseMenu,
		-- The pause menu passes the screenshot it took without itself on the screen.
		onSave = function( screenshotFile )
			showSlotScreen( "save", screenshotFile )
		end,
		onLoad = function()
			showSlotScreen( "load" )
		end,
		onQuit = function()
			closePauseMenu()
			composer.gotoScene( "scenes.menu", { effect = "fade", time = 500 } )
		end,
	} )

	scene.view:insert( pauseMenu )
end

function scene:create( event )
	local sceneGroup = self.view
	local sceneParams = event.params or {}

	-- A loaded slot passes savedState. The Play button passes nothing, so the game starts over.
	local savedState = sceneParams.savedState
	if savedState then
		score = savedState.score
	else
		score = 0
	end

	local background = display.newRect( sceneGroup, screen.centerX, screen.centerY, screen.width, screen.height )
	background:setFillColor( 0.2 )
	background:addEventListener( "touch", function( touchEvent )
		if touchEvent.phase == "ended" then
			score = score + 1
			scoreText.text = "Score: " .. score
		end
		return true
	end )

	scoreText = display.newText( sceneGroup, "Score: " .. score, screen.centerX, screen.centerY, native.systemFontBold, 48 )

	local pauseButton = display.newText( sceneGroup, "Pause", screen.minX + 80, screen.minY + 40, native.systemFontBold, 32 )
	pauseButton:addEventListener( "touch", function( touchEvent )
		if touchEvent.phase == "ended" and not pauseMenu then
			openPauseMenu()
		end
		return true
	end )
end

function scene:hide( event )
	if event.phase == "will" then
		-- The pause menu listens for the keys bound to the menu action, so it must go before the scene does.
		closePauseMenu()
	end
end

function scene:destroy( event )
	scoreText = nil
end

scene:addEventListener( "create", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene
```

### Keeping a high score

`loadsave` works on its own for any data that is not a save slot.

```lua
local loadsave = require( "classes.loadsave" )

local highScore = loadsave.load( "highScore.json" ) or { best = 0 }

local function submitScore( score )
	if score > highScore.best then
		highScore.best = score
		loadsave.save( highScore, "highScore.json" )
	end
end

submitScore( 120 )
print( "Best score: " .. highScore.best )
```
