-- An item lying on the map, built from an "item" object on the map's objects layer. The hero
-- picks it up by touching it.

local item = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local physics = require( "physics" )
local settings = require( "libs.settings" )
local inventory = require( "classes.inventory" )

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local itemSize = settings.platformer.item.size

--------------------------------------------------------------------------------------
-- Public functions

-- Build the item in the given layer, resting on the object's bottom edge. The object's item
-- property is the item's id in data/items.lua and frame its frame in the item sheet. An item
-- already picked up is not built again, so it stays gone when the hero comes back to the area.
-- Returns nil then.
function item.new( parent, object )
	if inventory.isCollected( object.name ) then
		return nil
	end

	local pickup = display.newImageRect( parent, inventory.getItemSheet(), object.frame or 1, itemSize, itemSize )
	pickup.x = object.x
	pickup.y = object.y + object.height * 0.5 - itemSize * 0.5
	pickup.id = "item"
	pickup.name = object.name
	pickup.item = object.item

	-- A sensor reports the touch without stopping the hero.
	physics.addBody( pickup, "static", { isSensor = true } )

	local isTaken = false

	-- Put the item in the inventory and mark it picked up. Returns true when it fit, and false
	-- when the inventory was full, which leaves the item on the map. Physics does not allow
	-- removing a body during a collision, so the item is hidden now and removed on the next frame.
	function pickup:take()
		if isTaken or not inventory.add( self.item ) then
			return false
		end

		isTaken = true
		inventory.markCollected( self.name )
		self.isVisible = false

		timer.performWithDelay( 1, function()
			display.remove( self )
		end, "game" )

		return true
	end

	return pickup
end

return item
