-- Background music on the reserved channel 1, with fades between tracks.

local music = {}

---------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local loadsave = require( "classes.loadsave" )
local settings = require( "libs.settings" )

---------------------------------------------------------------------------
-- Forward declarations & variables

local musicChannel = 1

local currentFilename = nil
local currentStream = nil

-- The track to start once the current one has faded out, or nil to stay silent.
local nextFilename = nil

-- How loud the current track is relative to the player's music volume, from 0 to 1.
local fadeLevel = 0
local targetLevel = 0

local isFading = false
local lastFrameTime = 0

---------------------------------------------------------------------------
-- Private functions

-- The player's music slider owns channel 1, so every volume set here is scaled from it.
local function applyVolume()
	local level = currentStream and fadeLevel or 1
	audio.setVolume( loadsave.userdata.audio.volume.music / 100 * level, { channel = musicChannel } )
end

-- Stop the channel before disposing, because a stream that is still playing cannot be disposed.
local function stopCurrent()
	audio.stop( musicChannel )

	if currentStream then
		audio.dispose( currentStream )
	end

	currentStream = nil
	currentFilename = nil
end

-- The track starts silent and the fade brings it up.
local function startTrack( filename )
	currentStream = audio.loadStream( filename )
	currentFilename = filename
	fadeLevel = 0
	targetLevel = 1
	applyVolume()
	audio.play( currentStream, { channel = musicChannel, loops = -1 } )
end

-- Driven by enterFrame and system.getTimer, so a game that pauses every timer and transition does not freeze the fade.
local function onEnterFrame()
	local now = system.getTimer()
	local elapsed = now - lastFrameTime
	lastFrameTime = now

	if fadeLevel < targetLevel then
		local fadeInTime = settings.music.fadeInTime
		fadeLevel = fadeInTime > 0 and math.min( targetLevel, fadeLevel + elapsed / fadeInTime ) or targetLevel
	else
		local fadeOutTime = settings.music.fadeOutTime
		fadeLevel = fadeOutTime > 0 and math.max( targetLevel, fadeLevel - elapsed / fadeOutTime ) or targetLevel
	end

	if fadeLevel == targetLevel and targetLevel == 0 then
		stopCurrent()

		if nextFilename then
			startTrack( nextFilename )
			nextFilename = nil
			return
		end
	end

	applyVolume()

	if fadeLevel == targetLevel then
		Runtime:removeEventListener( "enterFrame", onEnterFrame )
		isFading = false
	end
end

local function startFading()
	if not isFading and fadeLevel ~= targetLevel then
		lastFrameTime = system.getTimer()
		Runtime:addEventListener( "enterFrame", onEnterFrame )
		isFading = true
	end
end

---------------------------------------------------------------------------
-- Public functions

-- Play a looping music track. Asking for the current track keeps it playing without a restart,
-- and fades it back in if it was fading out.
function music.play( filename )
	if filename == currentFilename then
		nextFilename = nil
		targetLevel = 1

	elseif currentStream then
		nextFilename = filename
		targetLevel = 0

	else
		startTrack( filename )

	end

	startFading()
end

-- Fade the music out, then stop and dispose it. Pass { immediate = true } to stop at once.
function music.stop( params )
	nextFilename = nil
	targetLevel = 0

	if params and params.immediate then
		Runtime:removeEventListener( "enterFrame", onEnterFrame )
		isFading = false
		stopCurrent()
		fadeLevel = 0
		applyVolume()
		return
	end

	startFading()
end

-- Set channel 1 to the player's music volume, scaled by the fade in progress.
function music.updateVolume()
	applyVolume()
end

-- Returns the filename of the track that is playing or about to play, or nil when the music is stopping or stopped.
function music.getCurrent()
	if nextFilename then
		return nextFilename
	end

	return targetLevel > 0 and currentFilename or nil
end

return music
