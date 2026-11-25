# transitionOverlay

`classes/transitionOverlay.lua` fades the screen to black, runs your function while the screen is black, and fades back in when you tell it to. The overlay sits on the stage outside every scene, so it stays on the screen while Composer changes the scene behind it. General information about the project is in the [README](../../game/README.md).

The examples bind the module like this:

```lua
local transitionOverlay = require( "classes.transitionOverlay" )
```

## Contents

- [Limitations & Gotchas](#limitations--gotchas)
	- [The screen stays black until dismiss](#the-screen-stays-black-until-dismiss)
	- [One overlay at a time](#one-overlay-at-a-time)
	- [Touches are blocked, keys are not](#touches-are-blocked-keys-are-not)
- [Functions/API](#functionsapi)
	- [Fading](#fading)
		- [show](#show)
		- [dismiss](#dismiss)
		- [isActive](#isactive)
- [Examples](#examples)
	- [Moving to the next level](#moving-to-the-next-level)

## Limitations & Gotchas

### The screen stays black until dismiss

After the fade to black, the overlay waits. The scene you go to must call [`dismiss`](#dismiss), usually in its `show` "did" phase, or the game stays black. Calling `dismiss` when no overlay is showing is harmless, so a scene can always call it.

---

### One overlay at a time

A [`show`](#show) call while the overlay fades to black or holds at black does nothing, and its `onMidpoint` function never runs. A `show` call while the overlay fades away after [`dismiss`](#dismiss) stops that fade, fades the same overlay back to black and then runs the new `onMidpoint` once. The `onComplete` function of the stopped `dismiss` never runs.

---

### Touches are blocked, keys are not

The overlay swallows every touch, so nothing below it can be pressed. Key presses still reach the game, so stop the controls before you call `show` if the player must not move during the fade.

## Functions/API

### Fading

#### show

Fades the screen to black and then calls `params.onMidpoint`, where you change the scene.

```lua
transitionOverlay.show( params )
```

| Param | Meaning |
| --- | --- |
| `onMidpoint` | A function called once the screen is black. |
| `fadeInTime` | Milliseconds the fade to black takes. Defaults to `settings.transition.fadeInTime`. |
| `fadeOutTime` | Milliseconds the fade back in takes when [`dismiss`](#dismiss) is called. Defaults to `settings.transition.fadeOutTime`. |
| `text` | Text shown in the middle of the black screen, such as a level name. |
| `font` | The font of `text`. Defaults to `native.systemFontBold`. |

---

#### dismiss

Fades the overlay away and then calls `onComplete`. If the screen is still fading to black, the fade back in starts once it is black. With no overlay showing, `onComplete` is called at once.

```lua
transitionOverlay.dismiss( onComplete )
```

---

#### isActive

Returns `true` while an overlay is on the screen.

```lua
transitionOverlay.isActive()
```

## Examples

### Moving to the next level

A complete `scenes/game.lua`. Touching the screen fades to black with the next level's name, and the scene enters itself again through `scenes.refresh` with the new level number. The new scene fades the overlay away.

```lua
local composer = require( "composer" )
local screen = require( "classes.screen" )
local transitionOverlay = require( "classes.transitionOverlay" )

local scene = composer.newScene()

function scene:create( event )
	local sceneGroup = self.view
	local sceneParams = event.params or {}
	local level = sceneParams.level or 1

	local background = display.newRect( sceneGroup, screen.centerX, screen.centerY, screen.width, screen.height )
	background:setFillColor( 0.1, 0.3, 0.5 )

	display.newText( sceneGroup, "Level " .. level .. "\nTouch to continue", screen.centerX, screen.centerY, native.systemFontBold, 40 )

	background:addEventListener( "touch", function( touchEvent )
		if touchEvent.phase == "ended" then
			transitionOverlay.show( {
				text = "Level " .. (level + 1),
				onMidpoint = function()
					composer.gotoScene( "scenes.refresh", { params = { level = level + 1 } } )
				end,
			} )
		end
		return true
	end )
end

function scene:show( event )
	if event.phase == "did" then
		transitionOverlay.dismiss()
	end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

return scene
```
