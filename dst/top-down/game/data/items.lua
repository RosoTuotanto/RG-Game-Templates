-- Item data for the inventory. Each item has a display name, a short description and its frame
-- in the item image sheet, inventory.itemSheet in data/settingsTemplate.lua. The item id (the key)
-- is the name the map's item objects and the story's addItem and removeItem commands use.
-- An id must be a valid Lua identifier, because story conditions read it as $inventory.<id>.

return {
	parcel = {
		name = "Parcel",
		description = "An item picked up from the map. The guide's dialogue asks for it.",
		frame = 1,
	},

	key = {
		name = "Key",
		description = "An item the story gave with the addItem command.",
		frame = 2,
	},

	note = {
		name = "Note",
		description = "A starting item. Starting items are set in inventory.startingItems in data/settingsTemplate.lua.",
		frame = 3,
	},
}
