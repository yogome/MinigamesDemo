----------------------------------------------- Requires
local scenePath = ... 
local folder = scenePath:match("(.-)[^%.]+$") 
local assetPath = string.gsub(folder,"[%.]","/") 
local director = require("libs.helpers.director")

local game = director.newScene() 
----------------------------------------------- Variables
local backgroundLayer, dynamicLayer
local backgroundGroup, dynamicGroup, conveyorLinesGroup, objectsGroup, dialogueGroup, objectsTouchGroup
local manager, isFirstTime, managerLevel, countNumberRounds, countWrongAnswers
local numObjectsConveyor, objectPositionList, tapsEnable, robot
----------------------------------------------- Constants
local GLOBAL_SCALE = display.contentHeight / 765
local GLOBAL_SCALE_Y = display.contentWidth / 1020
local VELOCITY_CONVEYOR = 0.30
local SPACE_LINES_CONVEYOR = 90
local SELECTED_SCALE = 1.15
local TOTAL_ROUNDS = 5
local MAX_WRONG_ROUNDS = 3

local IMAGE_DEVICES = {
	{img = "calculadora.png", question = "calculando.png"}, 
	{img = "cellphone.png", question = "selfie.png"},
	{img = "tablet.png", question = "tabletTouch.png"}, 
	{img = "laptop.png", question = "programando.png"}, 
	{img = "consola.png", question = "jugando.png"},
	{img = "cajero.png", question = "cajero02.png"}, 
	{img = "bascula.png", question = "pesandose.png"}
}
local IMAGE_DISTRACTIONS = {"patito.png", "licuadora.png", "maceta.png", "manzana.png", "lampara.png"}
----------------------------------------------- Caches
----------------------------------------------- Functions
local function cleanUp()
	transition.cancel("transitionConveyor")
	transition.cancel("transition")
		
	display.remove(backgroundGroup)
	backgroundGroup = nil
	
	display.remove(dynamicGroup)
	dynamicGroup = nil
end

local function finishRound()
	
	for indexGroup = objectsTouchGroup.numChildren, 1, -1 do
		display.remove(objectsTouchGroup[indexGroup])
	end
	
	objectsTouchGroup.x = 0
	
	for indexDialogue = dialogueGroup.numChildren, 1, -1 do
		display.remove(dialogueGroup[indexDialogue])
	end
	
	dialogueGroup.alpha = 1
	
	if countNumberRounds > TOTAL_ROUNDS then
		manager.correct()
	elseif countWrongAnswers < MAX_WRONG_ROUNDS then
		countNumberRounds = countNumberRounds + 1
		robot:playRound()
	else
		manager.wrong()
	end
end

local function evaluate(object)
	if object.x > robot.contentBounds.xMin and object.x < robot.contentBounds.xMax and
	object.y > robot.contentBounds.yMin and object.y < robot.contentBounds.yMax then
		local delayRightAnswer = 0
		
		if object ~= robot.rightAnswer then
			if managerLevel == 1 then
				object.x, object.y = object.originX, object.originY
			elseif managerLevel == 2 then 
				transition.to(object, {tag = "transition", time = 1000, x = object.originX, y = object.originY}) 
				robot.rightAnswer:toFront()
				transition.to(robot.rightAnswer, {tag = "transition", time = 1000, x = robot.x, y = robot.y}) 
				countWrongAnswers = countWrongAnswers + 1
				delayRightAnswer = 1000
			end
		end
		
		if (object.isAnswer and managerLevel == 1) or managerLevel == 2 then
			tapsEnable = false
			
			transition.to(robot.rightAnswer, {tag = "transition", delay = delayRightAnswer, time = 500, alpha = 0, onComplete = function()
				transition.resume("transitionConveyor")
				transition.to(dialogueGroup, {tag = "transition", time = 500, alpha = 0})
				transition.to(objectsTouchGroup, {tag = "transition", time = display.contentWidth/ VELOCITY_CONVEYOR, x = display.contentWidth, onComplete = finishRound})
			end})
		end
	else
		object.x, object.y = object.originX, object.originY
	end
end

