-- Item data for the inventory. Each item has a display name, a short description and its frame
-- in the item image sheet, inventory.itemSheet in data/settingsTemplate.lua. The item id (the key)
-- is the name the story's addItem and removeItem commands use.
-- An id must be a valid Lua identifier, because story conditions read it as $inventory.<id>.

return {
	badge = {
		name = "Badge",
		description = "A badge template-female gave you. She would like it back one day.",
		frame = 1,
	},
}
