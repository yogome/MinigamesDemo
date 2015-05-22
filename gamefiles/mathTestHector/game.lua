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
local answersLayer, answersGroup
local backgroundLayer, backgroundImg
local operationLayer, operationGroup
local textLayer, instructions, instructionsBg
local manager
local tapsEnabled
--local isFirstTime
local sheetAnswers
local operationType
local firstOperandVal, secondOperandVal, result
local resultImg 
local equalOperator, operator
local answers, totalAnswers
local initPosX, initPosY
local paddingAnswers
----------------------------------------------- Constants
local SIZE_BOXES = 100
local FONT_SIZE = display.contentCenterY * 0.6
local COLOR_CORRECT = colors.green
local TOTAL_OP_ELEMENTS = 6
local PADDING_X_OPERATION = (display.contentWidth / TOTAL_OP_ELEMENTS)
local POS_X_RESULT = PADDING_X_OPERATION * 5
local POS_Y_RESULT = display.contentCenterY * 0.70
local OFFSET_Y_WRONG_ANSWERS = display.contentHeight * 0.30
local FIRST_ROW_FACTOR = 0.8
local SECOND_ROW_FACTOR = 1.2
local SCALE_OPERATOR = 0.8
local SCALE_BACKGROUND = 1.5
local TIME_BOX_ANIMATION = 400
local TEXT_POSX = display.contentCenterY * 0.11
local TEXT_POSY = native.systemFontBold, display.contentCenterY * 0.13
----------------------------------------------- Functions
local function onAnswerTouched(event)
	if event.phase == "began" then
		event.target:toFront()
        event.target.markX = event.target.x   
        event.target.markY = event.target.y   
		initPosX = event.target.x
		initPosY = event.target.y
    elseif event.phase == "moved" then
        local x = (event.x - event.xStart) + event.target.markX
        local y = (event.y - event.yStart) + event.target.markY
        event.target.x, event.target.y = x, y   
	elseif event.phase == "ended" then
		if event.target.isCorrect == true and (event.target.x > (POS_X_RESULT - resultImg.width) and event.target.x < (POS_X_RESULT + resultImg.width)) and (event.target.y > (POS_Y_RESULT - resultImg.height) and event.target.y < (POS_Y_RESULT + resultImg.height)) then
			event.target.x, event.target.y = POS_X_RESULT, POS_Y_RESULT
			if manager then 
				manager.correct()
			end
		elseif event.target.isCorrect == false and (event.target.x > (POS_X_RESULT - resultImg.width) and event.target.x < (POS_X_RESULT + resultImg.width)) and (event.target.y > (POS_Y_RESULT - resultImg.height) and event.target.y < (POS_Y_RESULT + resultImg.height)) then
			event.target.x, event.target.y = POS_X_RESULT, POS_Y_RESULT
			if manager then 
				local correctGroup = display.newGroup() 
				correctGroup.isVisible = false
				local box = display.newRect(0, 0, SIZE_BOXES, SIZE_BOXES)
				box:setFillColor(unpack(COLOR_CORRECT))
				correctGroup:insert(box)
				manager.wrong({id = "group", group = correctGroup}) 
			end
		else
			transition.to(event.target, {time = TIME_BOX_ANIMATION, x = initPosX, y = initPosY, transition = easing.outQuad})
		end
	end
    return true
end

local function drawOperationElements(value, positionX)
	if value == 1 then
		local element = display.newImage(assetPath.."sandia.png",positionX,POS_Y_RESULT)
		element.xScale = 1.5
		element.yScale = 1.5
		operationGroup:insert(element)
	elseif value == 2 then
		local paddingElements = (display.contentWidth / TOTAL_OP_ELEMENTS)
		local elementFirstRow = display.newImage(assetPath.."sandia.png", positionX - paddingElements / 3, POS_Y_RESULT)
		local elementSecondRow = display.newImage(assetPath.."sandia.png", positionX + paddingElements / 3, POS_Y_RESULT)
		operationGroup:insert(elementFirstRow)
		operationGroup:insert(elementSecondRow)
	else
		local firstRowElements = value / 2 + value % 2
		local secondRowElements = firstRowElements - value % 2
		local firstRowPaddingElements = PADDING_X_OPERATION / firstRowElements
		local secondRowPaddingElements = PADDING_X_OPERATION / secondRowElements
		for index = 1, firstRowElements do
			local element = display.newImage(assetPath.."sandia.png",positionX - (PADDING_X_OPERATION / 2) + ((index) * firstRowPaddingElements),POS_Y_RESULT * FIRST_ROW_FACTOR)
			element.xScale = 0.5
			element.yScale = 0.5
			operationGroup:insert(element)
		end
		for index = 1, secondRowElements do
			local element = display.newImage(assetPath.."sandia.png",positionX - (PADDING_X_OPERATION / 2) + ((index) * secondRowPaddingElements),POS_Y_RESULT * SECOND_ROW_FACTOR)
			element.xScale = 0.5
			element.yScale = 0.5
			operationGroup:insert(element)
		end
	end
