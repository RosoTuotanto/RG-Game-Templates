# Music

`classes/music.lua` plays one looping background track at a time on audio channel 1, the channel the game reserves for music, and fades between tracks. The Music Volume slider in the options sets the music volume, and the module sets the channel to that volume multiplied by the fade in progress, so every fade in ends at the slider's value. The fade times are `settings.music.fadeOutTime` and `settings.music.fadeInTime` in `game/data/settingsCore.lua`. General information about the project is in the [README](../../game/README.md).

The examples bind the module like this:

```lua
local music = require( "classes.music" )
```

## Contents

- [Limitations & Gotchas](#limitations--gotchas)
	- [The menu plays its own track](#the-menu-plays-its-own-track)
	- [Stop the music only through this module](#stop-the-music-only-through-this-module)
	- [Fades keep running while the game is paused](#fades-keep-running-while-the-game-is-paused)
- [Functions/API](#functionsapi)
	- [Playing music](#playing-music)
		- [play](#play)
		- [stop](#stop)
		- [getCurrent](#getcurrent)
		- [updateVolume](#updatevolume)
- [Examples](#examples)
	- [A game scene with its own track](#a-game-scene-with-its-own-track)

## Limitations & Gotchas

### The menu plays its own track

The menu plays `settings.menu.music` every time it is shown, and the track keeps playing in the load, options and credits scenes. The Play button and loading a save slot call [`stop`](#stop) as the scene change starts, so the menu music fades out during the scene fade, and the game scene starts its own track in its `show` "did" phase. A track a game scene starts keeps playing from scene to scene until a scene plays another track or calls `stop`. When the player returns to the menu, the menu track replaces it.

---

### Stop the music only through this module

The module remembers which track it is playing. If you stop channel 1 yourself, for example with `audio.stop()`, the module still thinks the track is playing, and the next [`play`](#play) call with the same file does nothing. Use [`stop`](#stop) instead, and leave channel 1 to this module. Set the channel's volume through [`updateVolume`](#updatevolume) too, so a fade in progress keeps its place.

---

### Fades keep running while the game is paused

The fades run on `enterFrame` and `system.getTimer()`, not on timers or transitions, so `timer.pauseAll()` and `transition.pauseAll()` do not freeze them.

## Functions/API

### Playing music

#### play

Plays `filename` on a loop. Any other track fades out first, then `filename` starts silent and fades in. If `filename` is already playing, the music continues without restarting, and if it was fading out, it fades back in. When `play` or [`stop`](#stop) is called during a fade, the last call decides what plays.

```lua
music.play( filename )
```

---

#### stop

Fades the current track out, then stops it and frees its memory. Pass `{ immediate = true }` to stop it at once.

```lua
music.stop( params )
```

---

#### getCurrent

Returns the filename of the track that is playing or about to play, or `nil` when the music is stopped or fading out to silence.

```lua
music.getCurrent()
```

---

#### updateVolume

Sets channel 1 to the player's music volume from `loadsave.userdata.audio.volume.music`, scaled by the fade in progress. The options scene calls it when the Music Volume slider moves.

```lua
music.updateVolume()
```

## Examples

### A game scene with its own track

Start the track in the scene's `show` "did" phase. Calling `play` on every visit is safe, because a track that is already playing just continues, and a track that is still fading out lets the new one fade in after it. This example uses the core menu track; put your own file's path in its place.

```lua
local composer = require( "composer" )
local music = require( "classes.music" )

local scene = composer.newScene()

function scene:show( event )
	if event.phase == "did" then
		music.play( "assets/audio/template/music/menuMusic.mp3" )
	end
end

scene:addEventListener( "show", scene )

return scene
```
