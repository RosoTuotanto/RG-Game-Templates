local composer = require("composer")
local scene = composer.newScene()

---------------------------------------------------------------------------

local screen = require("classes.screen")
local settings = require("libs.settings")

local splash = settings.splashScreen or {}
local customParams = nil

local logoGroup = display.newGroup()
logoGroup.alpha = 0

---------------------------------------------------------------------------

function scene:create( event )
	local sceneGroup = self.view
	sceneGroup:insert( logoGroup )

	-- The custom launch parameters are forwarded to the first scene.
	local sceneParams = event.params or {}
	customParams = sceneParams.launchParams

	-- Scale factor to convert pixel sizes to content units, ensuring
	-- assets render at consistent physical size regardless of config.lua.
	-- In landscape, pixelWidth maps to actualContentHeight (the longer content dimension).
	-- In portrait, pixelWidth maps to actualContentWidth (the shorter content dimension).
	local pixelScale
	if display.pixelWidth >= display.pixelHeight then
		pixelScale = display.actualContentHeight / display.pixelWidth
	else
		pixelScale = display.actualContentWidth / display.pixelWidth
	end

	-- Create the logo image (if defined).
	local filename = splash.logoFilename
	if filename then
		local width = splash.logoWidth or splash.logoHeight or 100
		local height = splash.logoHeight or width

		local logo = display.newImageRect( logoGroup, filename, width * pixelScale, height * pixelScale )
		logo.x, logo.y = screen.centerX + (splash.logoOffsetX or 0), screen.centerY + (splash.logoOffsetY or 0)
		logo.anchorX = splash.logoAnchorX or 0.5
		logo.anchorY = splash.logoAnchorY or 0.5
	end

	-- Extract the year (first 4 digits before the dot).
	local buildYear = tonumber(system.getInfo( "build" ):match("^(%d%d%d%d)"))
	local projectYear = splash.projectYear or buildYear

	-- Create the footer/copyright text.
	local text

	if buildYear > projectYear then
		text = "© " .. projectYear .. "-" ..buildYear .. " Roso Games\nwww.rosogames.fi"
	else
		text = "© " .. projectYear .. " Roso Games\nwww.rosogames.fi"
	end

	local footer = display.newText( {
		parent = logoGroup,
		text = text,
		x = screen.centerX + (splash.textOffsetX or 0),
		y = screen.maxY + (splash.textOffsetY or 0),
		width = splash.textWidth or screen.width,
		font = settings.fonts.bold,
		fontSize = (splash.fontSize or 20) * pixelScale,
		align = splash.textAlign or "right"
	} )
	footer.anchorX = splash.textAnchorX or 0.5
	footer.anchorY = splash.textAnchorY or 1
end

---------------------------------------------------------------------------

function scene:show( event )
	if event.phase == "did" then
		transition.to( logoGroup, {
			delay = splash.showDelay or 250,
			time = splash.showTime or 500,
			alpha = 1,
			transition = splash.showEasing or easing.inOut,
			onComplete = function()
				-- Hide the logo and the footer text after a delay.
				transition.to( logoGroup, {
					delay = splash.hideDelay or 1250,
					time = splash.hideTime or 250,
					alpha = 0,
					transition = splash.hideEasing or easing.inOut,
					onComplete = function()
						composer.gotoScene( "scenes." .. settings.startScene, {
							effect = "fade",
							time = 100,
							params = {
								launchParams = customParams,
							}
						} )
					end
				})
			end
		})
	end
end

---------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

---------------------------------------------------------------------------

return scene
