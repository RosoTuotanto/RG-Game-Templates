-- Merged game settings: data/settingsCore.lua overridden by data/settingsTemplate.lua.
--
-- Merge rules:
--   1. If both sides have a key-value table (a "map"), they merge per key.
--   2. If either side is an array-style table (a "list", i.e. it has a value
--      at index 1), the override replaces the core value wholesale.
--   3. Any non-table value replaces the core value.
--
-- Rule 2 exists because merging lists per index produces nonsense: a template
-- must be able to replace e.g. the whole menu button list or controls list.

local settingsCore = require("data.settingsCore")
local settingsTemplate = require("data.settingsTemplate")

local function isList( t )
	return t[1] ~= nil
end

local function deepMerge( base, override )
	for key, value in pairs( override ) do
		if type( value ) == "table" and type( base[key] ) == "table" and not isList( value ) and not isList( base[key] ) then
			deepMerge( base[key], value )
		else
			base[key] = value
		end
	end
	return base
end

return deepMerge( settingsCore, settingsTemplate )
