----------------------------------------------- progDecodeBlock, Caesar Cipher Decoding Game
local scenePath = ... 
local folder = scenePath:match("(.-)[^%.]+$") 
local assetPath = string.gsub(folder,"[%.]","/")
local extratable = require("libs.helpers.extratable")
local director = require("libs.helpers.director")
local widget = require("widget")
local game = director.newScene() 
----------------------------------------------- Variables
local correctCipher, codeInput, totalButtons
local backgroundLayer, gameObjectsLayer, UILayer
local gameObjectGroup, bgGroup, overlayGroup
local boxesUsed, retryCounter
local manager
local minigameLevel
local isFirstTime	
local tapsEnabled 
local rockBoard
----------------------------------------------- Constants
local TRANSITION_TAG = "transitionTag"
local GAME_TIMER = "gameTimer" 
local GLOBAL_SCALE = display.contentHeight / 768
local TOTAL_ATTEMPTS = 3
local MAX_BUTTONS = 11
local GAME_TOTAL_TIME = 15000
local UI_BUTTON_SIZE = 0.6 * GLOBAL_SCALE
local BOX_BUTTON_SIZE = 150 * GLOBAL_SCALE 
local DEFAULT_OK = assetPath.."botonOK-1.png"
local PRESSED_OK = assetPath.."botonOK-2.png"
local DEFAULT_BACK = assetPath.."btn_r2.png"
local PRESSED_BACK = assetPath.."btn_r1.png"
local TUTORIAL_TEXT_COLOR = {102/255, 0/255, 99/255}
local ORANGE_CIRCLE_COLOR = {1, 140/255, 0}
local TEXT_OPTIONS = {
		[1] = {text = "a", cipher = 1},
		[2] = {text = "b", cipher = 2},
		[3] = {text = "c", cipher = 3},
		[4] = {text = "d", cipher = 4},
		[5] = {text = "e", cipher = 5},
		[6] = {text = "f", cipher = 6},
		[7] = {text = "g", cipher = 7},
		[8] = {text = "h", cipher = 8},
		[9] = {text = "i", cipher = 9},
		[10] = {text = "j", cipher = 0}
	}
local GRID_OPTIONS = {
	[1] = {rows = 3, columns = 2, Scale = GLOBAL_SCALE , code = 4}, 
	[2] = {rows = 3, columns = 3, Scale = GLOBAL_SCALE * 0.80, code = 6},
	[3] = {rows = 3, columns = 4, Scale = GLOBAL_SCALE * 0.90, code = 8},
}
local PRESSED_BUTTON_FILL = {
	type = "image",
	filename = assetPath.."boton_2.png"
}
local PRESSED_BUTTON_OFFILL = {
	type = "image",
	filename = assetPath.."boton_1.png"
}
----------------------------------------------- Caches
----------------------------------------------- Functions
local function clearInGameCalculatorScreen()
	for numberRemovalIndex = 1, #codeInput do
		display.remove(codeInput[numberRemovalIndex])
		codeInput[numberRemovalIndex] = nil
	end
end
  
local function performLoseAnimation()
	transition.pause(GAME_TIMER)
	
	for resetIndex = 1, #totalButtons do
		totalButtons[resetIndex].fill = totalButtons[resetIndex].offFill
		totalButtons[resetIndex].isFilled = false
	end
	clearInGameCalculatorScreen()
	
	for fillingIndex = 1, retryCounter + 1 do
		timer.performWithDelay(500 * fillingIndex, function()
			if fillingIndex <= retryCounter then
				totalButtons[correctCipher[fillingIndex]].fill = totalButtons[correctCipher[fillingIndex]].onFill
			else
				for unfillingIndex = 1, retryCounter do
					timer.performWithDelay(500 * unfillingIndex, function()
						totalButtons[correctCipher[unfillingIndex]].fill = totalButtons[correctCipher[unfillingIndex]].offFill	
						totalButtons[correctCipher[unfillingIndex]].isFilled = false
						if unfillingIndex == retryCounter then
							if (retryCounter == TOTAL_ATTEMPTS and minigameLevel == 1) or retryCounter == GRID_OPTIONS[minigameLevel].code then
								manager.wrong()
							else
								transition.resume(GAME_TIMER)
								tapsEnabled = true
							end
						end
					end)
				end
			end
		end)
	end
end

