-- Item data for the inventory. Each item has a display name, a short description and its frame
-- in the item image sheet, inventory.itemSheet in data/settingsTemplate.lua. The item id (the key)
-- is the name the map's item objects and the story's addItem and removeItem commands use.
-- An id must be a valid Lua identifier, because story conditions read it as $inventory.<id>.

return {
	parcel = {
		name = "Parcel",
		description = "A parcel found on the highest platform outside. Someone indoors is waiting for it.",
		frame = 1,
	},
}
