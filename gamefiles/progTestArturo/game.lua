----------------------------------------------- progVariableIceCream - 4th and 5th grade arithmetic operations
local scenePath = ... 
local folder = scenePath:match("(.-)[^%.]+$") 
local assetPath = string.gsub(folder,"[%.]","/") 
local director = require("libs.helpers.director")
local extratable = require("libs.helpers.extratable")
local widget = require("widget")
local game = director.newScene() 
----------------------------------------------- Variables
local manager, isFirstTime, isTouchEnabled
local backgroundLayer, dynamicLayer, overlayLayer
local backgroundGroup, dynamicGroup, overlayGroup
local answerCounter, targetNumber, failCounter
local iceCreamNumbers, iceCreamCovers, iceCreamValues
local questionMarkBoxes
local screenReference
local dish, okButton, timerContainer
----------------------------------------------- Constants
local GLOBAL_SCALE = display.contentHeight / 765
local TRANSITION_TAG = "transition"
local GAME_TIMER = 20000
local DIFFICULTY = 1
local ATTEMPTS = 2
local ANSWERS = 3
local GRADE = 5
local COLUMNS = 3
local ROWS = 2
local OPERATORS = {
	[4] = {"plus", "minus"},
	[5] = {"times", "dividedby"}
}
local STICK_INFO = {
	{xOffset = -390, anchor = 0.5},
	{xOffset = -512, anchor = 1},
	{xOffset = 512, anchor = 0}
}
local QUESTION_MARK_INFO = {
	{xOffset = -0.275, yOffset = 0.18},
	{xOffset = 0, yOffset = 0.25},
	{xOffset = 0.275, yOffset = 0.18}
}
local ANSWER_ORDER = {"number", "operator", "number"}
local TIMER_COMPONENTS = {"timerbackground.png", "timercolor.png", "timerface.png", "timershine.png"}
----------------------------------------------- Caches
local mPow = math.pow
local mRand = math.random
----------------------------------------------- Functions
local function cleanUp()
	transition.cancel(TRANSITION_TAG)
	transition.cancel("timer")
	
	backgroundGroup = display.remove(backgroundGroup)
	dynamicGroup = display.remove(dynamicGroup)
	overlayGroup = display.remove(overlayGroup)
end

local function resetDish()
	answerCounter = 0
	
	for questionIndex = 1, #questionMarkBoxes do
		questionMarkBoxes[questionIndex].isOccupied = false
	end
	
	transition.to(dish.back, {tag = TRANSITION_TAG, time = 500, alpha = 1})
	transition.to(dish.front, {tag = TRANSITION_TAG, time = 500, alpha = 1,
	onComplete = function()
		isTouchEnabled = true
	end})
end

local function showNumbers(numberIndex)
	transition.cancel("timer")
	
	local answerNumber = display.newImage(assetPath.."ballnumber"..questionMarkBoxes[numberIndex].answer.number..".png")
	answerNumber.xScale, answerNumber.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	answerNumber.x, answerNumber.y = questionMarkBoxes[numberIndex].answer.x, questionMarkBoxes[numberIndex].answer.y
	answerNumber.alpha = 0
	dynamicGroup:insert(answerNumber)
	
	dish.front:toFront()
	
	transition.to(answerNumber, {tag = TRANSITION_TAG, delay = 500, time = 300, alpha = 1,
	onComplete = function()
		if numberIndex < 3 then
			showNumbers(numberIndex + 1)
		else
			manager.correct()
		end
	end})
end

