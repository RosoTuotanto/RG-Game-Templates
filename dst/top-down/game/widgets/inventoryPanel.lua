-- The inventory UI: a grid panel in the middle of the screen with item icons from the
-- item image sheet, a cursor moved with the arrow keys or by touching a slot, and an info box that shows the
-- name and description of the item in the selected slot.
-- The panel is drawn into the scene group, so it does not move with the camera.
-- It uses the same look as the dialogue window (dimmed background, colours and font).

local inventoryPanel = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local screen = require( "classes.screen" )
local settings = require( "libs.settings" )
local inventory = require( "classes.inventory" )
local items = require( "data.items" )

-- libs.utils adds display.fitText, which cuts the item's name and description to their places.
require( "libs.utils" )

--------------------------------------------------------------------------------------
-- Forward declarations & variables

-- The panel's size is worked out from the settings, so changing one of them keeps the panel in proportion.
local inventorySettings = settings.inventory
local columns = inventorySettings.columns
local rows = inventorySettings.rows
local slotSize = inventorySettings.slotSize
local slotGap = inventorySettings.slotGap
local padding = inventorySettings.padding
local titleHeight = inventorySettings.titleHeight
local sectionGap = inventorySettings.sectionGap
local iconSize = inventorySettings.iconSize

local gridWidth = columns * slotSize + ( columns - 1 ) * slotGap
local gridHeight = rows * slotSize + ( rows - 1 ) * slotGap
local panelWidth = gridWidth + 2 * padding

local slotCount = columns * rows

local titleFontSize = inventorySettings.titleFontSize
local nameFontSize = inventorySettings.nameFontSize
local descriptionFontSize = inventorySettings.descriptionFontSize

-- Distances inside the info box: from its left edge to the texts, from its top to the name and
-- to the description, and from the description area to its bottom.
local infoInset = 16
local nameTop = 14
local descriptionTop = 52
local infoBottomGap = 14

-- The name and the description may be as wide as the info box minus its insets.
local textWidth = gridWidth - 2 * infoInset

-- The height of descriptionLines lines of the description font, measured on a text object the first
-- time the inventory opens. The info box and the panel grow to fit it.
local descriptionHeight

-- The same colours as in the dialogue window.
local cursorColor = { 1, 0.82, 0.1 }
local textNormal = { 0.7, 0.7, 0.7 }

-- The panel's parts and state. When overlay is nil, the inventory is closed.
local overlay
local dim
local slotPositions = {}
local iconObjects = {}
local cursorFrame
local nameText
local descriptionText

-- An optional text at the right end of the title row, such as the player's money.
local statusText

-- The function given to inventoryPanel.open that runs once the panel closes.
local closeHandler

-- The slot under the cursor (1 to slotCount) and the slot whose item the player is holding.
local cursorIndex = 1
local heldIndex

--------------------------------------------------------------------------------------
-- Private functions

