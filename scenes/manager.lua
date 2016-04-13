------------------------------------------------ Test Menu
local scenePath = ...
local director = require("libs.helpers.director")

local manager = director.newScene()
----------------------------------------------- Variables
----------------------------------------------- Constants
----------------------------------------------- Functions
local function startManager(event)
	event = event or {}
	local parameters = event.params or {}
	
	local minigames = parameters.minigames or {}
	if minigames and #minigames >= 1 then
		local minigameRequire = require(minigames[1])
		
		if not minigameRequire.getInfo then
			error(tostring(minigames[1]).." is missing function .getInfo", 8)
		end
		
		local info = minigameRequire.getInfo()
		print(info.category)
		
		local generatedParameters = {
			category = "addition",
			operation = {
				operands = {3, 3},
				result = 6,
				operation = "3+3=6",
				operand = "+"
			},
			wrongAnswers = {2,3,4,5,7}
		}
		
		director.showOverlay(minigames[1], {isModal = true, effect = "fade", time = 500, params = generatedParameters})
	end
end
----------------------------------------------- Class functions
function manager.wrong(correctAnswer, options)
	options = options or {}
	director.hideOverlay("fade", 500)
	timer.performWithDelay(600, function()
		director.gotoScene("scenes.menu")
	end)
	print("Minigame ended with a wrong answer")
end

function manager.correct(options)
	options = options or {}
	director.hideOverlay("fade", 500)
	timer.performWithDelay(600, function()
		director.gotoScene("scenes.menu")
	end)
	print("Minigame ended with a correct answer")
end

function manager:create(event)
	local sceneView = manager.view
	
	local backgroundRect = display.newRect(display.contentCenterX, display.contentCenterY, display.viewableContentWidth, display.viewableContentHeight)
	backgroundRect:setFillColor(0.2, 0.2, 0.6)
	sceneView:insert(backgroundRect)
	
end

function manager:destroy()

end

function manager:show( event )
	if "will" == event.phase then
		display.setDefault("background",0,0,0)
		startManager(event)
	elseif "did" == event.phase then
	
	end
end

function manager:hide( event )
	if "did" == event.phase then

	end
end

manager:addEventListener( "create" )
manager:addEventListener( "destroy" )
manager:addEventListener( "hide" )
manager:addEventListener( "show" )

return manager