local function showFailureFeedback()
	failCounter = failCounter + 1
	for answerIndex = 1, #questionMarkBoxes do
		transition.to(questionMarkBoxes[answerIndex].answer, {tag = TRANSITION_TAG, time = 500, alpha = 0, 
		onComplete = function()
			questionMarkBoxes[answerIndex].answer = display.remove(questionMarkBoxes[answerIndex].answer)
		end})
	end
	
	local dishMelted = display.newImage(assetPath.."wronganswer.png")
	dishMelted.xScale, dishMelted.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	dishMelted.x, dishMelted.y = display.contentCenterX - dishMelted.contentWidth * 0.25, screenReference.counterTop.y - screenReference.counterTop.height * 0.87
	dishMelted.alpha = 0
	dynamicGroup:insert(dishMelted)
	
	transition.to(dish.back, {tag = TRANSITION_TAG, alpha = 0})
	transition.to(dish.front, {tag = TRANSITION_TAG, alpha = 0})
	transition.to(dishMelted, {tag = TRANSITION_TAG, alpha = 1, 
	onComplete = function()
		transition.to(dishMelted, {tag = TRANSITION_TAG, delay = 350, time = 300, alpha = 0, x = display.screenOriginX,
		onComplete = function() 
			dishMelted = display.remove(dishMelted)
			if failCounter < ATTEMPTS then
				resetDish()
			else
				manager.wrong()
			end
		end})
	end})
end

local function validateAnswer()
	local errorCount = 0
	for answerIndex = 1, #ANSWER_ORDER do
		if questionMarkBoxes[answerIndex].answer.tag ~= ANSWER_ORDER[answerIndex] then
			errorCount = errorCount + 1
		end
	end
	
	local inputResult = 0
	if errorCount == 0 then
		if questionMarkBoxes[2].answer.number == "plus" then
			inputResult = questionMarkBoxes[1].answer.number + questionMarkBoxes[3].answer.number
		elseif questionMarkBoxes[2].answer.number == "minus" then
			inputResult = questionMarkBoxes[1].answer.number - questionMarkBoxes[3].answer.number
		elseif questionMarkBoxes[2].answer.number == "times" then
			inputResult = questionMarkBoxes[1].answer.number * questionMarkBoxes[3].answer.number
		elseif questionMarkBoxes[2].answer.number == "dividedby" then
			inputResult = questionMarkBoxes[1].answer.number / questionMarkBoxes[3].answer.number
		end
	end
	
	if inputResult == targetNumber then
		showNumbers(1)
	else
		showFailureFeedback()
	end
end

local function handleOkButton(event)
	local button = event.target
	local phase = event.phase
	
	if okButton.isEnabled and isTouchEnabled then
		isTouchEnabled = false
		transition.to(okButton, {tag = TRANSITION_TAG, time = 500, alpha = 0})
		validateAnswer()
	end
	
	return true
end

local function checkBounds(target)	
	for questionIndex = 1, #questionMarkBoxes do
		local objectBounds = questionMarkBoxes[questionIndex].contentBounds
		if target.y >= objectBounds.yMin and target.y <= objectBounds.yMax
		and target.x >= objectBounds.xMin and target.x <= objectBounds.xMax
		and not questionMarkBoxes[questionIndex].isOccupied then
			answerCounter = answerCounter + 1
			transition.to(target, {tag = TRANSITION_TAG, time = 500, x = questionMarkBoxes[questionIndex].x, y = questionMarkBoxes[questionIndex].y,
			onComplete = function()
				dynamicGroup:insert(target)
				dish.front:toFront()
				target.isTouchEnabled = true
				questionMarkBoxes[questionIndex].isOccupied = true
				questionMarkBoxes[questionIndex].answer = target
			end})
			
			if answerCounter == ANSWERS then
				okButton.alpha = 1
				okButton.isEnabled = true
			else
				okButton.alpha = 0
				okButton.isEnabled = false
			end
			return true
		end
	end
	
	return false
end

local function spawnIceCreamBall(target, event)
	local iceCreamBall = display.newImage(assetPath.."ball"..target.number..".png")
	iceCreamBall.xScale, iceCreamBall.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	iceCreamBall.x, iceCreamBall.y = event.x, event.y
	iceCreamBall.number = target.number
	iceCreamBall.isClone = true
	iceCreamBall.originX, iceCreamBall.originY = target.x, target.y
	
	if target.number == OPERATORS[GRADE][1] or target.number == OPERATORS[GRADE][2] then
		iceCreamBall.tag = "operator"
	else
		iceCreamBall.tag = "number"
	end
	
	overlayGroup:insert(iceCreamBall)
	
	return iceCreamBall
end

