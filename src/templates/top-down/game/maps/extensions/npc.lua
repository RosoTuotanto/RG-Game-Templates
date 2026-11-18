-- PonyTiled extension for the map's "npc" objects. PonyTiled calls npcExtension.new for each
-- such object and passes it the Tiled object. The extension removes it and builds an NPC in its place.

local npcExtension = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local animations = require( "data.animations" )

--------------------------------------------------------------------------------------
-- Public functions

function npcExtension.new( instance )
	-- Take the details that PonyTiled copied from the Tiled object.
	local parentLayer = instance.parent
	local x, y = instance.x, instance.y

	-- frame is the image sheet frame to draw. node is the name of the dialogue passage the
	-- NPC starts when the player talks to it (background characters have no node).
	-- ignoreInteract true means the interact key never acts on the NPC.
	local frame = instance.frame or 1
	local name = instance.name
	local node = instance.node
	local ignoreInteract = instance.ignoreInteract

	-- Remove the placeholder object that Tiled created. We build our own in its place.
	display.remove( instance )

	local sheetData = animations.characterSheet
	local characterSheet = graphics.newImageSheet( sheetData.filename, sheetData.options )

	-- Build the NPC like the hero: a group on the NPC's feet, so the NPC sorts and collides by
	-- its feet, with the picture from the right frame standing on the group's position.
	local npc = display.newGroup()
	local picture = display.newImageRect( npc, characterSheet, frame, sheetData.options.width, sheetData.options.height )
	picture.anchorY = sheetData.feetY / sheetData.options.height

	-- The group's anchor only feeds the map's sort, so the NPC sorts by its feet like the hero.
	npc.anchorY = 1

	parentLayer:insert( npc )
	npc.x, npc.y = x, y

	npc.name = name
	npc.type = "npc"

	-- Keep the dialogue passage's name, so the talking code can find it later.
	npc.node = node
	npc.ignoreInteract = ignoreInteract

	-- A static round physics body stops the player from walking through the NPC. The interact key
	-- reads its radius from bodyRadius to find the edge of the body.
	npc.bodyRadius = 24
	physics.addBody( npc, "static", { radius = npc.bodyRadius } )

	-- The resting y position that the bounce always returns to.
	npc.baseY = y

	-- A small hop as feedback when the player talks to the NPC: lift it for a moment
	-- and drop it back to its resting position.
	function npc:bounce()
		transition.cancel( self )
		self.y = self.baseY

		transition.to( self, {
			time = animations.npcBounce.upTime,
			y = self.baseY - animations.npcBounce.height,
			transition = easing.outQuad,
			onComplete = function()
				transition.to( self, { time = animations.npcBounce.downTime, y = self.baseY, transition = easing.inQuad } )
			end,
		} )
	end

	-- Cancel a bounce in progress when the NPC is removed on a map change.
	function npc:finalize()
		transition.cancel( self )
	end

	npc:addEventListener( "finalize" )

	return npc
end

return npcExtension
