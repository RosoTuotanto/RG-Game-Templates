-- Dialogue module. Loads the story into the Weaver story engine and draws the dialogue window.
-- Weaver draws nothing on screen by itself, so the game is responsible for the UI.
-- A passage's text lines are revealed one at a time with the interact key, and the
-- choices appear only on the last line.
-- The game scene stops the player from moving while a dialogue is open.

local dialogue = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local weaver = require( "libs.spyricStoryWeaver" )
local screen = require( "classes.screen" )
local settings = require( "libs.settings" )
local inventory = require( "classes.inventory" )

-- libs.utils replaces table.copy with a version that also copies nested tables.
require( "libs.utils" )

--------------------------------------------------------------------------------------
-- Forward declarations & variables

-- The story's name and its source file come from the settings. Weaver recognises the story by this name.
local storyName = settings.story.name
local storySource = settings.story.source

-- Weaver keeps the story's state in a global table named after the story.
local storyGlobalKey = "WEAVERx" .. storyName:gsub( "%s+", "" )

local font = settings.fonts.regular
local textSize = 24

-- Colours of a normal and a highlighted choice.
local colorNormal = { 0.7, 0.7, 0.7 }
local colorSelected = { 1, 0.82, 0.1 }

-- The parts of the dialogue window. When overlay is nil, the dialogue is closed.
local overlay
local panelTop
local bodyText
local moreMarker

-- The passage's text lines, of which line number textLineIndex is on screen.
local textLines = {}
local textLineIndex = 0

-- The passage's choices. choiceLabels are plain strings until the last line is
-- shown, and then they are turned into selectable text objects in choiceTexts.
local choiceLabels = {}
local choiceTexts = {}
local choiceTargets = {}
local selectedChoice = 1

-- A function from the game that handles the story's own <<...>> commands, such as adding an item.
local commandHandler

-- An optional function from the game that runs once the dialogue window closes.
local closeHandler

local renderNode

--------------------------------------------------------------------------------------
-- Private functions

-- Remove the visible text and choices before drawing new ones.
local function clearContent()
	display.remove( bodyText )
	bodyText = nil

	for i = 1, #choiceTexts do
		display.remove( choiceTexts[i] )
	end
	choiceTexts = {}
end


-- Colour the choices so that the selected one stands out.
local function highlightChoice()
	for i = 1, #choiceTexts do
		if i == selectedChoice then
			choiceTexts[i]:setFillColor( unpack( colorSelected ) )
		else
			choiceTexts[i]:setFillColor( unpack( colorNormal ) )
		end
	end
end


-- Build the dialogue window: a dimmed background, a panel at the bottom of the screen and a "more" marker.
local function buildOverlay( parentGroup )
	overlay = display.newGroup()
	parentGroup:insert( overlay )

	-- Dim the game world so that the dialogue stands out from it.
	local dim = display.newRect( overlay, screen.centerX, screen.centerY, screen.width, screen.height )
	dim:setFillColor( 0, 0.55 )

	local panelWidth = screen.width - 240
	local panelHeight = 180
	local panelCenterY = screen.maxY - panelHeight * 0.5 - 32
	panelTop = panelCenterY - panelHeight * 0.5

	local panel = display.newRoundedRect( overlay, screen.centerX, panelCenterY, panelWidth, panelHeight, 16 )
	panel:setFillColor( 0.12, 0.12, 0.16 )
	panel.strokeWidth = 3
	panel:setStrokeColor( 0.4, 0.4, 0.5 )

	-- The "more" marker in the panel's bottom right corner is visible while
	-- the passage still has lines that have not been shown.
	moreMarker = display.newText({
		parent = overlay,
		text = "...",
		x = screen.centerX + panelWidth * 0.5 - 32,
		y = panelCenterY + panelHeight * 0.5 - 20,
		font = font,
		fontSize = textSize,
	} )
	moreMarker:setFillColor( unpack( colorNormal ) )
	moreMarker.isVisible = false
end


-- Turn the collected choices into visible, selectable texts below the body text.
local function showChoices()
	local nextY = bodyText.y + bodyText.height + 16

	for i = 1, #choiceLabels do
		local choice = display.newText({
			parent = overlay,
			text = "> " .. choiceLabels[i],
			x = screen.centerX,
			y = nextY,
			width = screen.width - 288,
			font = font,
			fontSize = textSize,
			align = "left",
		} )
		choice.anchorY = 0
		choiceTexts[i] = choice
		nextY = nextY + choice.height + 8
	end

	selectedChoice = 1
	highlightChoice()
end


-- Show the current text line. Lines are revealed one at a time, so the previous
-- line is removed and the new one is drawn in its place. On the last line the
-- "more" marker turns off and the choices appear.
local function showCurrentLine()
	clearContent()

	bodyText = display.newText({
		parent = overlay,
		text = textLines[textLineIndex],
		x = screen.centerX,
		y = panelTop + 20,
		width = screen.width - 288,
		font = font,
		fontSize = textSize,
		align = "left",
	} )
	bodyText.anchorY = 0

	local isLastLine = textLineIndex >= #textLines
	moreMarker.isVisible = not isLastLine

	if isLastLine then
		showChoices()
	end
end


