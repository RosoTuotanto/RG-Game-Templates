-- Composer's gotoScene to the current scene runs its hide and show events again but keeps
-- its view, so create does not run and the scene is not rebuilt. Game-to-game transitions
-- route through this scene: it removes the previous scene and immediately re-enters it
-- with the same params, so the scene is created anew.

local composer = require("composer")
local scene = composer.newScene()

---------------------------------------------------------------------------

local previousScene

function scene:show( event )
	if event.phase == "will" then
		-- Read the name on every visit: Composer keeps this module loaded, so a value read once would go stale.
		previousScene = composer.getSceneName( "previous" )
		composer.removeScene( previousScene )
	elseif event.phase == "did" then
		composer.gotoScene( previousScene, { params = event.params } )
	end
end

---------------------------------------------------------------------------

scene:addEventListener( "show", scene )

---------------------------------------------------------------------------

return scene
