-- Targets appear one at a time at random places, and the player touches as many as they can before the time runs out.

local targetPractice = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local screen = require( "classes.screen" )
local settings = require( "libs.settings" )

--------------------------------------------------------------------------------------
-- Forward declarations & variables

-- Every timer and transition of a round carries this tag, so pausing, resuming and removing the round reach all of them.
local roundTag = "targetPractice"

local millisecondsPerSecond = 1000

--------------------------------------------------------------------------------------
-- Public functions

-- Start a round in parent. When the time runs out, onComplete gets the story variables the round sets.
-- The returned round has pause, resume, resize and remove; the scene removes it, also after onComplete.
function targetPractice.start( parent, onComplete )
	local config = settings.visualNovel.minigames.targetPractice
	local round = {}

	local group = display.newGroup()
	parent:insert( group )

	local hits = 0
	local timeLeft = config.duration
	local isPaused = false
	local target, expireTimer
	local spawnTarget

	local counter = display.newText( {
		parent = group,
		text = "",
		x = screen.minX + config.hudMargin,
		y = screen.minY + config.hudMargin,
		font = settings.fonts.bold,
		fontSize = config.hudFontSize,
	} )
	counter.anchorX = 0
	counter.anchorY = 0

	local clock = display.newText( {
		parent = group,
		text = "",
		x = screen.centerX,
		y = screen.minY + config.hudMargin,
		font = settings.fonts.bold,
		fontSize = config.hudFontSize,
	} )
	clock.anchorY = 0

	local function updateHud()
		counter.text = string.format( config.counterText, hits, config.goal )
		clock.text = string.format( config.clockText, timeLeft )
	end

	local function removeTarget()
		display.remove( target )
		target = nil
	end

	local function scheduleSpawn()
		timer.performWithDelay( config.spawnDelay, spawnTarget, 1, roundTag )
	end

	local function onTargetExpired()
		removeTarget()
		scheduleSpawn()
	end

	local function onTargetTouch( event )
		if event.phase == "began" and not isPaused then
			hits = hits + 1
			updateHud()

			local hitImage = display.newImageRect( group, config.hitImage, config.targetSize, config.targetSize )
			hitImage.x = target.x
			hitImage.y = target.y
			transition.to( hitImage, { alpha = 0, time = config.hitFadeTime, tag = roundTag, onComplete = display.remove } )

			timer.cancel( expireTimer )
			removeTarget()
			scheduleSpawn()
		end
		return true
	end

	function spawnTarget()
		target = display.newImageRect( group, config.targetImage, config.targetSize, config.targetSize )
		target.x = math.random( screen.minX + config.edgeMargin, screen.maxX - config.edgeMargin )
		target.y = math.random( screen.minY + config.topMargin, screen.maxY - config.edgeMargin )
		target:addEventListener( "touch", onTargetTouch )

		expireTimer = timer.performWithDelay( config.targetLifetime, onTargetExpired, 1, roundTag )
	end

	local function onTick()
		timeLeft = timeLeft - 1
		updateHud()

		if timeLeft > 0 then
			timer.performWithDelay( millisecondsPerSecond, onTick, 1, roundTag )
		else
			timer.cancel( roundTag )
			removeTarget()
			onComplete( { targetHits = hits, targetGoalReached = hits >= config.goal } )
		end
	end

	-- Follow a change of the visible area: the counters go back to their corners, and a target on screen stays inside the play area.
	function round:resize()
		counter.x = screen.minX + config.hudMargin
		counter.y = screen.minY + config.hudMargin
		clock.x = screen.centerX
		clock.y = screen.minY + config.hudMargin

		if target then
			target.x = math.min( math.max( target.x, screen.minX + config.edgeMargin ), screen.maxX - config.edgeMargin )
			target.y = math.min( math.max( target.y, screen.minY + config.topMargin ), screen.maxY - config.edgeMargin )
		end
	end

	function round:pause()
		isPaused = true
		timer.pause( roundTag )
		transition.pause( roundTag )
	end

	function round:resume()
		isPaused = false
		timer.resume( roundTag )
		transition.resume( roundTag )
	end

	-- The engine keeps a timer that is cancelled while paused in its paused list for good, so a paused round resumes first.
	function round:remove()
		if isPaused then
			timer.resume( roundTag )
		end
		timer.cancel( roundTag )
		transition.cancel( roundTag )
		display.remove( group )
	end

	updateHud()
	scheduleSpawn()
	timer.performWithDelay( millisecondsPerSecond, onTick, 1, roundTag )

	return round
end

return targetPractice