local function dragIceCream(event)
	local target = event.target
	local phase = event.phase
	
	if isTouchEnabled and target.isTouchEnabled then 
		if "began" == phase then
			if not target.isClone then
				local iceCreamBall = spawnIceCreamBall(target, event)
				iceCreamBall:addEventListener("touch", dragIceCream)
				iceCreamBall.isFocus = true
				iceCreamBall.isTouchEnabled = true
				display.currentStage:setFocus(iceCreamBall)
			end
			
			for answerIndex = 1, #questionMarkBoxes do
				if target == questionMarkBoxes[answerIndex].answer then
					target.isFocus = true
					display.currentStage:setFocus(target)
					target:toFront()
					answerCounter = answerCounter - 1
					questionMarkBoxes[answerIndex].answer = nil
					questionMarkBoxes[answerIndex].isOccupied = false
				end
			end
			
		elseif target.isFocus then
			if "moved" == phase then
				target.x = event.x
				target.y = event.y
				
			elseif "ended" == phase or "cancelled" == phase then
				target.isFocus = false
				display.currentStage:setFocus(nil)
				target.isTouchEnabled = false
				
				if not checkBounds(target) then
					transition.to(target, {tag = TRANSITION_TAG, time = 300, x = target.originX, y = target.originY, 
					onComplete = function() 
						transition.to(target, {tag = TRANSITION_TAG, time = 200, alpha = 0, 
						onComplete = function() 
							target = display.remove(target)
						end})
					end})
				end
			end
		end
	end
	
	return true
end

local function createCashMachine()
	local cashMachineBase = display.newImage(assetPath.."cashmachinebase.png")
	cashMachineBase.xScale, cashMachineBase.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	cashMachineBase.x, cashMachineBase.y = display.contentCenterX + cashMachineBase.contentWidth, screenReference.counterTop.y - screenReference.counterTop.height * 0.8
	backgroundGroup:insert(cashMachineBase)
	
	local cashMachineScreen = display.newImage(assetPath.."cashmachinescreen.png")
	cashMachineScreen.xScale, cashMachineScreen.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	cashMachineScreen.x, cashMachineScreen.y = cashMachineBase.x, cashMachineBase.y - cashMachineBase.contentHeight * 0.8
	backgroundGroup:insert(cashMachineScreen)
	
	local numberText = display.newText(targetNumber, cashMachineScreen.x, cashMachineScreen.y, native.systemFont, 72)
	numberText.xScale, numberText.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	numberText:setFillColor(1)
	dynamicGroup:insert(numberText)
end

local function createDish()
	local dishBack = display.newImage(assetPath.."dishback.png")
	dishBack.xScale, dishBack.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	dishBack.x, dishBack.y = display.contentCenterX - dishBack.contentWidth * 0.25, screenReference.counterTop.y - screenReference.counterTop.height * 0.87
	backgroundGroup:insert(dishBack)
	
	local dishFront = display.newImage(assetPath.."dishfront.png")
	dishFront.xScale, dishFront.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	dishFront.x, dishFront.y = display.contentCenterX - dishFront.contentWidth * 0.25, screenReference.counterTop.y - screenReference.counterTop.height * 0.79
	dynamicGroup:insert(dishFront)
	
	for questionIndex = 1, #QUESTION_MARK_INFO do
		questionMarkBoxes[questionIndex] = display.newRect(dishBack.x + dishBack.contentWidth * QUESTION_MARK_INFO[questionIndex].xOffset, dishBack.y - dishBack.contentHeight * QUESTION_MARK_INFO[questionIndex].yOffset, 100 * GLOBAL_SCALE, 100 * GLOBAL_SCALE)
		questionMarkBoxes[questionIndex].alpha = 0
		backgroundGroup:insert(questionMarkBoxes[questionIndex])	
		questionMarkBoxes[questionIndex].answer = nil
	end
	
	dish.back = dishBack
	dish.front = dishFront
end

local function createOkButton()
	okButton = widget.newButton(
		{
			width = 150,
			height = 150,
			defaultFile = assetPath.."okbutton-1.png",
			overFile = assetPath.."okbutton-2.png",
			onEvent = handleOkButton
		}
	)
	okButton.xScale, okButton.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	okButton.x, okButton.y = display.contentCenterX + 420 * GLOBAL_SCALE, display.actualContentHeight - okButton.height * 0.6
	okButton.alpha = 0
	okButton.isEnabled = false
	dynamicGroup:insert(okButton)