-- Redraw the item icons from the current contents of the slots. A held item is faded,
-- so the player can see which item they are about to move.
local function refreshSlots()
	for slotIndex = 1, #iconObjects do
		display.remove( iconObjects[slotIndex] )
	end
	iconObjects = {}

	local sheet = inventory.getItemSheet()
	for slotIndex = 1, slotCount do
		local itemId = inventory.getSlot( slotIndex )
		local itemData = itemId and items[itemId]

		if itemData then
			local position = slotPositions[slotIndex]
			local icon = display.newImageRect( overlay, sheet, itemData.frame, iconSize, iconSize )
			icon.x, icon.y = position.x, position.y

			if slotIndex == heldIndex then
				icon.alpha = 0.45
			end
			iconObjects[#iconObjects+1] = icon
		end
	end

	-- Keep the cursor on top of the icons.
	if cursorFrame then
		cursorFrame:toFront()
	end
end


-- Move the cursor to the selected slot and show that slot's item in the info box.
local function refreshCursor()
	local position = slotPositions[cursorIndex]
	cursorFrame.x, cursorFrame.y = position.x, position.y

	local itemId = inventory.getSlot( cursorIndex )
	local itemData = itemId and items[itemId]

	local name = "Empty slot"
	local description = inventorySettings.emptySlotDescription
	if itemData then
		name = itemData.name
		description = itemData.description
	end

	display.fitText( nameText, name, textWidth )
	display.fitText( descriptionText, description, nil, descriptionHeight )
end


-- Measure how tall descriptionLines lines of the description font are, with the same wrap width
-- as the description, so the measured lines match the description's own.
local function measureDescriptionHeight()
	local lines = {}
	for i = 1, inventorySettings.descriptionLines do
		lines[i] = "Ag"
	end

	local sample = display.newText({
		text = table.concat( lines, "\n" ),
		width = textWidth,
		font = settings.fonts.regular,
		fontSize = descriptionFontSize,
	} )
	local height = sample.height
	display.remove( sample )
	return height
end

-- The dim covers the whole screen under the panel, so no touch on or around the panel reaches the game behind it.
local function blockTouch()
	return true
end


-- Touching a slot moves the cursor there, the same as the arrow keys do.
local function touchSlot( event )
	if event.phase == "began" then
		cursorIndex = event.target.slotIndex
		refreshCursor()
	end
	return true
end

--------------------------------------------------------------------------------------
-- Public functions

-- Open the inventory and build the panel into parentGroup, which does not move with the camera.
-- status is an optional text shown at the right end of the title row, such as the player's money,
-- and onClose an optional function that runs once the panel closes.
function inventoryPanel.open( parentGroup, status, onClose )
	if overlay then
		return
	end

	closeHandler = onClose
	cursorIndex = 1
	heldIndex = nil

	descriptionHeight = descriptionHeight or measureDescriptionHeight()
	local infoHeight = descriptionTop + descriptionHeight + infoBottomGap
	local panelHeight = titleHeight + sectionGap + gridHeight + sectionGap + infoHeight + 2 * padding

	overlay = display.newGroup()
	parentGroup:insert( overlay )

	dim = display.newRect( overlay, 0, 0, 1, 1 )
	dim:setFillColor( 0, 0.55 )
	dim:addEventListener( "touch", blockTouch )
	inventoryPanel.resize()

	local panel = display.newRoundedRect( overlay, screen.centerX, screen.centerY, panelWidth, panelHeight, 16 )
	panel:setFillColor( 0.12, 0.12, 0.16 )
	panel.strokeWidth = 3
	panel:setStrokeColor( 0.4, 0.4, 0.5 )

	local panelLeft = screen.centerX - panelWidth * 0.5
	local panelTop = screen.centerY - panelHeight * 0.5

	display.newText({
		parent = overlay,
		text = "Inventory",
		x = screen.centerX,
		y = panelTop + padding + titleHeight * 0.5,
		font = settings.fonts.bold,
		fontSize = titleFontSize,
	} )

	statusText = display.newText({
		parent = overlay,
		text = status or "",
		x = panelLeft + panelWidth - padding,
		y = panelTop + padding + titleHeight * 0.5,
		font = settings.fonts.bold,
		fontSize = nameFontSize,
	} )
	statusText.anchorX = 1
	statusText:setFillColor( unpack( cursorColor ) )

	-- Work out the centre of every slot and draw the slot's background.
	local gridLeft = panelLeft + padding
	local gridTop = panelTop + padding + titleHeight + sectionGap
	slotPositions = {}

	for slotIndex = 1, slotCount do
		local column = ( slotIndex - 1 ) % columns
		local row = math.floor( ( slotIndex - 1 ) / columns )
		local centerX = gridLeft + column * ( slotSize + slotGap ) + slotSize * 0.5
		local centerY = gridTop + row * ( slotSize + slotGap ) + slotSize * 0.5
		slotPositions[slotIndex] = { x = centerX, y = centerY }

		local slotBackground = display.newRoundedRect( overlay, centerX, centerY, slotSize, slotSize, 8 )
		slotBackground:setFillColor( 0.18, 0.18, 0.24 )
		slotBackground.strokeWidth = 2
		slotBackground:setStrokeColor( 0.32, 0.32, 0.4 )
		slotBackground.slotIndex = slotIndex
		slotBackground:addEventListener( "touch", touchSlot )
	end

	-- The cursor is a coloured outline with a transparent fill around the selected slot.
	cursorFrame = display.newRoundedRect( overlay, slotPositions[cursorIndex].x, slotPositions[cursorIndex].y, slotSize + 8, slotSize + 8, 10 )
	cursorFrame:setFillColor( 0, 0 )
	cursorFrame.strokeWidth = 4
	cursorFrame:setStrokeColor( unpack( cursorColor ) )

	-- The info box below the grid.
	local infoTop = gridTop + gridHeight + sectionGap
	local infoBox = display.newRoundedRect( overlay, screen.centerX, infoTop + infoHeight * 0.5, gridWidth, infoHeight, 8 )
	infoBox:setFillColor( 0.08, 0.08, 0.11 )
	infoBox.strokeWidth = 2
	infoBox:setStrokeColor( 0.32, 0.32, 0.4 )

	nameText = display.newText({
		parent = overlay,
		text = "",
		x = gridLeft + infoInset,
		y = infoTop + nameTop,
		font = settings.fonts.bold,
		fontSize = nameFontSize,
		align = "left",
	} )
	nameText.anchorX = 0
	nameText.anchorY = 0
	nameText:setFillColor( unpack( cursorColor ) )

	descriptionText = display.newText({
		parent = overlay,
		text = "",
		x = gridLeft + infoInset,
		y = infoTop + descriptionTop,
		width = textWidth,
		font = settings.fonts.regular,
		fontSize = descriptionFontSize,
		align = "left",
	} )
	descriptionText.anchorX = 0
	descriptionText.anchorY = 0
	descriptionText:setFillColor( unpack( textNormal ) )

	refreshSlots()
	refreshCursor()
end


-- Stretch the dim over the screen after its size has changed. The panel stays on the screen's centre,
-- which a resize does not move.
function inventoryPanel.resize()
	if dim then
		dim.x, dim.y = screen.centerX, screen.centerY
		dim.width, dim.height = screen.width, screen.height
	end
end


function inventoryPanel.isOpen()
	return overlay ~= nil
end


-- Draw the slots and the info box again from the inventory's contents, after the game has added
-- or removed an item while the inventory is open. Does nothing while it is closed.
function inventoryPanel.refresh()
	if overlay then
		refreshSlots()
		refreshCursor()
	end
end


-- Change the text at the right end of the title row while the inventory is open.
function inventoryPanel.setStatus( status )
	if statusText then
		statusText.text = status or ""
	end
end


-- Handle key presses while the inventory is open: the arrow keys move the cursor, the
-- interact key picks up an item, puts it down or swaps two items, and the inventory key
-- closes the inventory.
function inventoryPanel.handleKey( action, phase )
	if phase ~= "down" then
		return
	end

	if action == "right" then
		cursorIndex = cursorIndex % slotCount + 1
		refreshCursor()

	elseif action == "left" then
		cursorIndex = ( cursorIndex - 2 ) % slotCount + 1
		refreshCursor()

	elseif action == "down" then
		cursorIndex = cursorIndex + columns
		if cursorIndex > slotCount then
			cursorIndex = cursorIndex - slotCount
		end
		refreshCursor()

	elseif action == "up" then
		cursorIndex = cursorIndex - columns
		if cursorIndex < 1 then
			cursorIndex = cursorIndex + slotCount
		end
		refreshCursor()

	elseif action == "interact" then
		if heldIndex then
			-- Put the held item down: in another slot the two items swap places,
			-- and in its own slot the item is simply put back.
			if heldIndex ~= cursorIndex then
				inventory.move( heldIndex, cursorIndex )
			end
			heldIndex = nil
			refreshSlots()
			refreshCursor()

		elseif inventory.getSlot( cursorIndex ) then
			-- Pick up the selected slot's item so it can be moved.
			heldIndex = cursorIndex
			refreshSlots()
		end

	elseif action == "inventory" then
		inventoryPanel.close()
	end
end


-- Close the panel. The onClose function given to inventoryPanel.open runs afterwards, unless
-- skipHandler is true: a scene that is being left closes with true, so the game it would
-- resume is not started again. Closing a panel that is not open does nothing.
function inventoryPanel.close( skipHandler )
	if not overlay then
		return
	end

	display.remove( overlay )
	overlay = nil
	dim = nil
	iconObjects = {}
	slotPositions = {}
	cursorFrame = nil
	nameText = nil
	descriptionText = nil
	statusText = nil
	heldIndex = nil

	-- The handler is cleared before it runs, so it runs once per opened panel and may open
	-- the panel again.
	local onClose = closeHandler
	closeHandler = nil

	if onClose and not skipHandler then
		onClose()
	end
end

--------------------------------------------------------------------------------------

return inventoryPanel