local function checkCorrectAnswer()
		retryCounter = retryCounter >= TOTAL_ATTEMPTS and 3 or retryCounter + 1
		local correctNums = 0
		tapsEnabled = false
		
		for answerCheckerIndex = 1, #codeInput do
			if correctCipher[answerCheckerIndex] == tonumber(codeInput[answerCheckerIndex].text) then
				correctNums = correctNums + 1
			end
		end
		
		if correctNums == GRID_OPTIONS[minigameLevel].code then
			transition.pause(GAME_TIMER)
			manager.correct()
		else
			transition.to(gameObjectGroup, {time = 150, x = gameObjectGroup.x + 20 * GLOBAL_SCALE, y = gameObjectGroup.y + 20 * GLOBAL_SCALE, iterations = 4, onComplete = function()
				transition.to(gameObjectGroup, {time = 150, x = gameObjectGroup.x - 20 * GLOBAL_SCALE, y = gameObjectGroup.y - 20 * GLOBAL_SCALE})
			end})
			transition.to(rockBoard, {time = 150, x = rockBoard.x + 20 * GLOBAL_SCALE, y = rockBoard.y + 20 * GLOBAL_SCALE, iterations = 4, onComplete = function()
				transition.to(rockBoard, {time = 150, x = rockBoard.x - 20 * GLOBAL_SCALE, y = rockBoard.y - 20 * GLOBAL_SCALE, onComplete = function()
					performLoseAnimation()
				end})
			end})
		end
	return true
end

local function createTimer()
	local timerGroup = display.newGroup()
	gameObjectGroup:insert(timerGroup)
	
	local whiteCircle = display.newImage(assetPath.."timer_w.png")
	whiteCircle.xScale, whiteCircle.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	whiteCircle.x, whiteCircle.y = rockBoard.x - (rockBoard.contentWidth * 0.4), rockBoard.y - (rockBoard.contentHeight * 0.3)
	timerGroup:insert(whiteCircle)
	
	local orangeCircle = display.newCircle(whiteCircle.x, whiteCircle.y, whiteCircle.contentWidth * 0.5)
	orangeCircle:setFillColor(unpack(ORANGE_CIRCLE_COLOR))
	orangeCircle.xScale = -orangeCircle.xScale
	orangeCircle.fill.effect = "filter.radialWipe"
	orangeCircle.fill.effect.axisOrientation = 0.25
	orangeCircle.fill.effect.progress = 1
	timerGroup:insert(orangeCircle)
	
	local timerFrame = display.newImage(assetPath.."timer.png")
	timerFrame.xScale, timerFrame.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	timerFrame.x, timerFrame.y = rockBoard.x - (rockBoard.contentWidth * 0.4), rockBoard.y - (rockBoard.contentHeight * 0.3)
	timerGroup.alpha = 0
	timerGroup:insert(timerFrame)
	
	transition.to(timerGroup, {tag = GAME_TIMER, time = 1000, alpha = 1, onComplete = function()
		transition.to(orangeCircle.fill.effect, {tag = GAME_TIMER, time = GAME_TOTAL_TIME, progress = 0, onComplete = function ()
			retryCounter = GRID_OPTIONS[minigameLevel].code
			performLoseAnimation()
		end})			
	end})
end

local function transitionOverlayObjects(tutorialTextTable, currentItemIndex)	
	transition.to(tutorialTextTable[currentItemIndex], {tag = TRANSITION_TAG,time = 1000, alpha = 1, onComplete = function ()
		transition.to(tutorialTextTable[currentItemIndex], {tag = TRANSITION_TAG,time = 1000, alpha = 0, onComplete = function () 
			currentItemIndex = currentItemIndex == #tutorialTextTable and 1 or currentItemIndex + 1
			transitionOverlayObjects(tutorialTextTable, currentItemIndex)
		end})
	end})	
end	

local function handleOkOverlayButton(event)
	if "ended" == event.phase then
		transition.cancel(TRANSITION_TAG)
		transition.to(overlayGroup, {alpha = 0, time = 500, onComplete = function ()
			display.remove(overlayGroup)	
			if minigameLevel > 1 then 
				createTimer()
			end
			tapsEnabled = true
		end})
	end
end

