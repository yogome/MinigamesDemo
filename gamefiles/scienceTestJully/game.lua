----------------------------------------------- progBooleanCards - Boolean operations with cards
local scenePath = ... 
local folder = scenePath:match("(.-)[^%.]+$") 
local assetPath = string.gsub(folder,"[%.]","/") 
local director = require("libs.helpers.director")
local extratable = require("libs.helpers.extratable")

local game = director.newScene() 
----------------------------------------------- Caches
local mathRandom = math.random
local removeTable = table.remove
----------------------------------------------- Variables
local backgroundGroup, dynamicGroup, cardGroup, uiGroup, conditionsGroup, booleanConditionGroup
local correctAnswerTotal, minigameLevel, currentAttempt, cardsPlacedTable, correctCards, cardTable
local backgroundLayer, dynamicLayer, uiLayer
local handMoveImage, cardHandImage
local booleanConditionalRandom
local manager, isFirstTime
local tapsEnabled
local energyContainer
----------------------------------------------- Constants
local COLOR_TEXT_BOOLEAN_CONITION = {23 / 255, 85 / 255, 204 / 255}
local COLOR_NUBERS_RANDOM = {242 / 255, 56 / 255, 115 / 255}
local COLOR_END_TIME = {255 / 255, 109 / 255, 147 / 255}
local COLOR_STAR_TIME = {43 / 255, 179 / 255, 47 / 255}
local COLOR_CURRENT_TIMER = 1

local SCREEN_HEIGHT = display.viewableContentHeight
local SCREEN_WIDTH = display.viewableContentWidth
local GLOBAL_SCALE = display.contentHeight / 765
local CONTAINER_WIDTH = 71 * GLOBAL_SCALE
local CARD_WIDTH = 205 * GLOBAL_SCALE

local TAG_TRANSITION = "TransitionCard"
local TAG_TIMER = "Timer"

local LIMIT_START_TIME = 25000
local LIMIT_END_TIME = 5000
local TIME_CARD = 1000
local TIME_HAND = 300

local TOTAL_CORRECT_CARDS = 3
local BAR_ENERGY_VALUE = 423
local SECOND_VALUE = 2
local FIRTS_VALUE = 1
local TOTAL_TURN = 5

local CARD_NUMBERS = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
local CARD_COLOR_TABLE = {"azul", "rojo", "rosa", "verde"}
local CONDITION_VALUE = {"number", "color"}
local BOOLEAN_TEXT_TABLE = {"OR", "AND", "NOT"}

local LEVEL_DATA = {
	[1] = {numberCardTotal = 3, numberCardRow = 3, offsetCard = 30 * GLOBAL_SCALE, scaleCard = GLOBAL_SCALE},
	[2] = {numberCardTotal = 4, numberCardRow = 4, offsetCard = 30 * GLOBAL_SCALE, scaleCard = GLOBAL_SCALE},
	[3] = {numberCardTotal = 5, numberCardRow = 5, offsetCard = - 10 * GLOBAL_SCALE, scaleCard = GLOBAL_SCALE * 0.9}
}
local POSITION_CONDITION_TABLE = {
	[1] = {x = 140 * GLOBAL_SCALE, y = 100 * GLOBAL_SCALE},
	[2] = {x = -140 * GLOBAL_SCALE, y = 100 * GLOBAL_SCALE}
}
----------------------------------------------- Functions
local function hideConditionBoolean()
	for transitionIndex = 1, conditionsGroup.numChildren do
		transition.to(booleanConditionGroup[transitionIndex], {tag = TAG_TRANSITION, time = TIME_HAND, xScale = GLOBAL_SCALE * 0.1, yScale = GLOBAL_SCALE * 0.1})
		transition.to(conditionsGroup[transitionIndex], {tag = TAG_TRANSITION, time = TIME_HAND, xScale = GLOBAL_SCALE * 0.1, yScale = GLOBAL_SCALE * 0.1, onComplete = function()
			for booleanElementIndex = 1, booleanConditionGroup.numChildren do
				display.remove(booleanConditionGroup[FIRTS_VALUE])
			end
			for conditionsIndex = 1, conditionsGroup.numChildren do
				display.remove(conditionsGroup[FIRTS_VALUE])
			end
			handMoveImage.createBooleanCondition()
		end})
	end
