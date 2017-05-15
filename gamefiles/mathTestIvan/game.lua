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
local answersLayer
local backgroundLayer
local textLayer, instructions
local manager
local isFirstTime
local backgroundImage
local instructionImage
local firstNumberLayout, secondNumberLayout, operation, equals, answer
local number1, number2, result
local answer_box1, answer_box2, answer_box3

----------------------------------------------- Constants
local OFFSET_TEXT = {x = 0, y = -300}
local SIZE_FONT = 40
local SCALE_BGX = 1.25
local SCALE_BGY = 1.1
local SCALE_IBI = 1.2
local BOXES = 3
local BOX_IMG_SIZE = 200
local BOX_IMG_POSY = 225
local PADDING_ANSWERS = 300
local OPERATION_PADDING = 200
local PROBLEM_LAYOUT_POSY = display.contentCenterY - 125

----------------------------------------------- Functions

local function initialize(event)
	event = event or {} 
	local params = event.params or {} 
	
	isFirstTime = params.isFirstTime 
	manager = event.parent 
	
	instructions.text = localization.getString("testMinigameIvanInstructions") 
end

local function onTouchBox( event )
	local object = event.target
	local answerPosX, answerPosY = answer.x, answer.y
	print("touch")
	
	if object.isTouchable then
		if event.phase == "began" then
			object.markX = object.x
			object.markY = object.y
			display.getCurrentStage():setFocus( object )
		elseif event.phase == "moved" then 
			local x = (event.x - event.xStart) + object.markX
			local y = (event.y - event.yStart) + object.markY

			object.x, object.y = x, y

		elseif event.phase == "ended" then
			local objPosX, objPosY = object.x, object.y
			local distanceToPointX, distanceToPointY = math.abs( answerPosX - objPosX ), math.abs( answerPosY - objPosY )

			if object.total == result and distanceToPointX < 100 and distanceToPointY < 100 then 
				object.x = answer.x
				object.y = answer.y

				if manager then 
					manager.correct()
				end
			else
				object.isTouchable = false
				director.to(scenePath, object,{ time = 500, x = object.markX, y = object.markY, onComplete = function () object.isTouchable = true end})
				display.getCurrentStage():setFocus(nil)
			end
		end
	end
	return true
end

local function onTapBox( event )
	print("tap")
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
	local startX = -65
	local startY = -60
	local totalSandia = 1
	
	num_Group.total = num
	
		for indexRow = 1, BOXES do
			for indexColumns = 1, BOXES do
				if totalSandia <= num then
					local sandia = display.newImage( assetPath.."sandia.png")
					sandia:scale(0.5,0.5) 
					sandia.x = startX
					sandia.y = startY
					num_Group:insert( sandia )
					startX = startX + sandia.contentWidth
					totalSandia = totalSandia + 1
					print("addfruit "..num)
				end
			end
			startX = -65
			startY = startY + 60
		end
end

local function createBoxes( num , num_Group1 ,num_Group2 ,num_Group3)
	local totalWidth = (BOXES - 1) * PADDING_ANSWERS
	local startX = display.contentCenterX - totalWidth * 0.5
	local correctAnswer = math.random( 3 )
	local object
	local wrongNumber1, wrongNumber2, wrongNumber3
	
	print("correctAnswer "..correctAnswer)
	for boxIndex = 1, BOXES do	
		if boxIndex == 1 then
			object = boxImage(num_Group1)
			num_Group1:insert(object)
			num_Group1.x = startX + (boxIndex - 1) * PADDING_ANSWERS
			num_Group1.y = display.contentCenterY + BOX_IMG_POSY
			num_Group1:addEventListener("touch", onTouchBox)
			num_Group1:addEventListener("tap", onTapBox)
			num_Group1.isTouchable = true
			
			if correctAnswer == 1 then
				addFruit( num , num_Group1 )
			else
				wrongNumber1 = math.random(9)
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
			num_Group2:addEventListener("tap", onTapBox)
			num_Group2.isTouchable = true
			
			if correctAnswer == 2 then
				addFruit( num , num_Group2 )
			else
				wrongNumber2 = math.random(9)
				while wrongNumber2 == num  or wrongNumber2 == wrongNumber1 do
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
			num_Group3:addEventListener("tap", onTapBox)
			num_Group3.isTouchable = true
			
			if correctAnswer == 3 then
				addFruit( num , num_Group3 )
			else
				wrongNumber3 = math.random(9)
				while wrongNumber3 == num or wrongNumber3 == wrongNumber1 or wrongNumber3 == wrongNumber2 do
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
	firstNumberLayout.x = display.contentCenterX + -400
	firstNumberLayout.y = PROBLEM_LAYOUT_POSY

	operation = display.newImage( assetPath.."suma.png", firstNumberLayout.x + OPERATION_PADDING, PROBLEM_LAYOUT_POSY, BOX_IMG_SIZE, BOX_IMG_SIZE )
	sceneView:insert( operation )
	
	secondNumberLayout = display.newGroup()
	sceneView:insert( secondNumberLayout )
	secondNumberLayout.x = operation.x + OPERATION_PADDING
	secondNumberLayout.y = PROBLEM_LAYOUT_POSY
	
	equals = display.newImage( assetPath.."igual.png", secondNumberLayout.x + OPERATION_PADDING, PROBLEM_LAYOUT_POSY, BOX_IMG_SIZE, BOX_IMG_SIZE )
	sceneView:insert( equals )
	
	answer = display.newImage( assetPath.."respuesta.png", equals.x + OPERATION_PADDING, PROBLEM_LAYOUT_POSY, BOX_IMG_SIZE, BOX_IMG_SIZE )
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
	backgroundImage.yScale = SCALE_BGY
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
		initialize( event )
		problemLayout( sceneView )
	elseif phase == "did" then 
		
	end
end

function game:hide( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then 
		
	elseif phase == "did" then 
		display.remove( firstNumberLayout )
		firstNumberLayout = nil
		
		display.remove( secondNumberLayout )
		secondNumberLayout = nil
		
		display.remove( answer_box1 )
		answer_box1 = nil
		
		display.remove( answer_box2 )
		answer_box2 = nil
		
		display.remove( answer_box3 )
		answer_box3 = nil
	end
end

----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game

