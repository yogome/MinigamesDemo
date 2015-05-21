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
--local gameTutorial
local backgroundImage
local instructionImage
--local wrongAnswers, correctAnswer
local firstNumberLayout, secondNumberLayout, operation, equals, answer
local number1, number2, result
local answer_box1, answer_box2, answer_box3

----------------------------------------------- Constants
--local OFFSET_X_ANSWERS = 200
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
local BOXES = 3
--local BOX_IMG_SIZE = 200
local BOX_IMG_POSY = 225
--local BOX_SPACING_PADDING =  385
local PADDING_ANSWERS = 300
--local FRUIT_SIZE = 75
--local OPERATION_SPACE = 5
--local OPERATION_PADDING = 200
local TABLES = {
	[1] = { {1} },
	[2] = { {1,1} },
	[3] = { {1,0,0} , 
			{0,1,0} , 
			{0,0,1} },
	[4] = { {1,1} , 
			{1,1} },
	[5] = { {1,0,1} , 
			{0,1,0} , 
			{1,0,1} },
	[6] = { {1,1,1} , 
			{1,1,1} },
	[7] = { {0,1,0} , 
			{1,0,0} , 
			{0,1,0} , 
			{1,0,1} , 
			{0,1,0} },
	[8] = { {1,0,1} , 
			{0,1,0} , 
			{1,0,1} , 
			{0,1,0} , 
			{1,0,1} },
	[9] = { {1,1,1} , 
			{1,1,1} , 
			{1,1,1} },
}

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

local function onTouchBox( event )
	local object = event.target

	if event.phase == "began" then
		object.markX = object.x
		object.markY = object.y
		display.getCurrentStage():setFocus( object )
	elseif event.phase == "moved" then 
		local x = (event.x - event.xStart) + object.markX
		local y = (event.y - event.yStart) + object.markY
		
		object.x, object.y = x, y
	
	elseif event.phase == "ended" then
		if object.numChildren - 1 == result then 
			object.x = answer.x
			object.y = answer.y
			
			if manager then 
				manager.correct()
			end
		else
			object.x, object.y = object.markX, object.markY
		end
		
		display.getCurrentStage():setFocus(nil)
	end
	return true
end

local function fruitNumber()
	local num1, num2
	
	num1 = math.random(5)
	
	if num1 == 5 then
		num2 = math.random(4)
	else
		num2 = math.random(5)
	end
	
	return num1,num2
end

local function boxImage()
	local boxImage = display.newImage( assetPath.."cajadefrutas.png")
	return boxImage
end

local function addFruit( num , num_Group )
	for index = 1, num do
		local sandia = display.newImage( assetPath.."sandia.png" ) 
		sandia:scale(0.5,0.5) 
		num_Group:insert( sandia )
		print("addfruit "..num)
	end
end

local function createBoxes( num , num_Group1 ,num_Group2 ,num_Group3)
	local totalWidth = (BOXES - 1) * PADDING_ANSWERS
	local startX = display.contentCenterX - totalWidth * 0.5
	local correctAnswer = math.random( 3 )
	local object
	
	print("correctAnswer "..correctAnswer)
	for boxIndex = 1, BOXES do	
		if boxIndex == 1 then
			object = boxImage(num_Group1)
			num_Group1:insert(object)
			num_Group1.x = startX + (boxIndex - 1) * PADDING_ANSWERS
			num_Group1.y = display.contentCenterY + BOX_IMG_POSY
			num_Group1:addEventListener("touch", onTouchBox)
			
			if correctAnswer == 1 then
				addFruit( num , num_Group1 )
			else
				local wrongNumber1 = math.random(9)
				while wrongNumber1 == num do
					wrongNumber1 = math.random(9)
				end
				addFruit( wrongNumber1 , num_Group1 )
			end
		elseif boxIndex == 2 then
			object = boxImage(num_Group2)
			num_Group2:insert(object)
			num_Group2.x = startX + (boxIndex - 1) * PADDING_ANSWERS
			num_Group2.y = display.contentCenterY + BOX_IMG_POSY
			num_Group2:addEventListener("touch", onTouchBox)
			
			if correctAnswer == 2 then
				addFruit( num , num_Group2 )
			else
				local wrongNumber2 = math.random(9)
				while wrongNumber2 == num do
					wrongNumber2 = math.random(9)
				end
				addFruit( wrongNumber2 , num_Group2 )
			end
		elseif boxIndex == 3 then
			object = boxImage(num_Group3)
			num_Group3:insert(object)
			num_Group3.x = startX + (boxIndex - 1) * PADDING_ANSWERS
			num_Group3.y = display.contentCenterY + BOX_IMG_POSY
			num_Group3:addEventListener("touch", onTouchBox)
			
			if correctAnswer == 3 then
				addFruit( num , num_Group3 )
			else
				local wrongNumber3 = math.random(9)
				while wrongNumber3 == num do
					wrongNumber3 = math.random(9)
				end
				addFruit( wrongNumber3 , num_Group3 )
			end
		end
	end