end

local function createSticks()		
	for stickIndex = 1, #STICK_INFO do
		local sticks = display.newImage(assetPath.."sticks"..stickIndex..".png")
		sticks.anchorX = STICK_INFO[stickIndex].anchor
		sticks.xScale, sticks.yScale = GLOBAL_SCALE, GLOBAL_SCALE
		sticks.x, sticks.y = display.contentCenterX + STICK_INFO[stickIndex].xOffset * GLOBAL_SCALE, screenReference.counterTop.y - screenReference.counterTop.height * 0.6
		backgroundGroup:insert(sticks)
	end
end

local function closeCover(position)
	iceCreamCovers[position].alpha = 1
	iceCreamCovers[position].openedCover.alpha = 0
	iceCreamCovers[position].iceCream.isTouchEnabled = false
end

local function tapListener(event)
	local target = event.target
	
	if isTouchEnabled then
		for iceCreamIndex = 1, #iceCreamCovers do
			if target == iceCreamCovers[iceCreamIndex] then
				if iceCreamIndex % 2 == 1 then
					if iceCreamCovers[iceCreamIndex + 1].iceCream.isTouchEnabled then
						closeCover(iceCreamIndex + 1)
					end
				else
					if iceCreamCovers[iceCreamIndex - 1].iceCream.isTouchEnabled then
						closeCover(iceCreamIndex - 1)
					end
				end
				target.alpha = 0
				target.openedCover.alpha = 1
				isTouchEnabled = true
				target.iceCream.isTouchEnabled = true
			end
		end
	end
end