local function touchFunction(event)
	local target = event.target
	local phase = event.phase
	
	if tapsEnable then
		if phase == "began" then
			target.isFocus = true 
			target:toFront()
			display.currentStage:setFocus(target)
			target.xScale, target.yScale  = target.xScale * SELECTED_SCALE, target.yScale * SELECTED_SCALE
			
		elseif target.isFocus then 
			if phase == "moved" then
				target.x, target.y = event.x, event.y
				
			elseif phase == "ended" then
				target.isFocus = false
				display.currentStage:setFocus(nil)
				target.xScale, target.yScale = target.xScale / SELECTED_SCALE, target.yScale / SELECTED_SCALE
				evaluate(target)
			end
		end
	end
	
	return true
end 

local function showQuestion(indexObject)
	if indexObject == numObjectsConveyor then
		transition.pause("transitionConveyor")
		
		local question = display.newImage(assetPath.. IMAGE_DEVICES[robot.chosenQuestion].question)
		question.alpha = 0
		question.xScale, question.yScale = GLOBAL_SCALE, GLOBAL_SCALE
		dialogueGroup:insert(question)
		
		local cuadros = display.newImage(assetPath.. "cuadritos.png")
		cuadros.alpha = 0
		cuadros.xScale, cuadros.yScale = GLOBAL_SCALE, GLOBAL_SCALE
		cuadros.x, cuadros.y = -question.contentWidth * 0.75, question.contentHeight * 0.75
		dialogueGroup:insert(cuadros)
		
		transition.to(cuadros, {tag = "transition", time = 300, alpha = 1, onComplete = function()
			transition.to(question, {tag = "transition", delay = 100, time = 300, alpha = 1, onComplete = function()
				tapsEnable = true
				
				for indexGroup = 1, objectsGroup.numChildren do
					objectsTouchGroup:insert(objectsGroup[1])
				end 
			end})
		end})
	end
end

local function isInList(number,numbersList)
	local answer = false
	
	for indexList = 1, #numbersList do
		if numbersList[indexList] == number then
			answer = true
		end
	end
	
	return answer
end

