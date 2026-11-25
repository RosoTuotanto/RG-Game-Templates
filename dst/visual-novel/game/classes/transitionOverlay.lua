-- A black full-screen fade that survives scene changes and holds at black until dismiss is called.

local transitionOverlay = {}

---------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local screen = require( "classes.screen" )
local settings = require( "libs.settings" )

---------------------------------------------------------------------------
-- Forward declarations & variables

local activeGroup
local activeRect
local activeText
local isFadingIn = false
local isFadingOut = false
local pendingDismiss = nil
local startFadeOut
local fadeOutTime = settings.transition.fadeOutTime

---------------------------------------------------------------------------
-- Private functions

local function blockInput()
	return true
end

local function cleanup()
	transition.cancel( activeRect )

	if activeText then
		transition.cancel( activeText )
	end

	display.remove( activeGroup )
	activeGroup = nil
	activeRect = nil
	activeText = nil

	isFadingIn = false
	isFadingOut = false
	pendingDismiss = nil
end

local function createText( params, alpha )
	activeText = display.newText( {
		parent = activeGroup,
		text = params.text,
		x = screen.centerX,
		y = screen.centerY,
		font = params.font or settings.fonts.bold,
		fontSize = 48,
	} )
	activeText.alpha = alpha
end

local function startFadeIn( fadeInTime, onMidpoint )
	isFadingIn = true

	transition.to( activeRect, {
		alpha = 1,
		time = fadeInTime,
		onComplete = function()
			isFadingIn = false

			if onMidpoint then
				onMidpoint()
			end

			-- A dismiss that arrived during the fade-in starts its fade-out only now.
			if pendingDismiss then
				local callback = pendingDismiss
				pendingDismiss = nil
				startFadeOut( callback )
			end
		end,
	} )

	if activeText then
		transition.to( activeText, { alpha = 1, time = fadeInTime } )
	end
end

function startFadeOut( onComplete )
	isFadingOut = true

	transition.to( activeRect, {
		alpha = 0,
		time = fadeOutTime,
		onComplete = function()
			cleanup()

			if onComplete then
				onComplete()
			end
		end,
	} )

	if activeText then
		transition.to( activeText, { alpha = 0, time = fadeOutTime } )
	end
end

---------------------------------------------------------------------------
-- Public functions

-- Fade to black, then call params.onMidpoint (for example to change the scene).
-- A call while the overlay fades to black or holds at black does nothing, and its onMidpoint never runs.
-- A call while the overlay fades away stops that fade and fades the same overlay back to black.
function transitionOverlay.show( params )
	if activeGroup and not isFadingOut then
		return
	end

	params = params or {}
	local fadeInTime = params.fadeInTime or settings.transition.fadeInTime
	fadeOutTime = params.fadeOutTime or settings.transition.fadeOutTime
	local onMidpoint = params.onMidpoint

	if activeGroup then
		-- Cancelling the fade-out also drops its onComplete, so the earlier dismiss callback never runs.
		transition.cancel( activeRect )
		isFadingOut = false

		-- The old text belongs to the earlier request, so the new request's text replaces it.
		if activeText then
			transition.cancel( activeText )
			display.remove( activeText )
			activeText = nil
		end

		if params.text then
			createText( params, activeRect.alpha )
		end

		-- The overlay is already partly black, so the fade takes only the part of the time that is left.
		startFadeIn( fadeInTime * (1 - activeRect.alpha), onMidpoint )
		return
	end

	-- The overlay goes on the stage, not in a scene, so it stays visible while composer changes scenes.
	activeGroup = display.newGroup()
	display.getCurrentStage():insert( activeGroup )

	activeRect = display.newRect( activeGroup, screen.centerX, screen.centerY, screen.width, screen.height )
	activeRect:setFillColor( 0 )
	activeRect.alpha = 0

	-- Swallow touches and taps so nothing below the overlay can be pressed.
	activeRect:addEventListener( "touch", blockInput )
	activeRect:addEventListener( "tap", blockInput )

	if params.text then
		createText( params, 0 )
	end

	startFadeIn( fadeInTime, onMidpoint )
end

-- Fade the overlay out and then call onComplete.
function transitionOverlay.dismiss( onComplete )
	-- With no overlay showing, call onComplete right away so the caller is never left waiting.
	if not activeGroup then
		if onComplete then
			onComplete()
		end
		return
	end

	if isFadingIn then
		pendingDismiss = onComplete or function() end
		return
	end

	startFadeOut( onComplete )
end

function transitionOverlay.isActive()
	return activeGroup ~= nil
end

return transitionOverlay