end

local function fillBar()
	energyContainer.fillValue = energyContainer.fillValue + BAR_ENERGY_VALUE * 0.34
	transition.to(energyContainer, {width = energyContainer.fillValue, onComplete = function()
		if correctAnswerTotal ~= TOTAL_CORRECT_CARDS then
			hideConditionBoolean()
		else
			manager.correct()
		end
	end})
end

local function delayCardGroup()
	for cardElementIndex = 1, cardGroup.numChildren do
		display.remove(cardGroup[FIRTS_VALUE])
	end
	cardGroup.y = 0
end

local function selectedCorrectCard(cardTouch)
	transition.to(handMoveImage, {tag = TAG_TRANSITION, time = TIME_HAND, x = cardTouch.xStart , y = cardTouch.yScale + 600 * GLOBAL_SCALE, onComplete = function()
		transition.to(handMoveImage, {tag = TAG_TRANSITION, x = handMoveImage.xStart, y = handMoveImage.yStart})
		cardTouch:toFront()
		transition.to(cardTouch.shadow, {tag = TAG_TRANSITION, time = 40, alpha = 0})
		transition.to(cardTouch, {tag = TAG_TRANSITION, x = handMoveImage.xStart, y = handMoveImage.yStart, onComplete = function()
			cardTouch.alpha = 0
			transition.to(cardGroup, {tag = TAG_TRANSITION, time = TIME_CARD, y = display.contentHeight, onComplete = function()
				correctAnswerTotal = correctAnswerTotal + 1
				fillBar()
				delayCardGroup()
				if currentAttempt > TOTAL_TURN and correctAnswerTotal < TOTAL_CORRECT_CARDS then
					manager.wrong()
				end
			end})
		end})
	end})
end

local function selectedWrongCard(cardTouch)
	transition.to(handMoveImage, {tag = TAG_TRANSITION, time = TIME_HAND, x = cardTouch.xStart , y = cardTouch.yStart + 200 * GLOBAL_SCALE, onComplete = function()
		transition.to(handMoveImage, {tag = TAG_TRANSITION, x = handMoveImage.xStart, y = handMoveImage.yStart, onComplete = function()
			transition.to(cardGroup, {tag = TAG_TRANSITION, time = TIME_CARD, y = display.contentHeight, onComplete = function()
				delayCardGroup()
				if currentAttempt > TOTAL_TURN and correctAnswerTotal < TOTAL_CORRECT_CARDS then
					manager.wrong()
				elseif correctAnswerTotal == TOTAL_CORRECT_CARDS then
					manager.correct()
				elseif currentAttempt <= TOTAL_TURN then
					transition.cancel(TAG_TRANSITION)
					hideConditionBoolean()
				end
			end})
		end})
	end})
end

local function selectCard(event)
	local objectTap = event.target
	local isCorrect, conditionCorrectAnswer

	if currentAttempt <= TOTAL_TURN and correctAnswerTotal <= TOTAL_CORRECT_CARDS then 
		if booleanConditionalRandom == "OR" then
			conditionCorrectAnswer = (objectTap.color == correctCards[FIRTS_VALUE].color and objectTap.number == correctCards[FIRTS_VALUE].number) or
			(correctCards[SECOND_VALUE].color and objectTap.number == correctCards[SECOND_VALUE].number)
			
		elseif booleanConditionalRandom == "AND" then
			conditionCorrectAnswer = objectTap.color == correctCards[FIRTS_VALUE].color and objectTap.number == correctCards[FIRTS_VALUE].number
			
		elseif booleanConditionalRandom == "NOT" then
			conditionCorrectAnswer = objectTap.color ~= correctCards[FIRTS_VALUE].color and objectTap.number ~= correctCards[FIRTS_VALUE].number
		end
		
		isCorrect = conditionCorrectAnswer and true or false
		
		if tapsEnabled then
			tapsEnabled = false
			if not isCorrect then
				selectedWrongCard(objectTap)
			else
				selectedCorrectCard(objectTap)
			end
			currentAttempt = currentAttempt + 1
		end 
	end
	return true