local function throwObjects()
	local numberRandom, timeDelay = 0, 0
	local positionInConveyor, alreadyChosen = {}, {}
	
	for indexCreate = 1, numObjectsConveyor do 
		repeat
			numberRandom = math.random(1, numObjectsConveyor)
		until not isInList(numberRandom, positionInConveyor)
		positionInConveyor[indexCreate] = numberRandom
	end
	
	for indexObject = 1, numObjectsConveyor do
		local object, objectPosition
		
		if indexObject == 1 then
			object = display.newImage(assetPath.. IMAGE_DEVICES[robot.chosenQuestion].img)
			objectsGroup:insert(object)
			table.insert(alreadyChosen, robot.chosenQuestion)
			robot.rightAnswer = object
		elseif indexObject == 2 then
				numberRandom = math.random(1, #IMAGE_DISTRACTIONS)
				object = display.newImage(assetPath.. IMAGE_DISTRACTIONS[numberRandom])
				objectsGroup:insert(object)
		else
			repeat
				numberRandom = math.random(1, #IMAGE_DEVICES)
			until not isInList(numberRandom, alreadyChosen)
			object = display.newImage(assetPath.. IMAGE_DEVICES[numberRandom].img)
			objectsGroup:insert(object)
			table.insert(alreadyChosen, numberRandom)
		end
		
		object.xScale, object.yScale = GLOBAL_SCALE * 0.8, GLOBAL_SCALE * 0.8
		object.x = objectsGroup.xTube
		objectPosition = positionInConveyor[indexObject]
		object.originX, object.originY = objectPositionList[objectPosition], conveyorLinesGroup.y - object.contentHeight * 0.25
		object:addEventListener("touch", touchFunction)
		
		timeDelay = ((objectPositionList[1] - objectPositionList[2]) / VELOCITY_CONVEYOR) * (objectPosition - 1)
		
		transition.to(object, {tag = "transition", delay = timeDelay, time = 400, y = object.originY, onComplete = function()
			local timeTransitionX = (objectPositionList[objectPosition] - object.x) / VELOCITY_CONVEYOR
			transition.to(object, {tag = "transition", time = timeTransitionX, x = objectPositionList[objectPosition], onComplete = function()
				showQuestion(objectPosition)
			end})
		end})
	end
end

local function	playRound()
	local chosenQuestion = math.random(1, #IMAGE_DEVICES)
	robot.chosenQuestion = chosenQuestion
	throwObjects()
end

local function createConveyor()
	local lineConveyor, numberLinesConveyor, xLines
	
	local conveyorBelt = display.newImage(assetPath.. "banda01.png")
	conveyorBelt.anchorY = 1
	conveyorBelt.xScale, conveyorBelt.yScale = GLOBAL_SCALE_Y, GLOBAL_SCALE
	conveyorBelt.x, conveyorBelt.y = display.contentCenterX, display.contentHeight
	dynamicGroup:insert(conveyorBelt)
	
	conveyorLinesGroup = display.newGroup()
	conveyorLinesGroup.y = conveyorBelt.y - conveyorBelt.contentHeight * 0.59
	dynamicGroup:insert(conveyorLinesGroup)
	
	numberLinesConveyor = display.contentWidth / SPACE_LINES_CONVEYOR + 2
	
	for indexLines = 1, numberLinesConveyor do
		lineConveyor = display.newImage(assetPath.. "banda02.png")
		
		if indexLines == 1 then
			xLines = -lineConveyor.contentWidth * GLOBAL_SCALE
		end
		
		lineConveyor.xScale, lineConveyor.yScale = GLOBAL_SCALE, GLOBAL_SCALE
		lineConveyor.x = xLines
		conveyorLinesGroup:insert(lineConveyor)
		xLines = xLines + SPACE_LINES_CONVEYOR
	end
	
	transition.to(conveyorLinesGroup, {tag = "transitionConveyor", time = SPACE_LINES_CONVEYOR / VELOCITY_CONVEYOR, x = conveyorLinesGroup.x + SPACE_LINES_CONVEYOR, iterations = -1})
end

local function createScene()
	robot = display.newImage(assetPath.. "yogotar.png")
	robot.xScale, robot.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	robot.playRound = playRound
	robot.x, robot.y = display.contentCenterX, 0.45 * display.contentHeight
	backgroundGroup:insert(robot)
	
	createConveyor() 
	
	local tubeBack = display.newImage(assetPath.. "tubo02.png")
	tubeBack.anchorX, tubeBack.anchorY = 0,0
	tubeBack.xScale, tubeBack.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	tubeBack.x = 0.01 * display.contentWidth
	dynamicGroup:insert(tubeBack)
	
	dialogueGroup = display.newGroup()
	dialogueGroup.x, dialogueGroup.y = robot.x + robot.contentWidth * 1.2, robot.y - robot.contentHeight * 0.5
	dynamicGroup:insert(dialogueGroup)
	
	objectsGroup = display.newGroup()
	objectsGroup.xTube = tubeBack.x + tubeBack.contentWidth * 0.44
	dynamicGroup:insert(objectsGroup)
	
	local tubeFront = display.newImage(assetPath.. "tubo01.png")
	tubeFront.anchorX, tubeFront.anchorY = 0,0
	tubeFront.xScale, tubeFront.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	tubeFront.x = tubeBack.x
	dynamicGroup:insert(tubeFront)
	
	objectsTouchGroup = display.newGroup()
	dynamicGroup:insert(objectsTouchGroup)
end

local function createGroups()
	backgroundGroup = display.newGroup()
	backgroundLayer:insert(backgroundGroup)
	
	dynamicGroup = display.newGroup()
	dynamicLayer:insert(dynamicGroup)
end

local function initialize(event)
	event = event or {} 
	local params = event.params or {}
    local sceneParams = params.sceneParams

	isFirstTime = params.isFirstTime 
	manager = event.parent 
	managerLevel = 2
	
	if managerLevel == 1 then 
		numObjectsConveyor = 2
	else
		numObjectsConveyor = 3
	end
	
	objectPositionList = {}
	
	for indexPosition = 1, numObjectsConveyor do
		objectPositionList[indexPosition] = display.contentWidth * (1 - (1 / (numObjectsConveyor + 1) * indexPosition))
	end
	
	countNumberRounds = 1
	countWrongAnswers = 0
	tapsEnable = false
	math.randomseed( os.time())
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
	
	dynamicLayer = display.newGroup() 
	sceneView:insert(dynamicLayer)
	
	local imageBackground = display.newImageRect(assetPath.. "fondo.png", display.contentWidth, display.contentHeight)
	imageBackground.x, imageBackground.y = display.contentCenterX, display.contentCenterY
	backgroundLayer:insert(imageBackground)
end

function game:show(event) 
	local sceneView = self.view
	local phase = event.phase
	
	if phase == "will" then 
		initialize(event)
		createGroups()
		createScene()
		robot:playRound()
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