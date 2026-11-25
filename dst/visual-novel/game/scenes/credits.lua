local composer = require("composer")
local scene = composer.newScene()

---------------------------------------------------------------------------

-- Common plugins, modules, libraries & classes.
local screen = require( "classes.screen" )
local creditsData = require( "data.credits" )
local menuBackground = require( "widgets.menuBackground" )
local sceneTitle = require( "widgets.sceneTitle" )
local widget = require( "widget" )

---------------------------------------------------------------------------

-- Shared handles for the core UI sounds.
local audioHandles = require( "libs.audioHandles" )

---------------------------------------------------------------------------

-- Forward declarations & variables.
local scrollView
local creditsTextGroup
local buttonBack
local isUserTouching = false
local lastFrameTime = nil
local scrollPixelsPerMs = 0
local maxScrollY = 0
local autoScrollActive = false
local endFadeStarted = false

---------------------------------------------------------------------------

-- Functions.

-- Fade the credits text out once the scroll has reached its end.
local function fadeOutText()
	local endFadeTime = creditsData.config.endFadeTime
	if endFadeStarted or endFadeTime <= 0 then
		return
	end

	endFadeStarted = true
	transition.to( creditsTextGroup, { time = endFadeTime, alpha = 0 } )
end

-- Show the credits text at full opacity again, stopping a fade that is still running.
local function restoreText()
	transition.cancel( creditsTextGroup )
	creditsTextGroup.alpha = 1
	endFadeStarted = false
end

local function scrollListener( event )
	local phase = event.phase
	if phase == "began" then
		isUserTouching = true
		lastFrameTime = nil

		-- A touch brings faded credits back.
		if endFadeStarted then
			restoreText()
		end

	elseif phase == "ended" then
		isUserTouching = false
		lastFrameTime = nil

		-- Re-enable auto-scroll if user dragged back up from the bottom,
		-- or fade the text out again if they let go at the end.
		if scrollPixelsPerMs > 0 then
			local _, currentY = scrollView:getContentPosition()
			if currentY > maxScrollY then
				autoScrollActive = true
			else
				fadeOutText()
			end
		end
	end
	return true
end

local function onEnterFrame( event )
	if not autoScrollActive or not scrollView or isUserTouching then
		lastFrameTime = nil
		return
	end

	local currentTime = event.time
	if lastFrameTime == nil then
		lastFrameTime = currentTime
		return
	end

	local deltaTime = currentTime - lastFrameTime
	lastFrameTime = currentTime

	local _, currentY = scrollView:getContentPosition()

	if currentY <= maxScrollY then
		autoScrollActive = false
		fadeOutText()
		return
	end

	local newY = currentY - scrollPixelsPerMs * deltaTime
	if newY < maxScrollY then
		newY = maxScrollY
	end

	scrollView:scrollToPosition({ y = newY, time = 0 })
end

local function handleButtonEvent( event )
	if event.phase == "ended" then
		local id = event.target.id

		audio.play( audioHandles.click )

		if id == "back" then
			composer.gotoScene( "scenes.menu", { effect = "fade", time = 500 } )
		end
	end
end

---------------------------------------------------------------------------

function scene:create( event )
	local sceneGroup = self.view
	local config = creditsData.config

	menuBackground.new( sceneGroup )

	sceneTitle.new( sceneGroup, config.title.text, screen.centerX, screen.minY + config.title.yOffset )

	local buttonConfig = config.backButton
	buttonBack = widget.newButton({
		id = "back",
		label = buttonConfig.label,
		labelAlign = buttonConfig.labelAlign,
		width = buttonConfig.width,
		height = buttonConfig.height,
		fontSize = buttonConfig.fontSize,
		font = buttonConfig.font,
		labelColor = buttonConfig.labelColor,
		fillColor = buttonConfig.fillColor,
		onEvent = handleButtonEvent,
		shape = buttonConfig.shape,
		isEnabled = false,
	})
	buttonBack.x = screen.minX + buttonConfig.xOffset
	buttonBack.y = screen.maxY - buttonConfig.yOffset
	buttonBack.anchorX, buttonBack.anchorY = 0, 1
	sceneGroup:insert( buttonBack )

	-- Create a scrollable text field that automatically starts scrolling.
	local scrollConfig = config.scrollView
	scrollView = widget.newScrollView(
		{
			top = scrollConfig.top,
			left = screen.centerX - scrollConfig.width * 0.5,
			width = scrollConfig.width,
			height = scrollConfig.height,
			scrollWidth = scrollConfig.width,
			scrollHeight = scrollConfig.scrollHeight,
			bottomPadding = scrollConfig.bottomPadding,
			backgroundColor = scrollConfig.backgroundColor,
			horizontalScrollDisabled = true,
			hideScrollBar = true,
			listener = scrollListener
		}
	)
	sceneGroup:insert( scrollView )

	-- All credit texts go in one group, so the whole text can fade out at once.
	creditsTextGroup = display.newGroup()
	scrollView:insert( creditsTextGroup )

	-- Create credit entries from data.
	local entries = creditsData.entries
	local text = {}

	for i = 1, #entries do
		local entry = entries[i]

		text[i] = display.newText({
			parent = creditsTextGroup,
			text = entry.text,
			width = scrollConfig.width,
			align = "center",
			font = entry.font,
			fontSize = entry.fontSize,
			x = scrollConfig.width * 0.5,
			y = (text[i-1] and text[i-1].y + text[i-1].height + entry.padding or 0)
		})

		text[i].anchorY = 0
		text[i]:setFillColor( entry.color[1], entry.color[2], entry.color[3] )
	end

	-- Calculate scroll metrics for linear scrolling.
	local lastText = text[#text]
	if lastText then
		local contentBottom = lastText.y + lastText.height + (scrollConfig.bottomPadding or 0)
		local scrollableDistance = contentBottom - scrollConfig.height
		if scrollableDistance > 0 then
			maxScrollY = -scrollableDistance
			scrollPixelsPerMs = scrollableDistance / config.scrollSpeed
		else
			maxScrollY = 0
			scrollPixelsPerMs = 0
		end
	end

end

---------------------------------------------------------------------------

function scene:show( event )
	if event.phase == "will" then

	elseif event.phase == "did" then
		buttonBack:setEnabled( true )

		-- Start linear auto-scroll if there is content to scroll.
		isUserTouching = false
		lastFrameTime = nil
		if scrollPixelsPerMs > 0 then
			local _, currentY = scrollView:getContentPosition()
			if currentY > maxScrollY then
				autoScrollActive = true
				Runtime:addEventListener( "enterFrame", onEnterFrame )
			end
		end
	end
end

---------------------------------------------------------------------------

function scene:hide( event )
	if event.phase == "will" then
		buttonBack:setEnabled( false )

		-- Stop auto-scroll when leaving the scene.
		autoScrollActive = false
		Runtime:removeEventListener( "enterFrame", onEnterFrame )

		-- Return a faded text to full opacity for the next visit.
		restoreText()
	elseif event.phase == "did" then

	end
end

---------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )

---------------------------------------------------------------------------

return scene