end

local function dropCard()
	if not tapsEnabled then
		transition.to(cardHandImage, {tag = TAG_TRANSITION, time = TIME_HAND, x = display.screenOriginX, y = display.contentCenterY + 20 * GLOBAL_SCALE})
		transition.to(handMoveImage, {tag = TAG_TRANSITION, time = TIME_HAND, x = display.screenOriginX, y = display.contentCenterY + 220, onComplete = function()
			for positionIndex = 1, LEVEL_DATA[minigameLevel].numberCardTotal do
				transition.to(cardHandImage, {delay = 200 * (positionIndex - 1), time = 300, tag =  TAG_TRANSITION, x = cardsPlacedTable[positionIndex].x})
				transition.to(handMoveImage, {delay = 200 * (positionIndex - 1), time =300, tag =  TAG_TRANSITION, x = cardsPlacedTable[positionIndex].x, onComplete = function() 
					cardsPlacedTable[positionIndex].alpha = 1
					cardsPlacedTable[positionIndex].shadow.alpha = 1
					if positionIndex == LEVEL_DATA[minigameLevel].numberCardTotal then
						transition.to(handMoveImage, {tag = TAG_TRANSITION, x = handMoveImage.xStart, y = handMoveImage.yStart, onComplete = function()
							cardHandImage.alpha = 0
							tapsEnabled = true
						end})
					end
				end})
			end
		end})
	end
end

local function showBooleanCondition()
	for transitionIndex = 1, conditionsGroup.numChildren do
		transition.to(booleanConditionGroup[transitionIndex], {tag = TAG_TRANSITION, time = TIME_HAND, xScale = GLOBAL_SCALE, yScale = GLOBAL_SCALE}) 
		transition.to(conditionsGroup[transitionIndex], {tag = TAG_TRANSITION, time = TIME_HAND, xScale = GLOBAL_SCALE, yScale = GLOBAL_SCALE})
		transition.to(cardHandImage, {tag = TAG_TRANSITION, y = display.contentCenterY + 700 * GLOBAL_SCALE})
		transition.to(handMoveImage, {tag = TAG_TRANSITION, time = 400, y = display.contentCenterY + 700 * GLOBAL_SCALE, onComplete = function() 
			cardHandImage.alpha = 1
			transition.to(handMoveImage, {tag = TAG_TRANSITION, time = TIME_HAND,  x = display.screenOriginX})
			transition.to(cardHandImage, {tag = TAG_TRANSITION, time = TIME_HAND, x = display.screenOriginX, onComplete = function()
				if transitionIndex == conditionsGroup.numChildren then 
					dropCard()
				end
			end})
		end})
	end
end