local function createOverlay()
	local tutorialTextTable = {}
	local currentItemIndex = 1
	
	local fadedScreen = display.newRect(display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)
	fadedScreen:setFillColor(0)
	fadedScreen.alpha = 0.9
	overlayGroup:insert(fadedScreen)
	
	local overlayBackground = display.newImage(assetPath.."ventana_overlay.png")
	overlayBackground.x, overlayBackground.y = display.contentCenterX, display.contentCenterY
	overlayGroup:insert(overlayBackground)
	
	local overlayBoard = display.newImage(assetPath.."roca_overlay.png")
	overlayBoard.x, overlayBoard.y = display.contentCenterX, display.contentCenterY
	overlayGroup:insert(overlayBoard)
	
	for textSelectorIndex = 1, #TEXT_OPTIONS do
		local tutorialText = display.newText(TEXT_OPTIONS[textSelectorIndex].text.." = "..TEXT_OPTIONS[textSelectorIndex].cipher, display.contentCenterX, display.contentCenterY,  native.systemFont, 96)
		tutorialText:setFillColor(unpack(TUTORIAL_TEXT_COLOR))
		tutorialText.alpha = 0
		overlayGroup:insert(tutorialText)
		tutorialTextTable[textSelectorIndex] = tutorialText
	end
	
	local okButton = widget.newButton({
		defaultFile = DEFAULT_OK,
		overFile = PRESSED_OK,
		onEvent = handleOkOverlayButton
	})
	okButton.x, okButton.y = display.contentCenterX, display.contentCenterY + okButton.contentWidth * 0.8
	okButton.xScale, okButton.yScale = 0.5, 0.5
	overlayGroup:insert(okButton)
	
	transitionOverlayObjects(tutorialTextTable, currentItemIndex)
end

