-- Shared handles for the core UI sounds, loaded once so every scene and widget plays the same buffer.
-- Music is not loaded here: classes/music.lua streams it.

local audioHandles = {}

-------------------------------------------------------------------------
-- Handles

audioHandles.click = audio.loadSound( "assets/audio/template/sfx/click.wav" )

-------------------------------------------------------------------------

return audioHandles