local function creatCardObject()
	local totalCardWidth
	local positionCardx
	
	totalCardWidth = LEVEL_DATA[minigameLevel].numberCardRow * CARD_WIDTH + (LEVEL_DATA[minigameLevel].numberCardRow - 1) * LEVEL_DATA[minigameLevel].offsetCard
	positionCardx = display.contentCenterX - 0.5 * totalCardWidth + CARD_WIDTH * 0.5
	
	for cardIndex = 1, LEVEL_DATA[minigameLevel].numberCardTotal do		
		local card = display.newGroup()
		card.xScale = LEVEL_DATA[minigameLevel].scaleCard
		card.yScale = LEVEL_DATA[minigameLevel].scaleCard
		card.x = positionCardx
		card.y = display.contentCenterY + 20 * GLOBAL_SCALE
		card.xStart = card.x
		card.yStart = card.y
		card.alpha = 0
		card.color = cardTable[cardIndex].color
		card.number = cardTable[cardIndex].number
		cardGroup:insert(card)
		
		card.shadow = display.newImage(assetPath.."sombra.png")
		card.shadow.y = 15 
		card.shadow.alpha = 0
		card:insert(card.shadow)
		
		card.image = display.newImage(assetPath..cardTable[cardIndex].color..cardTable[cardIndex].number..".png")
		card:insert(card.image)
		
		cardsPlacedTable[cardIndex] = card
		card:addEventListener("tap", selectCard)
		
		if cardIndex == LEVEL_DATA[minigameLevel].numberCardTotal then
			cardHandImage = display.newImage(assetPath..cardTable[cardIndex].color..cardTable[cardIndex].number..".png")
			cardHandImage.xScale = LEVEL_DATA[minigameLevel].scaleCard
			cardHandImage.yScale = LEVEL_DATA[minigameLevel].scaleCard
			cardHandImage.x = display.contentCenterX
			cardHandImage.y = display.contentCenterY + 200 * GLOBAL_SCALE
			cardHandImage.alpha = 0
			cardGroup:insert(cardHandImage)
		end
		
		positionCardx = positionCardx + CARD_WIDTH + LEVEL_DATA[minigameLevel].offsetCard
	end
	
	showBooleanCondition()
end

