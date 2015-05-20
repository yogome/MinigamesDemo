----------------------------------------------- Test minigame
local scenePath = ... 
local folder = scenePath:match("(.-)[^%.]+$") 
local assetPath = string.gsub(folder,"[%.]","/") 
local director = require( "libs.helpers.director" )
local colors = require( "libs.helpers.colors" )
local localization = require( "libs.helpers.localization" )
local settings = require( "settings" ) 

local game = director.newScene() 
----------------------------------------------- Variables
local answersLayer, wrongAnswersGroup
local backgroundLayer
local textLayer, instructions
local manager
local tapsEnabled
local isFirstTime
local correctBox, wrongBox
local gameTutorial
local backgroundImage
local instructionImage
----------------------------------------------- Constants
local OFFSET_X_ANSWERS = 200
local OFFSET_TEXT = {x = 0, y = -300}
local SIZE_BOXES = 100
local COLOR_WRONG = colors.red
local COLOR_CORRECT = colors.green
local WRONG_ANSWERS = 6
local SIZE_FONT = 40
local SCALE_BGX = 1.25
local SCALE_IBI = 1.2
local TIME_BOX_ANIMATION = 500
local INSTRUCTION_TEXT = "Arrastra la respuesta correcta"
local PADDING_WRONG_ANSWERS = 140
local OFFSET_Y_WRONG_ANSWERS = 200
----------------------------------------------- Functions
local function onAnswerTapped(event)
	local answer = event.target 
	if tapsEnabled then
		tapsEnabled = false 
		if answer.isCorrect then 
			if manager then 
				manager.correct()
			end
		else
			if manager then 
				local correctGroup = display.newGroup() 
				correctGroup.isVisible = false
				
				local box = display.newRect(0, 0, SIZE_BOXES, SIZE_BOXES)
				box:setFillColor(unpack(COLOR_CORRECT))
				correctGroup:insert(box)
				
				manager.wrong({id = "group", group = correctGroup}) 
			end
		end
	end
end

local function removeDynamicAnswers()
	display.remove(wrongAnswersGroup) 
	wrongAnswersGroup = nil
end

local function createDynamicAnswers()
	
	removeDynamicAnswers() 
	
	wrongAnswersGroup = display.newGroup() 
	answersLayer:insert(wrongAnswersGroup) 
	
	
	local totalWidth = (WRONG_ANSWERS - 1) * PADDING_WRONG_ANSWERS
	local startX = display.contentCenterX - totalWidth * 0.5 
	
	local function boxAnimation(box) 
		local originalY = box.y
		local targetY = originalY - 50
		transition.to(box, {tag = scenePath, time = TIME_BOX_ANIMATION, y = targetY, transition = easing.outQuad, onComplete = function()
			transition.to(box, {tag = scenePath, time = TIME_BOX_ANIMATION, y = originalY, transition = easing.inQuad, onComplete = function()
				boxAnimation(box)
			end})
		end})
	end
	
	for index = 1, WRONG_ANSWERS do
		local wrongBox = display.newRect(startX + (index - 1) * PADDING_WRONG_ANSWERS, display.contentCenterY + OFFSET_Y_WRONG_ANSWERS, SIZE_BOXES, SIZE_BOXES)
		wrongBox.isCorrect = false 
		wrongBox:addEventListener("tap", onAnswerTapped)
		wrongAnswersGroup:insert(wrongBox)
		wrongBox:setFillColor(unpack(COLOR_WRONG)) 
		boxAnimation(wrongBox)
	end
	
	transition.to(wrongAnswersGroup, {tag = scenePath, time = 20000, alpha = 0.2}) 
end

local function initialize(event)
	event = event or {} 
	local params = event.params or {} 
	
	isFirstTime = params.isFirstTime 
	manager = event.parent 
	
	local operation = params.operation 
	local wrongAnswers = params.wrongAnswers
	
	
	
	
	
	
	
	
	
	
	
	instructions.text = INSTRUCTION_TEXT 
end

local function enableButtons()
	tapsEnabled = true
end

local function disableButtons()
	tapsEnabled = false
end
----------------------------------------------- Module functions
function game.getInfo() 
	return {
		available = false, 
		correctDelay = 500, 
		wrongDelay = 500, 
		
		name = "Minigame tester", 
		category = "math", 
		subcategories = {"addition", "subtraction"}, 
		age = {min = 0, max = 99}, 
		grade = {min = 0, max = 99}, 
		gamemode = "findAnswer", 
		requires = { 
			{id = "operation", operands = 2, maxAnswer = 10, minAnswer = 1, maxOperand = 10, minOperand = 1},
			{id = "wrongAnswer", amount = 5},
		},
	}
end  

function game:create(event) 
	local sceneView = self.view
	
	
	
	backgroundLayer = display.newGroup() 
	sceneView:insert(backgroundLayer)
	
	answersLayer = display.newGroup()
	sceneView:insert(answersLayer)
	
	textLayer = display.newGroup()
	sceneView:insert(textLayer)
	
	backgroundImage = display.newImage( assetPath.."fondo.png", display.contentCenterX, display.contentCenterY )
	backgroundImage.xScale = SCALE_BGX
	backgroundLayer:insert( backgroundImage )
	
	instructionImage = display.newImage ( assetPath.."instruccion.png", display.contentCenterX + OFFSET_TEXT.x, display.contentCenterY + OFFSET_TEXT.y )
	instructionImage.xScale = SCALE_IBI
	instructionImage.yScale = SCALE_IBI
	backgroundLayer:insert( instructionImage )
	
	correctBox = display.newRect(display.contentCenterX + -OFFSET_X_ANSWERS, display.contentCenterY, SIZE_BOXES, SIZE_BOXES)
	correctBox.isCorrect = true 
	correctBox:setFillColor(unpack(COLOR_CORRECT))
	correctBox:addEventListener("tap", onAnswerTapped)
	answersLayer:insert(correctBox)
	
	wrongBox = display.newImageRect(assetPath.."ninja.png", SIZE_BOXES, SIZE_BOXES) 
	wrongBox.x, wrongBox.y = display.contentCenterX + OFFSET_X_ANSWERS, display.contentCenterY
	wrongBox.isCorrect = false
	wrongBox:setFillColor(unpack(COLOR_WRONG))
	wrongBox:addEventListener("tap", onAnswerTapped)
	answersLayer:insert(wrongBox)
	
	
	
	instructions = display.newText("", display.contentCenterX + OFFSET_TEXT.x, display.contentCenterY + OFFSET_TEXT.y, settings.fontName, SIZE_FONT)
	textLayer:insert(instructions)
	
end

function game:destroy() 
	
end


function game:show( event ) 
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then 
		initialize(event)
		createDynamicAnswers() 
	elseif phase == "did" then 
		enableButtons()
	end
end

function game:hide( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then 
		
	elseif phase == "did" then 
		
		disableButtons()
		removeDynamicAnswers()
		transition.cancel(scenePath)
	end
end

----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game

