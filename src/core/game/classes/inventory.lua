-- The player's inventory and the record of items already picked up.
-- This module lives outside the game scene, so its state is kept even when the
-- game scene is rebuilt from scratch on every map change.

local inventory = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local settings = require( "libs.settings" )

--------------------------------------------------------------------------------------
-- Forward declarations & variables

-- The inventory is a grid with a fixed number of slots. The slots use string keys
-- (slots["1"] = "note"), because a Lua list with gaps between its entries does not
-- survive a json.encode and json.decode round trip intact. A table with string keys
-- always becomes a JSON object, which decodes back unchanged.
inventory.slotCount = settings.inventory.columns * settings.inventory.rows
inventory.slots = {}

-- The record of picked up items: collected[mapName][objectName] = true.
-- An item that has been picked up once does not reappear when we return to its map.
local collected = {}

-- The current map. The game scene sets it before building the map, so that the
-- item extension knows which map a pickup belongs to.
local currentMap

-- The item image sheet, built the first time something draws an item.
local itemSheet

--------------------------------------------------------------------------------------
-- Private functions

-- Find the first free slot and return its string key, or nil if every slot is taken.
local function firstFreeSlot()
	for slotIndex = 1, inventory.slotCount do
		local key = tostring( slotIndex )
		if not inventory.slots[key] then
			return key
		end
	end
	return nil
end

--------------------------------------------------------------------------------------
-- Public functions

-- Return the item image sheet from the settings. Every item icon draws from it, by the frame
-- that data/items.lua gives the item.
function inventory.getItemSheet()
	if not itemSheet then
		local sheetSettings = settings.inventory.itemSheet
		itemSheet = graphics.newImageSheet( sheetSettings.filename, {
			width = sheetSettings.frameWidth,
			height = sheetSettings.frameHeight,
			numFrames = sheetSettings.frameCount,
		} )
	end
	return itemSheet
end


-- Tell the inventory which map is being built.
function inventory.setMap( mapName )
	currentMap = mapName
	collected[mapName] = collected[mapName] or {}
end


-- Add an item to the first free slot. Returns true if the item fit and false if every
-- slot was full, so the caller can leave the item on the map when there is no room.
function inventory.add( itemId )
	local key = firstFreeSlot()
	if key then
		inventory.slots[key] = itemId
		return true
	end
	return false
end


-- Add the starting items from the settings. They show right away how the
-- inventory and moving items around work.
function inventory.addStartingItems()
	local startingItems = settings.inventory.startingItems
	for i = 1, #startingItems do
		inventory.add( startingItems[i] )
	end
end


-- Return the item in the given slot, or nil if the slot is empty.
function inventory.getSlot( slotIndex )
	return inventory.slots[tostring( slotIndex )]
end


-- Move an item from one slot to another. If the target slot is taken, the two items
-- swap places. The inventory panel calls this when the player rearranges items.
function inventory.move( fromSlot, toSlot )
	local fromKey = tostring( fromSlot )
	local toKey = tostring( toSlot )
	inventory.slots[fromKey], inventory.slots[toKey] = inventory.slots[toKey], inventory.slots[fromKey]
end


function inventory.has( itemId )
	for slotIndex = 1, inventory.slotCount do
		if inventory.slots[tostring( slotIndex )] == itemId then
			return true
		end
	end
	return false
end


-- Return a table with the id of every item in the inventory as a key with the value true.
-- The dialogue gives it to the story as $inventory, so <<if $inventory.parcel>> is true while
-- the parcel is held. An item that is not held has no key, so its condition counts as false.
function inventory.getHeldItems()
	local heldItems = {}
	for _, itemId in pairs( inventory.slots ) do
		heldItems[itemId] = true
	end
	return heldItems
end


-- Remove an item, for example when it is handed over to an NPC. Its slot is left empty.
function inventory.remove( itemId )
	for slotIndex = 1, inventory.slotCount do
		local key = tostring( slotIndex )
		if inventory.slots[key] == itemId then
			inventory.slots[key] = nil
			return
		end
	end
end


-- Mark an object on the current map as picked up.
function inventory.markCollected( objectName )
	collected[currentMap][objectName] = true
end


function inventory.isCollected( objectName )
	return collected[currentMap] and collected[currentMap][objectName] == true
end


-- Return the pickup record, so that the game's save can store it.
function inventory.getCollected()
	return collected
end


-- Restore a saved state: the slots and the pickup record. This is used when a game is
-- continued from a save. The slots were saved with string keys, so they come back intact.
function inventory.restore( savedSlots, savedCollected )
	inventory.slots = savedSlots or {}
	collected = savedCollected or {}
end


-- Empty the inventory and the pickup record. Starting a new game calls this, so that
-- the items from the previous game are not kept.
function inventory.reset()
	inventory.slots = {}
	collected = {}
	currentMap = nil
end

--------------------------------------------------------------------------------------

return inventory