local function createCardData(numberTable, colorTable)
	local numberCardRandom, colorCardRandom
	local firstCard = 1
	local secureFirstTwoCard = 2
	
	for cardRandomIndex = 1, LEVEL_DATA[minigameLevel].numberCardTotal  do
		if cardRandomIndex == firstCard and booleanConditionalRandom ~= "OR" then
			if booleanConditionalRandom == "AND" then
				if conditionsGroup[cardRandomIndex].typeConditions == "color" and conditionsGroup[cardRandomIndex + 1].typeConditions == "color" then
					numberCardRandom = CARD_NUMBERS[mathRandom(#CARD_NUMBERS)]
					colorCardRandom = conditionsGroup[cardRandomIndex].displayToUse
				else 
					local positionNumberIndex = conditionsGroup[cardRandomIndex].typeConditions == "number" and FIRTS_VALUE or SECOND_VALUE
					local positionColorIndex = conditionsGroup[cardRandomIndex].typeConditions == "color" and FIRTS_VALUE or SECOND_VALUE
					numberCardRandom = conditionsGroup[positionNumberIndex].displayToUse
					colorCardRandom = conditionsGroup[positionColorIndex].displayToUse
				end
			elseif booleanConditionalRandom == "NOT" then
				if conditionsGroup[cardRandomIndex].typeConditions == "color" then
					numberCardRandom = CARD_NUMBERS[mathRandom(#CARD_NUMBERS)]
					colorCardRandom = conditionsGroup[cardRandomIndex].displayToUse
				else 
					numberCardRandom = conditionsGroup[cardRandomIndex].displayToUse
					colorCardRandom = CARD_COLOR_TABLE[mathRandom(#CARD_COLOR_TABLE)]
				end
			end
		elseif cardRandomIndex <= secureFirstTwoCard and booleanConditionalRandom == "OR" then
			if conditionsGroup[cardRandomIndex].typeConditions == "number" then
				numberCardRandom = conditionsGroup[cardRandomIndex].displayToUse
				colorCardRandom = CARD_COLOR_TABLE[mathRandom(#CARD_COLOR_TABLE)]
			else
				numberCardRandom = CARD_NUMBERS[mathRandom(#CARD_NUMBERS)]
				colorCardRandom = conditionsGroup[cardRandomIndex].displayToUse
			end
		else
			numberCardRandom = numberTable[cardRandomIndex]
			if booleanConditionalRandom == "AND" then
				removeTable(colorTable, FIRTS_VALUE)
			end
			colorCardRandom = colorTable[mathRandom(#colorTable)]
		end
		if cardRandomIndex <= secureFirstTwoCard then
			correctCards[cardRandomIndex] = {number = numberCardRandom, color = colorCardRandom}
		end
		cardTable[cardRandomIndex] = {number = numberCardRandom, color = colorCardRandom}
	end
	cardTable = extratable.shuffle(cardTable)
	
	creatCardObject()
end

local function createConditionValue()
	transition.cancel(TAG_TRANSITION)
	
	local firstRandCondition = mathRandom(#CONDITION_VALUE)
	local posibleSecondCondition = firstRandCondition == 1 and 2 or mathRandom(#CONDITION_VALUE)
	
	local condition = minigameLevel == 1 and booleanConditionalRandom ~= "AND"
	local secondRandCondition = condition and firstRandCondition or posibleSecondCondition
	
	local typeConditions = {CONDITION_VALUE[firstRandCondition], CONDITION_VALUE[secondRandCondition]}
	
	local secureDiferentCondition = {"c_", "palo_"}
	secureDiferentCondition = extratable.shuffle(secureDiferentCondition)
	
	local numbers = extratable.deepcopy(CARD_NUMBERS)
	numbers = extratable.shuffle(numbers)
	
	local colors = extratable.deepcopy(CARD_COLOR_TABLE)
	colors = extratable.shuffle(colors)
	
	local conditionType = booleanConditionalRandom == "NOT" and FIRTS_VALUE or #POSITION_CONDITION_TABLE
	
	for booleanConditionIndex = 1, conditionType do
		local randToUse, displayToUse, conditionImage, typeToUse
		
		if typeConditions[booleanConditionIndex] == "number" then
			randToUse = mathRandom(#numbers)
			displayToUse = numbers[randToUse]
			removeTable(numbers, randToUse)
			conditionImage = display.newText(displayToUse, 0, 0, native.systemFontBold, 80 * GLOBAL_SCALE)
			conditionImage:setFillColor(unpack(COLOR_NUBERS_RANDOM))
		else
			randToUse = booleanConditionalRandom == "AND" and FIRTS_VALUE or mathRandom(#colors)
			typeToUse = secureDiferentCondition[FIRTS_VALUE]..colors[randToUse]
			displayToUse = colors[randToUse]
			conditionImage = display.newImage(assetPath..typeToUse..".png")
			
			if booleanConditionalRandom ~= "AND" then
				removeTable(colors, randToUse)
			end
			
			if minigameLevel ~= 1 or booleanConditionalRandom == "AND" then
				removeTable(secureDiferentCondition, FIRTS_VALUE)
			end
		end
		
		local conditionTypePosition = booleanConditionalRandom == "NOT" and 100 * GLOBAL_SCALE or POSITION_CONDITION_TABLE[booleanConditionIndex].x
		
		conditionImage.x = display.contentCenterX + conditionTypePosition
		conditionImage.y = display.screenOriginY + POSITION_CONDITION_TABLE[booleanConditionIndex].y
		conditionImage.xScale = GLOBAL_SCALE * 0.2
		conditionImage.yScale = GLOBAL_SCALE * 0.2
		conditionImage.typeConditions = typeConditions[booleanConditionIndex]
		conditionImage.displayToUse = displayToUse
		conditionsGroup:insert(conditionImage)
	end
	createCardData(numbers, colors)
end

local function createBooleanCondition()
	booleanConditionalRandom = BOOLEAN_TEXT_TABLE[mathRandom(#BOOLEAN_TEXT_TABLE)]
	
	local positionConditionX = booleanConditionalRandom == "NOT" and display.contentCenterX - 50 * GLOBAL_SCALE or display.contentCenterX
	
	local booleanConditionText = display.newText(booleanConditionalRandom, positionConditionX, display.screenOriginY + 100 * GLOBAL_SCALE, native.systemFontBold, 80 * GLOBAL_SCALE)
	booleanConditionText:setFillColor(unpack(COLOR_TEXT_BOOLEAN_CONITION))
	booleanConditionText.xScale = GLOBAL_SCALE * 0.2
	booleanConditionText.yScale = GLOBAL_SCALE * 0.2
	booleanConditionGroup:insert(booleanConditionText)
	
	createConditionValue()
end

local function createTimer()
	if minigameLevel > FIRTS_VALUE then
		local timerEmptyImage = display.newCircle(display.screenOriginX + 129 * GLOBAL_SCALE, display.screenOriginY + 115 * GLOBAL_SCALE, 50 * GLOBAL_SCALE)
		timerEmptyImage:setFillColor(unpack(COLOR_STAR_TIME))
		timerEmptyImage.alpha = 0
		uiGroup:insert(timerEmptyImage)
		
		local timerMovement = display.newCircle(timerEmptyImage.x, timerEmptyImage.y, timerEmptyImage.contentWidth * 0.4)
		timerMovement:setFillColor(COLOR_CURRENT_TIMER)
		timerMovement.xScale = - timerMovement.xScale
		timerMovement.fill.effect = "filter.radialWipe"
		timerMovement.fill.effect.axisOrientation = 0.25
		timerMovement.fill.effect.progress = 1
		uiGroup:insert(timerMovement)
		
		local timerFlowerImage = display.newImage(assetPath.."timer1.png")
		timerFlowerImage.xScale = GLOBAL_SCALE
		timerFlowerImage.yScale = GLOBAL_SCALE
		timerFlowerImage.x = display.screenOriginX + 125 * GLOBAL_SCALE
		timerFlowerImage.y = display.screenOriginY + 120 * GLOBAL_SCALE
		timerFlowerImage.alpha = 0
		uiGroup:insert(timerFlowerImage)
		
		transition.to(timerEmptyImage, {tag = TAG_TIMER, time = 2300, alpha = 1})
		transition.to(timerFlowerImage, {tag = TAG_TIMER, time = 2300, alpha = 1, onComplete = function()
			transition.to(timerMovement.fill.effect, {tag = TAG_TIMER, time = LIMIT_START_TIME, progress = 0.10, onComplete = function()
				timerEmptyImage:setFillColor(unpack(COLOR_END_TIME))
				transition.to(timerMovement.fill.effect, {tag = TAG_TIMER, time = LIMIT_END_TIME , progress = 0, onComplete = function()
					transition.cancel(TAG_TRANSITION)
					tapsEnabled = false
					transition.to(cardGroup, {tag = TAG_TIMER, time = TIME_CARD, y = display.contentHeight, onComplete = function()
						manager.wrong()
					end})
				end})
			end})
		end})
	end
end

local function createHand()
	handMoveImage = display.newImage(assetPath.."manita.png")
	handMoveImage.xScale = GLOBAL_SCALE
	handMoveImage.yScale = GLOBAL_SCALE
	handMoveImage.x = display.contentCenterX
	handMoveImage.y = display.contentCenterY + 400 * GLOBAL_SCALE
	handMoveImage.xStart = handMoveImage.x
	handMoveImage.yStart = handMoveImage.y
	
	handMoveImage.createBooleanCondition = createBooleanCondition
	
	dynamicGroup:insert(handMoveImage)
end

local function createBarEnergy()
	local baseEnergyBarImage = display.newImage(assetPath.."barra_azul.png")
	baseEnergyBarImage.xScale = GLOBAL_SCALE
	baseEnergyBarImage.yScale = GLOBAL_SCALE
	baseEnergyBarImage.x = display.contentCenterX
	baseEnergyBarImage.y = display.contentHeight - 90 * GLOBAL_SCALE
	uiGroup:insert(baseEnergyBarImage)
	
	energyContainer = display.newContainer(0, CONTAINER_WIDTH)
	energyContainer.fillValue = 0
	energyContainer.anchorChildren = false
	energyContainer.anchorX = 0
	energyContainer:translate(display.contentCenterX - 145 * GLOBAL_SCALE, display.contentHeight - 87 * GLOBAL_SCALE)
	uiGroup:insert(energyContainer)
	
	local barEnergyImage = display.newImage(assetPath.."b_energia4.png")
	barEnergyImage.anchorX = 0
	barEnergyImage.xScale = GLOBAL_SCALE
	barEnergyImage.yScale = GLOBAL_SCALE
	barEnergyImage:translate(0, 0)
	energyContainer:insert(barEnergyImage, true)
	
	local threeCardBarImage = display.newImage(assetPath.."b_energia2.png")
	threeCardBarImage.xScale = GLOBAL_SCALE
	threeCardBarImage.yScale = GLOBAL_SCALE
	threeCardBarImage.x = display.contentCenterX - 160 * GLOBAL_SCALE
	threeCardBarImage.y = display.contentHeight - 90 * GLOBAL_SCALE
	uiGroup:insert(threeCardBarImage)
end 

local function createScene()
	local woodImage = display.newImage(assetPath.."madera.png")
	woodImage.width = display.contentWidth
	woodImage.yScale = GLOBAL_SCALE 
	woodImage.x = display.contentCenterX
	woodImage.y = display.contentHeight - 15 * GLOBAL_SCALE
	backgroundGroup:insert(woodImage)
	
	local booleanBaseImage = display.newImage(assetPath.."barra.png")
	booleanBaseImage.anchorY = 0
	booleanBaseImage.xScale = GLOBAL_SCALE
	booleanBaseImage.yScale = GLOBAL_SCALE
	booleanBaseImage.x = display.contentCenterX
	booleanBaseImage.y = display.screenOriginY
	backgroundGroup:insert(booleanBaseImage)
end

local function createGroup()
	backgroundGroup = display.newGroup()
	backgroundLayer:insert(backgroundGroup)
	
	dynamicGroup = display.newGroup()
	dynamicLayer:insert(dynamicGroup)
	
	uiGroup = display.newGroup()
	uiLayer:insert(uiGroup)
	
	cardGroup = display.newGroup()
	dynamicGroup:insert(cardGroup)
	
	booleanConditionGroup = display.newGroup()
	uiGroup:insert(booleanConditionGroup)
	
	conditionsGroup = display.newGroup()
	uiGroup:insert(conditionsGroup)
end

local function cleanUp()
	transition.cancel(TAG_TRANSITION)
	transition.cancel(TAG_TIMER)
	
	display.remove(uiGroup)
	uiGroup = nil
	
	display.remove(dynamicGroup)
	dynamicGroup = nil
	
	display.remove(backgroundGroup)
	backgroundGroup = nil
end

local function initialize(event)
	event = event or {} 
	local params = event.params or {}
	
	correctAnswerTotal = 0
	currentAttempt = 1
	minigameLevel = 1
	
	cardsPlacedTable = {}
	correctCards = {}
	cardTable = {}
	
	tapsEnabled = false

	isFirstTime = params.isFirstTime 
	manager = event.parent 
end
----------------------------------------------- Module functions
function game.getInfo() 
	return {
		correctDelay = 500, 
		wrongDelay = 500, 
		name = "BooleanCards", 
		category = "programming", 
		subcategories = {"logic"}, 
		age = {min = 8, max = 9}, 
		grade = {min = 3, max = 99}, 
		gamemode = "logic/Boolean Operators", 
		requires = {}
	}
end  

function game:create() 
	local sceneView = self.view
	
	backgroundLayer = display.newGroup() 
	sceneView:insert(backgroundLayer)
	
	dynamicLayer = display.newGroup()
	sceneView:insert(dynamicLayer)
	
	uiLayer = display.newGroup()
	sceneView:insert(uiLayer)
	
	local backgroundImage = display.newImageRect(assetPath.."fondo.png", SCREEN_WIDTH, SCREEN_HEIGHT)
	backgroundImage.x = display.contentCenterX
	backgroundImage.y = display.contentCenterY
	backgroundLayer:insert(backgroundImage)
end

function game:show(event) 
	local phase = event.phase
	
	if phase == "will" then 
		initialize(event)
		createGroup()
		createScene()
		createHand()
		createBarEnergy()
		createBooleanCondition()
		if minigameLevel > 1 then
			createTimer()
		end
	end
end

function game:hide(event)
	local phase = event.phase

	if phase == "did" then 
		cleanUp()
	end
end

----------------------------------------------- Execution
game:addEventListener("create")
game:addEventListener("hide")
game:addEventListener("show")

return game