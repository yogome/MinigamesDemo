----------------------------------------------- Requires
local scenePath = ... 
local folder = scenePath:match("(.-)[^%.]+$") 
local assetPath = string.gsub(folder,"[%.]","/") 
local director = require("libs.helpers.director")

local game = director.newScene() 
----------------------------------------------- Variables
local backgroundLayer 
local manager, isFirstTime
----------------------------------------------- Constants

----------------------------------------------- Caches

----------------------------------------------- Functions
local function cleanUp()
	
end

local function initialize(event)
	event = event or {} 
	local params = event.params or {}
    local sceneParams = params.sceneParams

	isFirstTime = params.isFirstTime 
	manager = event.parent 
end
----------------------------------------------- Module functions
function game.getInfo() 
	return {
		correctDelay = 500, 
		wrongDelay = 500, 
		name = "testMinigame", 
		category = "math", 
		subcategories = {"addition"}, 
		age = {min = 0, max = 99}, 
		grade = {min = 0, max = 99}, 
		gamemode = "findAnswer", 
		requires = {}
	}
end  

function game:create(event) 
	local sceneView = self.view
	
	backgroundLayer = display.newGroup() 
	sceneView:insert(backgroundLayer)
end

function game:show(event) 
	local sceneView = self.view
	local phase = event.phase
	
	if phase == "will" then 
		initialize(event)
	elseif phase == "did" then 
		
	end
end

function game:hide(event)
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then 
		
	elseif phase == "did" then 
		cleanUp()
	end
end

----------------------------------------------- Execution
game:addEventListener("create")
game:addEventListener("hide")
game:addEventListener("show")

return game