local function pressBackButton()
	if tapsEnabled then
		if #boxesUsed > 0 then
			boxesUsed[#boxesUsed].isFilled = false
			boxesUsed[#boxesUsed].fill = boxesUsed[#boxesUsed].offFill	
			display.remove(codeInput[#codeInput])
			table.remove(codeInput, #codeInput)
			table.remove(boxesUsed, #boxesUsed)
		end
	end
	return true
end

local function createUIButtons()
	local okBtn = widget.newButton({
		defaultFile = DEFAULT_OK,
		overFile = PRESSED_OK,
		onPress = checkCorrectAnswer
	})
	okBtn.xScale, okBtn.yScale = UI_BUTTON_SIZE, UI_BUTTON_SIZE 	
	okBtn.x, okBtn.y = rockBoard.x + (rockBoard.contentWidth * 0.4), rockBoard.contentHeight * 0.75
	gameObjectGroup:insert(okBtn)

	local backBtn = widget.newButton({
		defaultFile = DEFAULT_BACK,
		overFile = PRESSED_BACK,
		onPress = pressBackButton 
	})
	backBtn.x, backBtn.y = rockBoard.x - (rockBoard.contentWidth * 0.4), rockBoard.contentHeight * 0.75
	gameObjectGroup:insert(backBtn)
end

local function tapBoxButton(event)	
	local box = event.target
	if #boxesUsed < box.code and tapsEnabled and not box.isFilled then 
		box.isFilled = true
		box.fill = box.onFill
		
		local screenNumber = display.newText(box.labelValue, display.contentCenterX - (box.width * 1.36) + (#codeInput * 60), rockBoard.contentHeight * 0.08, native.systemFont, 60 * GLOBAL_SCALE)
		gameObjectGroup:insert(screenNumber)
		
		codeInput[#codeInput + 1] = screenNumber
		boxesUsed[#codeInput] = box
	end
	return true
end
	
local function createGrid()
	local labelValue = 1 
	local gridToUse = GRID_OPTIONS[minigameLevel] 
	for rowsUsed = 1, gridToUse.rows do 
		for columnsUsed = 1, gridToUse.columns do
			local boxX = (rockBoard.x - rockBoard.contentWidth * 0.45) + columnsUsed * rockBoard.contentWidth / (gridToUse.columns + 1.5)
			local boxY = (rockBoard.contentHeight / (gridToUse.rows + 2) * rowsUsed) + BOX_BUTTON_SIZE * 0.8
			local alphaToUse = 1
			
			local boxButton = display.newImageRect(assetPath.."boton_1.png", BOX_BUTTON_SIZE, BOX_BUTTON_SIZE) 
			boxButton.x, boxButton.y = boxX, boxY
			boxButton.isFilled = false	
			boxButton.onFill = PRESSED_BUTTON_FILL 
			boxButton.alpha = alphaToUse
			boxButton.offFill = PRESSED_BUTTON_OFFILL
			boxButton.code = gridToUse.code
			boxButton.labelValue = labelValue --correct
			boxButton:addEventListener("tap", tapBoxButton)
			gameObjectGroup:insert(boxButton)
			
			totalButtons[labelValue] = boxButton
			
			local boxLabel = display.newText(labelValue, 0, 0, native.systemFont, 26 * GLOBAL_SCALE)
			boxLabel.x, boxLabel.y = boxX, boxY 
			boxLabel:setFillColor(0)
			boxLabel.alpha = alphaToUse
			gameObjectGroup:insert(boxLabel)
			
			labelValue = labelValue + 1
			
			if minigameLevel > 2 then
				boxX = (rockBoard.x - rockBoard.contentWidth * 0.45) + (columnsUsed + 0.8) * rockBoard.contentWidth / (gridToUse.columns + 1)
				if labelValue > MAX_BUTTONS then
					boxButton.alpha = 0
					boxLabel.alpha = 0
				elseif labelValue >= MAX_BUTTONS - 1 then
					if labelValue == MAX_BUTTONS then
						boxLabel.text = "0"
						boxButton.labelValue = 0
					end
					boxButton.x = boxX
					boxLabel.x = boxX
				end
			end
		end
	end
end

local function createCode()
	local codetoSolve = display.newText("code: ", rockBoard.x, rockBoard.contentHeight * 0.18, native.systemFont, 36 * GLOBAL_SCALE) 
	gameObjectGroup:insert(codetoSolve)
	
	local gameCodeToSolveTable = {}
	for gameCodeIndex = 1, GRID_OPTIONS[minigameLevel].code do
		gameCodeToSolveTable[gameCodeIndex] = TEXT_OPTIONS[gameCodeIndex]
	end
	
	local textTableCopy = extratable.shuffle(gameCodeToSolveTable) 
	
	for textOptionIndex = 1, GRID_OPTIONS[minigameLevel].code do
		if textTableCopy[textOptionIndex].text == "j" and minigameLevel < 3 then
			table.remove(textTableCopy, textOptionIndex)
		elseif textTableCopy[textOptionIndex].cipher > 6 and minigameLevel == 1 then
			table.remove(textTableCopy, textOptionIndex)
		end
		local letter = textTableCopy[textOptionIndex].text
		codetoSolve.text = codetoSolve.text..letter
		correctCipher[textOptionIndex] = textTableCopy[textOptionIndex].cipher
		gameObjectGroup:insert(codetoSolve)
	end
end

local function createBG()
	rockBoard = display.newImage(assetPath.."roca.png")
	rockBoard.xScale, rockBoard.yScale = GLOBAL_SCALE, GLOBAL_SCALE 
	rockBoard.x, rockBoard.y = display.contentCenterX, display.contentCenterY
	bgGroup:insert(rockBoard)
end
	
local function createGroups()
	gameObjectGroup = display.newGroup()
	gameObjectsLayer:insert(gameObjectGroup)
	
	bgGroup = display.newGroup()
	backgroundLayer:insert(bgGroup)
	
	overlayGroup = display.newGroup()
	UILayer:insert(overlayGroup)
end

local function cleanUp()
	transition.cancel(GAME_TIMER)
	
	display.remove(gameObjectGroup)
	gameObjectGroup = nil	
	
	display.remove(bgGroup)
	bgGroup = nil
	
	display.remove(overlayGroup)
	overlayGroup = nil
	
end

local function initialize(event)
	event = event or {} 
	local params = event.params or {} 
	
	isFirstTime = params.isFirstTime
	
	manager = event.parent 
	
	tapsEnabled = false
	
	minigameLevel = 2
	retryCounter = 0

	correctCipher = {}
	totalButtons = {}
	boxesUsed = {}
	codeInput = {}
end
------------------------------------------ Module functions
function game.getInfo() 
	return {
		correctDelay = 500, 
		wrongDelay = 500, 
		name = "MinigameTony", 
		category = "science", 
		subcategories = {"materials"}, 
		age = {min = 0, max = 99}, 
		grade = {min = 0, max = 99}, 
		gamemode = "findAnswer", 
		requires = {}
	}
end 

function game:create() 
	local sceneView = self.view
	
	backgroundLayer = display.newGroup() 
	sceneView:insert(backgroundLayer)
	
	gameObjectsLayer = display.newGroup()
	sceneView:insert(gameObjectsLayer)
	
	UILayer = display.newGroup()
	sceneView:insert(UILayer)
	
	local background = display.newImageRect(assetPath.."fondo.png", display.contentWidth + 1, display.contentHeight + 1)
    background.x, background.y = display.contentCenterX, display.contentCenterY
    backgroundLayer:insert(background)
end

function game:show(event) 
	local phase = event.phase
	if phase == "will" then 
		createGroups()
		createBG()
		initialize(event)
		createOverlay()
		createGrid()
		createCode()
		createUIButtons()
	elseif phase == "did" then 
	end
end
	
function game:hide(event)
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