end

local function removeDynamicAnswers()
	display.remove(answersGroup) 
	answersGroup = nil
end

local function createOperation()
	operationGroup = display.newGroup()
	operationLayer:insert(operationGroup)
	drawOperationElements(firstOperandVal, PADDING_X_OPERATION)
	drawOperationElements(secondOperandVal, PADDING_X_OPERATION * 3)
	operator = display.newText(""..operationType, PADDING_X_OPERATION * 2, POS_Y_RESULT * 0.9, native.systemFontBold, FONT_SIZE)
	equalOperator = display.newImage(assetPath.."igual.png", PADDING_X_OPERATION * 4, POS_Y_RESULT)
	equalOperator.xScale = SCALE_OPERATOR
	equalOperator.yScale = SCALE_OPERATOR
	resultImg = display.newImage(assetPath.."respuesta.png", POS_X_RESULT, POS_Y_RESULT)
	operationGroup:insert(operator)
	operationGroup:insert(equalOperator)
	operationGroup:insert(resultImg)
end

local function createDynamicAnswers()
	removeDynamicAnswers() 
	answersGroup = display.newGroup() 
	answersLayer:insert(answersGroup) 
	local startX = display.contentWidth / (totalAnswers + 1)
	for index = 1, totalAnswers do
		local answerBox = display.newImage(sheetAnswers, answers[index], startX * index, display.contentCenterY + OFFSET_Y_WRONG_ANSWERS)
		local finalScale
		if totalAnswers < 4 then
			finalScale = 0.75
		else
			finalScale = 0.5
		end
		answerBox.xScale = finalScale
		answerBox.yScale = finalScale
		if answers[index] == result then
			answerBox.isCorrect = true
		else
			answerBox.isCorrect = false
		end
		answerBox:addEventListener("touch", onAnswerTouched)
		answersGroup:insert(answerBox)
	end
end

local function initialize(event)
	event = event or {} 
	local params = event.params or {} 
	manager = event.parent 
	local operation = params.operation 
	local wrongAnswers = params.wrongAnswers
	answers = wrongAnswers	
	table.insert(answers,2,operation.result)
	firstOperandVal = operation.operands[1]
	secondOperandVal = operation.operands[2]
	operationType = operation.operand
	result = operation.result
	totalAnswers = #answers
	paddingAnswers = display.contentWidth / totalAnswers
	instructions.text = localization.getString("testMinigameHectorInstructions")
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
	backgroundImg = display.newImage(assetPath.."fondo.png",display.contentCenterX,display.contentCenterY)
	backgroundImg.xScale = 1.3
	backgroundImg.yScale = backgroundImg.xScale
	backgroundLayer:insert(backgroundImg)
	answersLayer = display.newGroup()
	sceneView:insert(answersLayer)
	textLayer = display.newGroup()
	sceneView:insert(textLayer)
	operationLayer = display.newGroup()
	sceneView:insert(operationLayer)
	local optionFrame =
	{
		frames =
		{
			--frame 1
			{
				x = 45,
				y = 64,
				width = 290,
				height = 290
			},
			--frame 2
			{    
				x = 345,
				y = 64,
				width = 290,
				height = 290
			},
			--frame 3
			{
				x = 640,
				y = 64,
				width = 290,
				height = 290
			},
			--frame 4
			{    
				x = 50,
				y = 370,
				width = 290,
				height = 290
			},
			--frame 5
			{
				x = 345,
				y = 370,
				width = 290,
				height = 290
			},
			--frame 6
			{    
				x = 640,
				y = 368,
				width = 290,
				height = 290
			},
			--frame 7
			{
				x = 50,
				y = 677,
				width = 290,
				height = 290
			},
			--frame 8
			{    
				x = 345,
				y = 675,
				width = 290,
				height = 290
			},
			--frame 9
			{
				x = 640,
				y = 675,
				width = 290,
				height = 290
			}
		}	
	}
	sheetAnswers = graphics.newImageSheet( assetPath.."acomodo de frutas.png", optionFrame )
	instructionsBg = display.newImage(assetPath.."instruccion.png",display.contentCenterX,display.contentCenterY * 0.12)
	instructionsBg.xScale = SCALE_BACKGROUND 
	instructions = display.newText("", display.contentCenterX, TEXT_POSX, TEXT_POSY)
	textLayer:insert(instructionsBg)
	textLayer:insert(instructions)	
	
end

function game:destroy() 
	
end


function game:show( event ) 
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then 
		initialize(event)
		createOperation()
		createDynamicAnswers()
		answersLayer:toFront()
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

-----  ------------------------------------------ Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game
