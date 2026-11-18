local loadsave = {}

-- initGame stores the player's settings here as loadsave.userdata, so every file can read them.

local json = require( "json" )

-- Save data to a file in JSON format.
function loadsave.save( data, filename )
	-- Work out the full path of the file.
	local path = system.pathForFile( filename, system.DocumentsDirectory )
	local file, errorString = io.open( path, "w" )

	if not file then
		print( "File error: " .. errorString )
		return false
	else
		-- Write the data to the file in JSON format.
		file:write( json.prettify( json.encode( data ) ) )
		io.close( file )

		return true
	end
end

-- Read a JSON file and return its contents as a Lua table.
function loadsave.load( filename )
	-- Work out the full path of the file.
	local path = system.pathForFile( filename, system.DocumentsDirectory )
	local file = io.open( path, "r" )

	-- The file does not exist (for example, the game has not been saved yet). This is not
	-- an error, so quietly return nil and let the caller start from a clean slate.
	if not file then
		return nil
	end

	-- Read the file's contents and close the file.
	local contents = file:read( "*a" )
	io.close( file )

	-- json.decode returns nil for a corrupt file, so check the type of the result.
	-- pcall guards against unexpected errors too: the game does not crash, it gets nil.
	local success, data = pcall( json.decode, contents )
	if not success or type( data ) ~= "table" then
		print( "WARNING: failed to read save file \"" .. filename .. "\"." )
		return nil
	end

	return data
end

-- Delete a save file. Starting a new game uses this so that an old save
-- does not get in the way.
function loadsave.delete( filename )
	local path = system.pathForFile( filename, system.DocumentsDirectory )
	os.remove( path )
end

return loadsave