end

local function problemLayout( sceneView )
	firstNumberLayout = display.newGroup()
	sceneView:insert( firstNumberLayout)
	firstNumberLayout.x = display.contentCenterX + -450
	firstNumberLayout.y = display.contentCenterY - 125

	operation = display.newImage( assetPath.."suma.png", firstNumberLayout.x + 225, firstNumberLayout.y, 200, 200 )
	sceneView:insert( operation )
	
	secondNumberLayout = display.newGroup()
	sceneView:insert( secondNumberLayout )
	secondNumberLayout.x = operation.x + 225
	secondNumberLayout.y = operation.y
	
	equals = display.newImage( assetPath.."igual.png", secondNumberLayout.x + 225, secondNumberLayout.y, 200, 200 )
	sceneView:insert( equals )
	
	answer = display.newImage( assetPath.."respuesta.png", equals.x + 225, equals.y, 200, 200 )
	sceneView:insert( answer )
	
	answer_box1 = display.newGroup()
	sceneView:insert( answer_box1 )
	
	answer_box2 = display.newGroup()
	sceneView:insert( answer_box2 )
	
	answer_box3 = display.newGroup()
	sceneView:insert( answer_box3 )
	
	number1,number2 = fruitNumber()
	
	print("Numbers"..number1.." "..number2)
	
	addFruit( number1 , firstNumberLayout )
	addFruit( number2 , secondNumberLayout )
	
	result = number1 + number2
	
	print("result"..result)
	
	createBoxes( result, answer_box1, answer_box2, answer_box3)
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

function game:create( event ) 
	local sceneView = self.view
	
	backgroundLayer = display.newGroup() 
	sceneView:insert(backgroundLayer)
	
	answersLayer = display.newGroup()
	sceneView:insert( answersLayer )
	
	textLayer = display.newGroup()
	sceneView:insert( textLayer )
	
	backgroundImage = display.newImage( assetPath.."fondo.png", display.contentCenterX, display.contentCenterY )
	backgroundImage.xScale = SCALE_BGX
	backgroundLayer:insert( backgroundImage )
	
	instructionImage = display.newImage ( assetPath.."instruccion.png", display.contentCenterX + OFFSET_TEXT.x, display.contentCenterY + OFFSET_TEXT.y )
	instructionImage.xScale = SCALE_IBI
	instructionImage.yScale = SCALE_IBI
	backgroundLayer:insert( instructionImage )
	
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
		problemLayout( sceneView ) 
	elseif phase == "did" then 
		--enableButtons()
	end
end

function game:hide( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then 
		display.remove(firstNumberLayout)
		firstNumberLayout = nil
		
		display.remove(secondNumberLayout)
		secondNumberLayout = nil
		
		display.remove(answer_box1)
		answer_box1 = nil
		
		display.remove(answer_box2)
		answer_box2 = nil
		
		display.remove(answer_box3)
		answer_box3 = nil
		
	elseif phase == "did" then 
		
		--disableButtons()
		--transition.cancel(scenePath)
	end
end

----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game