-- Get a passage (called a node in Weaver's code) and start revealing its lines. Weaver
-- returns the passage as a list of lines, and each line is a table whose first value is its type.
function renderNode( nodeName )
	-- Copy the items the player holds into the story variable $inventory first, so the passage's
	-- conditions can ask about them, such as <<if $inventory.parcel>>.
	_G[storyGlobalKey].saveData.inventory = inventory.getHeldItems()

	local line = weaver.getNode( nodeName, storyName )

	textLines = {}
	choiceLabels = {}
	choiceTargets = {}

	for i = 1, #line do
		local lineType = line[i][1]

		if lineType == "text" then
			textLines[#textLines+1] = line[i][2]

		elseif lineType == "link" then
			choiceTargets[#choiceTargets+1] = line[i][3]
			choiceLabels[#choiceLabels+1] = line[i][2]

		elseif commandHandler then
			-- Every other line is one of the story's own <<...>> commands, which the game handles.
			commandHandler( line[i] )
		end
	end

	-- A passage can end up with no text because of its conditions. An empty line keeps
	-- the window working as usual, and any choices are then shown straight away.
	if #textLines == 0 then
		textLines[1] = ""
	end

	textLineIndex = 1
	showCurrentLine()
end

--------------------------------------------------------------------------------------
-- Public functions

-- Load the story into Weaver. The story always starts from the beginning, and
-- Weaver keeps its state in memory.
function dialogue.init()
	weaver.initStory({
		name = storyName,
		source = storySource,
	} )
end


-- Open a dialogue at the given passage. The window is added to parentGroup, which
-- does not move with the camera, so the dialogue stays in place on the screen.
-- onCommand is an optional function that handles the story's own <<...>> commands, and
-- onClose an optional function that runs once the window closes.
function dialogue.open( nodeName, parentGroup, onCommand, onClose )
	if overlay then
		return
	end

	commandHandler = onCommand
	closeHandler = onClose
	buildOverlay( parentGroup )
	renderNode( nodeName )
end


-- Show a single line without a passage, such as the hero's own comment at a locked gate.
-- The window otherwise works like a dialogue, and the interact key closes it.
function dialogue.showMonologue( text, parentGroup )
	if overlay then
		return
	end

	commandHandler = nil
	closeHandler = nil
	buildOverlay( parentGroup )

	textLines = { text }
	choiceLabels = {}
	choiceTargets = {}
	textLineIndex = 1
	showCurrentLine()
end


-- Build the open window again at the screen's current size, on the same line and choice.
function dialogue.resize()
	if not overlay then
		return
	end

	local parentGroup = overlay.parent
	local choice = selectedChoice

	clearContent()
	display.remove( overlay )
	buildOverlay( parentGroup )
	showCurrentLine()

	if #choiceTexts > 0 then
		selectedChoice = choice
		highlightChoice()
	end
end


function dialogue.isOpen()
	return overlay ~= nil
end


-- Handle key presses during a dialogue: the interact key reveals the next line, and
-- on the last line the up and down keys pick a choice and the interact key confirms
-- the choice or closes the dialogue.
function dialogue.handleKey( action, phase )
	if phase ~= "down" then
		return
	end

	if action == "up" then
		if #choiceTexts > 0 then
			selectedChoice = selectedChoice > 1 and selectedChoice - 1 or #choiceTexts
			highlightChoice()
		end

	elseif action == "down" then
		if #choiceTexts > 0 then
			selectedChoice = selectedChoice < #choiceTexts and selectedChoice + 1 or 1
			highlightChoice()
		end

	elseif action == "interact" then
		if textLineIndex < #textLines then
			textLineIndex = textLineIndex + 1
			showCurrentLine()
		elseif #choiceTargets > 0 then
			renderNode( choiceTargets[selectedChoice] )
		else
			dialogue.close()
		end
	end
end


-- Close the window. The onClose function given to dialogue.open runs afterwards, unless
-- skipHandler is true: a scene that is being left closes with true, so nothing new is built
-- into a scene that is going away.
function dialogue.close( skipHandler )
	if skipHandler then
		closeHandler = nil
	end

	clearContent()
	display.remove( overlay )
	overlay = nil
	panelTop = nil
	moreMarker = nil

	textLines = {}
	textLineIndex = 0
	choiceLabels = {}
	choiceTargets = {}
	commandHandler = nil

	-- The handler is cleared before it runs, so it runs once per opened dialogue and may open
	-- a new dialogue of its own.
	local onClose = closeHandler
	closeHandler = nil

	if onClose then
		onClose()
	end
end


-- Read the value of a story variable ($name) from Weaver's save data. For example, a locked
-- exit reads the variable that its requiredFlag property names. Returns nil before init.
function dialogue.getFlag( name )
	local story = _G[storyGlobalKey]
	if story and story.saveData then
		return story.saveData[name]
	end
end


-- Return a copy of the story's state: the visit count of every passage and the
-- story's variables. The game scene stores it in the save slot with the rest of the game.
function dialogue.getState()
	return table.copy( _G[storyGlobalKey].saveData )
end


-- Start the story from the beginning and then write a saved state over it. Passages and
-- variables that were added to the story after the save was made keep their starting values.
function dialogue.setState( state )
	dialogue.init()

	-- Weaver reads the state through the global story table, so the saved values are
	-- written into the live table instead of replacing it. The copy keeps the game
	-- scene's saved table unchanged while the story goes on.
	local saveData = _G[storyGlobalKey].saveData
	local savedState = table.copy( state )

	for key, value in pairs( savedState ) do
		if key == "node" then
			for nodeName, nodeData in pairs( value ) do
				saveData.node[nodeName] = nodeData
			end
		else
			saveData[key] = value
		end
	end
end

--------------------------------------------------------------------------------------

return dialogue
