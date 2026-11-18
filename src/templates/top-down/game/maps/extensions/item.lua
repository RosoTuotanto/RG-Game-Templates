-- PonyTiled extension for the map's "item" objects. PonyTiled calls itemExtension.new for each
-- such object and passes it the Tiled object. The extension removes it and builds the item in
-- its place, unless the item has already been picked up.

local itemExtension = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local inventory = require( "classes.inventory" )
local settings = require( "libs.settings" )

--------------------------------------------------------------------------------------
-- Public functions

function itemExtension.new( instance )
	-- Take the details that PonyTiled copied from the Tiled object.
	local parentLayer = instance.parent
	local x, y = instance.x, instance.y

	-- frame is the item image sheet's frame, item is the item's id and name is the object's name.
	-- ignoreInteract true means the interact key never acts on the item.
	local frame = instance.frame or 1
	local itemId = instance.item
	local name = instance.name
	local ignoreInteract = instance.ignoreInteract

	-- Remove the placeholder object that Tiled created. We build our own in its place.
	display.remove( instance )

	-- An item that has already been picked up is not created again. This way an item
	-- does not reappear when we return to this map.
	if inventory.isCollected( name ) then
		return nil
	end

	-- Build the item from the right frame on the same layer as the Tiled object.
	local sheetSettings = settings.inventory.itemSheet
	local item = display.newImageRect( parentLayer, inventory.getItemSheet(), frame, sheetSettings.frameWidth, sheetSettings.frameHeight )
	item.x, item.y = x, y

	item.name = name
	item.type = "item"

	-- Keep the item's id for the inventory.
	item.item = itemId
	item.ignoreInteract = ignoreInteract

	-- A static round physics body stops the hero from walking over the item. The interact key
	-- reads its radius from bodyRadius to find the edge of the body.
	item.bodyRadius = 20
	physics.addBody( item, "static", { radius = item.bodyRadius } )

	-- Put the item in the inventory and remove it from the map. The record marks it as
	-- picked up, so it does not reappear when we return to this map. If the inventory is
	-- full, the item stays on the map and is not marked. Returns true when the item was
	-- picked up and false when the inventory was full.
	function item:pickup()
		if inventory.add( self.item ) then
			inventory.markCollected( self.name )
			display.remove( self )
			return true
		end

		return false
	end

	return item
end

return itemExtension