local function createIceCreamContainer(rowCenterX, rowCenterY)
	local iceCreamBack = display.newImage(assetPath.."icecreamback.png")
			iceCreamBack.xScale, iceCreamBack.yScale = GLOBAL_SCALE, GLOBAL_SCALE
			iceCreamBack.x, iceCreamBack.y = rowCenterX, rowCenterY
			backgroundGroup:insert(iceCreamBack)
			
			local iceCream = display.newImage(assetPath.."icecream"..iceCreamValues[#iceCreamCovers + 1]..".png")
			iceCream.xScale, iceCream.yScale = GLOBAL_SCALE, GLOBAL_SCALE
			iceCream.x, iceCream.y = rowCenterX, rowCenterY - 6 * GLOBAL_SCALE
			iceCream.number = iceCreamValues[#iceCreamCovers + 1]
			iceCream.isTouchEnabled = false
			iceCream:addEventListener("touch", dragIceCream)
			backgroundGroup:insert(iceCream)
			
			local iceCreamCover = display.newImage(assetPath.."icecreamcover.png")
			iceCreamCover.xScale, iceCreamCover.yScale = GLOBAL_SCALE, GLOBAL_SCALE
			iceCreamCover.x, iceCreamCover.y = rowCenterX, rowCenterY - 6 * GLOBAL_SCALE
			iceCreamCover:addEventListener("tap", tapListener)
			backgroundGroup:insert(iceCreamCover)
			
			local iceCreamCoverOpened = display.newImage(assetPath.."icecreamcoveropened.png")
			iceCreamCoverOpened.xScale, iceCreamCoverOpened.yScale = GLOBAL_SCALE, GLOBAL_SCALE
			iceCreamCoverOpened.x, iceCreamCoverOpened.y = rowCenterX, rowCenterY - 25 * GLOBAL_SCALE - iceCreamCover.contentHeight * 0.5
			iceCreamCoverOpened.alpha = 0
			backgroundGroup:insert(iceCreamCoverOpened)
			iceCreamCover.openedCover = iceCreamCoverOpened
			iceCreamCover.iceCream = iceCream
			
			iceCreamCovers[#iceCreamCovers + 1] = iceCreamCover
end

local function setIceCreamContainerPositions()
	for columnIndex = 1, COLUMNS do
		for rowIndex = 1, ROWS do			
			local offset
			if columnIndex == 1 then
				offset = 20 * GLOBAL_SCALE
			else
				offset = 50 * GLOBAL_SCALE
			end
			
			local rowCenterX = display.contentCenterX - 512 * GLOBAL_SCALE + offset + (columnIndex - 0.5) * screenReference.frost.contentWidth
			local rowCenterY =  display.viewableContentHeight - 0.5 * screenReference.fridgeContainer.contentHeight + mPow(-1, rowIndex) * 0.25 * screenReference.fridgeContainer.contentHeight
			
			createIceCreamContainer(rowCenterX, rowCenterY)
		end
	end
end

local function generateTargetNumber()
	targetNumber = 0
	while targetNumber % 1 ~= 0 and targetNumber % 1 ~= 0.5 or targetNumber <= 0 do
		local operator = OPERATORS[GRADE][mRand(1, 2)]
		local firstNumber = iceCreamNumbers[mRand(1, 2)]
		local secondNumber = iceCreamNumbers[mRand(5, 6)]
		if operator == "plus" then
			targetNumber = firstNumber + secondNumber
		elseif operator == "minus" then
			targetNumber = firstNumber - secondNumber
		elseif operator == "times" then
			targetNumber = firstNumber * secondNumber
		elseif operator == "dividedby" then
			targetNumber = firstNumber / secondNumber
		end
	end
end

local function shuffleIceCream()
	iceCreamNumbers = extratable.shuffle(iceCreamNumbers)
	local operators = extratable.shuffle(OPERATORS[GRADE])
	
	for iceCreamIndex = 1, ROWS * COLUMNS do
		if iceCreamIndex == 3 or iceCreamIndex == 4 then
			iceCreamValues[iceCreamIndex] = operators[iceCreamIndex - 2]
		else
			iceCreamValues[iceCreamIndex] = iceCreamNumbers[iceCreamIndex]
		end
	end
	
	if DIFFICULTY ~= 1 then
		iceCreamValues = extratable.shuffle(iceCreamValues)
	end
end

local function createTimer()
	local timerComponent
	local secondLayer = 2
	for layerIndex = 1, #TIMER_COMPONENTS do
		if layerIndex ~= secondLayer then
			timerComponent = display.newImage(assetPath..TIMER_COMPONENTS[layerIndex])
			timerComponent.anchorY = 1
			timerComponent.xScale, timerComponent.yScale = GLOBAL_SCALE, GLOBAL_SCALE
			timerComponent.x, timerComponent.y = display.actualContentWidth - 120 * GLOBAL_SCALE, display.actualContentHeight - 10 * GLOBAL_SCALE
			dynamicGroup:insert(timerComponent)
		else
			local timerColor = display.newImage(assetPath..TIMER_COMPONENTS[layerIndex])
			timerColor.anchorY = 1
			timerColor.xScale, timerColor.yScale = GLOBAL_SCALE, GLOBAL_SCALE
			
			timerContainer = display.newContainer(timerColor.width, 0)
			timerContainer:insert(timerColor)
			timerContainer:insert(timerColor, true)
			timerContainer:translate(timerComponent.x, timerComponent.y)
			dynamicGroup:insert(timerContainer)
		end
	end
end

local function createFridge()
	local fridgeContainer = display.newImage(assetPath.."fridge.png")
	fridgeContainer.anchorY = 1
	fridgeContainer.yScale = GLOBAL_SCALE
	fridgeContainer.x, fridgeContainer.y = display.contentCenterX, display.viewableContentHeight
	fridgeContainer.width = display.actualContentWidth
	backgroundGroup:insert(fridgeContainer)
	
	local counterTop = display.newImage(assetPath.."counter.png")
	counterTop.anchorY = 1
	counterTop.yScale = GLOBAL_SCALE
	counterTop.width = display.actualContentWidth
	counterTop.x, counterTop.y = display.contentCenterX, display.viewableContentHeight - fridgeContainer.contentHeight
	backgroundGroup:insert(counterTop)
	
	local frost
	for columnIndex = 1, COLUMNS do
		frost = display.newImage(assetPath.."frost"..columnIndex..".png")
		frost.xScale, frost.yScale = GLOBAL_SCALE, GLOBAL_SCALE
		
		local offset
		if columnIndex == 1 then
			offset = 20 * GLOBAL_SCALE
		else
			offset = 50 * GLOBAL_SCALE
		end
		
		frost.x, frost.y = display.contentCenterX - 512 * GLOBAL_SCALE + offset + (columnIndex - 0.5) * frost.contentWidth, display.viewableContentHeight - 0.5 * fridgeContainer.contentHeight
		backgroundGroup:insert(frost)
	end
	
	local fridgeDoorsLeft = display.newImage(assetPath.."fridgedoorleft.png")
	fridgeDoorsLeft.anchorX, fridgeDoorsLeft.anchorY = 1, 1
	fridgeDoorsLeft.xScale, fridgeDoorsLeft.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	fridgeDoorsLeft.x, fridgeDoorsLeft.y = display.contentCenterX - 520 * GLOBAL_SCALE, display.viewableContentHeight
	backgroundGroup:insert(fridgeDoorsLeft)
	
	local fridgeDoorsRight = display.newImage(assetPath.."fridgedoorright.png")
	fridgeDoorsRight.anchorX, fridgeDoorsRight.anchorY = 0, 1
	fridgeDoorsRight.xScale, fridgeDoorsRight.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	fridgeDoorsRight.x, fridgeDoorsRight.y = display.contentCenterX - 430 * GLOBAL_SCALE + 3 * frost.contentWidth, display.viewableContentHeight
	backgroundGroup:insert(fridgeDoorsRight)
	
	screenReference.fridgeContainer = fridgeContainer
	screenReference.counterTop = counterTop
	screenReference.frost = frost
end

local function createCharacter()
	local character = display.newImage(assetPath.."eagle-01.png")
	character.anchorY = 0
	character.xScale, character.yScale = GLOBAL_SCALE * 1.8, GLOBAL_SCALE * 1.8
	character.x, character.y = display.contentCenterX - character.contentWidth, display.screenOriginY
	backgroundGroup:insert(character)
end

local function handleOverlayButton(event)
	local button = event.target
	local phase = event.phase
	
	if button.isEnabled then
		if "began" == phase then
			display.currentStage:setFocus(button)
		elseif "ended" == phase or "cancelled" == phase then
			display.currentStage:setFocus(nil)
			transition.to(overlayGroup, {tag = TRANSITION_TAG, time = 300, alpha = 0,
			onComplete = function()
				transition.cancel(TRANSITION_TAG)
				overlayGroup = display.remove(overlayGroup)
				overlayGroup = display.newGroup()
				overlayLayer:insert(overlayGroup)
				isTouchEnabled = true
				transition.to(timerContainer, {tag = "timer", time = GAME_TIMER, height = 610 * GLOBAL_SCALE,
				onComplete = function()
					manager.wrong()
				end})
			end})
		end
	end
	
	return true
end

local function animateOverlay(options)
	transition.to(options.overlayHand, {tag = TRANSITION_TAG, delay = 800, time = 200, rotation = -45,
	onComplete = function()
		options.overlayIceCream.alpha = 1
		options.overlayIceCreamCoverOpened.alpha = 1
		transition.to(options.overlayHand, {tag = TRANSITION_TAG, time = 200, rotation = 0,
		onComplete = function()
			transition.to(options.overlayHand, {tag = TRANSITION_TAG, delay = 750, time = 200, rotation = -45, 
			onComplete = function()
				options.overlayIceCreamBall.alpha = 1
				transition.to(options.overlayIceCreamBall, {tag = TRANSITION_TAG, delay = 150, time = 500, y = options.overlayDishFront.y - 30 * GLOBAL_SCALE})
				transition.to(options.overlayHand, {tag = TRANSITION_TAG, delay = 150, time = 500, y = options.overlayDishFront.y,
				onComplete = function()
					options.overlayDishFront:toFront()
					options.overlayHand:toFront()
					transition.to(options.overlayHand, {tag = TRANSITION_TAG, delay = 150, time = 200, rotation = 0, 
					onComplete = function()
						transition.to(options.overlayIceCreamBall, {tag = TRANSITION_TAG, delay = 200, time = 200, alpha = 0})
						transition.to(options.overlayHand, {tag = TRANSITION_TAG, delay = 200, time = 200, alpha = 0,
						onComplete = function()
							options.overlayOkButton.alpha = 1
							options.overlayOkButton.isEnabled = true
							options.overlayIceCreamBall.y = options.overlayIceCream.y
							options.overlayHand.y = display.contentCenterY + options.overlayHand.height * 0.8
							options.overlayIceCream.alpha = 0
							options.overlayIceCreamCoverOpened.alpha = 0
							options.overlayIceCreamBall:toFront()
							options.overlayHand:toFront()
							transition.to(options.overlayHand, {tag = TRANSITION_TAG, delay = 200, time = 200, alpha = 1,
							onComplete = function()
								animateOverlay(options)
							end})
						end})
					end})
				end})
			end})
		end})
	end})
end

local function createOverlay()
	isTouchEnabled = false
	
	local shadow = display.newRect(display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
	shadow:setFillColor(0)
	shadow.alpha = 0.75
	overlayGroup:insert(shadow)
	
	local overlayBackground = display.newImage(assetPath.."overlay.png")
	overlayBackground.xScale, overlayBackground.yScale = GLOBAL_SCALE * 1.05, GLOBAL_SCALE * 1.05
	overlayBackground.x, overlayBackground.y = display.contentCenterX, display.contentCenterY
	overlayGroup:insert(overlayBackground)
	
	local overlayIceCreamCover = display.newImage(assetPath.."overlayicecream.png")
	overlayIceCreamCover.xScale, overlayIceCreamCover.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	overlayIceCreamCover.x, overlayIceCreamCover.y = display.contentCenterX, display.contentCenterY + 116 * GLOBAL_SCALE
	overlayGroup:insert(overlayIceCreamCover)
	
	local overlayIceCream = display.newImage(assetPath.."icecream7.png")
	overlayIceCream.xScale, overlayIceCream.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	overlayIceCream.x, overlayIceCream.y = overlayIceCreamCover.x, overlayIceCreamCover.y - 15 * GLOBAL_SCALE
	overlayIceCream.alpha = 0
	overlayGroup:insert(overlayIceCream)
	
	local overlayIceCreamCoverOpened = display.newImage(assetPath.."icecreamcoveropened.png")
	overlayIceCreamCoverOpened.xScale, overlayIceCreamCoverOpened.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	overlayIceCreamCoverOpened.x, overlayIceCreamCoverOpened.y = overlayIceCream.x, overlayIceCream.y - overlayIceCream.height * 0.5 - 23 * GLOBAL_SCALE
	overlayIceCreamCoverOpened.alpha = 0
	overlayGroup:insert(overlayIceCreamCoverOpened)
	
	local overlayDish = display.newImage(assetPath.."overlaydish.png")
	overlayDish.xScale, overlayDish.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	overlayDish.x, overlayDish.y = display.contentCenterX, display.contentCenterY - 106 * GLOBAL_SCALE
	overlayGroup:insert(overlayDish)
	
	local overlayDishFront = display.newImage(assetPath.."dishfront.png")
	overlayDishFront.xScale, overlayDishFront.yScale = GLOBAL_SCALE * 0.58, GLOBAL_SCALE * 0.8
	overlayDishFront.x, overlayDishFront.y = display.contentCenterX, display.contentCenterY - 90 * GLOBAL_SCALE
	overlayGroup:insert(overlayDishFront)
	
	local overlayIceCreamBall = display.newImage(assetPath.."ball7.png")
	overlayIceCreamBall.xScale, overlayIceCreamBall.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	overlayIceCreamBall.x, overlayIceCreamBall.y = overlayIceCream.x, overlayIceCream.y
	overlayIceCreamBall.alpha = 0
	overlayGroup:insert(overlayIceCreamBall)
	
	local overlayHand = display.newImage(assetPath.."hand.png")
	overlayHand.xScale, overlayHand.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	overlayHand.x, overlayHand.y = display.contentCenterX + overlayHand.width * 0.6, display.contentCenterY + overlayHand.height * 0.8
	overlayGroup:insert(overlayHand)
	
	local overlayOkButton = widget.newButton(
		{
			width = 150,
			height = 150,
			defaultFile = assetPath.."okbutton-1.png",
			overFile = assetPath.."okbutton-2.png",
			onEvent = handleOverlayButton
		}
	)
	overlayOkButton.xScale, overlayOkButton.yScale = GLOBAL_SCALE * 0.8, GLOBAL_SCALE * 0.8
	overlayOkButton.x, overlayOkButton.y = display.contentCenterX, display.contentCenterY + overlayBackground.contentHeight * 0.5
	overlayOkButton.alpha = 0
	overlayOkButton.isEnabled = false
	overlayGroup:insert(overlayOkButton)
	
	local options = {}
	options.overlayIceCream = overlayIceCream
	options.overlayIceCreamCoverOpened = overlayIceCreamCoverOpened
	options.overlayHand = overlayHand
	options.overlayIceCreamBall = overlayIceCreamBall
	options.overlayDishFront = overlayDishFront
	options.overlayOkButton = overlayOkButton
	
	animateOverlay(options)
end

local function createBackground()
	local door = display.newImage(assetPath.."backgrounddoor.png")
	door.anchorY = 0
	door.xScale, door.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	door.x, door.y = display.contentCenterX, display.screenOriginY
	backgroundGroup:insert(door)
	
	local bricksLeft = display.newImage(assetPath.."bricksleft.png")
	bricksLeft.anchorX, bricksLeft.anchorY = 0, 0
	bricksLeft.yScale = GLOBAL_SCALE
	bricksLeft.width = (display.actualContentWidth - door.contentWidth) * 0.5
	bricksLeft.x, bricksLeft.y = display.screenOriginX, display.screenOriginY
	backgroundGroup:insert(bricksLeft)
	
	local bricksRight = display.newImage(assetPath.."bricksright.png")
	bricksRight.anchorx, bricksRight.anchorY = 1, 0
	bricksRight.yScale = GLOBAL_SCALE
	bricksRight.width = (display.actualContentWidth - door.contentWidth) * 0.5
	bricksRight.x, bricksRight.y = display.actualContentWidth, display.screenOriginY
	backgroundGroup:insert(bricksRight)
end

local function createGroups()
	backgroundGroup = display.newGroup()
	backgroundLayer:insert(backgroundGroup)
	
	dynamicGroup = display.newGroup()
	dynamicLayer:insert(dynamicGroup)
	
	overlayGroup = display.newGroup()
	overlayLayer:insert(overlayGroup)
end

local function initialize(event)
	event = event or {} 
	local params = event.params or {}
	manager = event.parent

	isFirstTime = params.isFirstTime
	
	failCounter = 0
	answerCounter = 0
	iceCreamNumbers = {1, 2, 3, 4, 5, 6, 7, 8, 9}
	questionMarkBoxes = {}
	screenReference = {}
	iceCreamCovers = {}
	iceCreamValues = {}
	dish = {}
	
	math.randomseed(os.time())
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
		levels = 2,
		requires = {}
	}
end  

function game:create() 
	local sceneView = self.view
	
	backgroundLayer = display.newGroup()
	sceneView:insert(backgroundLayer)
	
	dynamicLayer = display.newGroup() 
	sceneView:insert(dynamicLayer)
	
	overlayLayer = display.newGroup()
	sceneView:insert(overlayLayer)
	
	local wall = display.newImageRect(assetPath.."wall.png", display.contentWidth, display.contentHeight)
	wall.x, wall.y = display.contentCenterX, display.contentCenterY
	backgroundLayer:insert(wall)
end

function game:show(event) 
	local phase = event.phase
	
	if phase == "will" then 
		initialize(event)
		createGroups()
		createBackground()
		createCharacter()
		createFridge()
		createTimer()
		shuffleIceCream()
		generateTargetNumber()
		setIceCreamContainerPositions()
		createSticks()
		createCashMachine()
		createDish()
		createOkButton()
		createOverlay()
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