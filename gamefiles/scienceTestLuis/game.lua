----------------------------------------------- Requires
local scenePath = ... 
local folder = scenePath:match("(.-)[^%.]+$") 
local assetPath = string.gsub(folder,"[%.]","/")
local director = require("libs.helpers.director")
local widget = require("widget")
local game = director.newScene() 
----------------------------------------------- Variables
local correctCipher, codeInput, totalButtons, screenNumberTable, tutorialTextTable
local backgroundLayer, gameObjectsLayer, UILayer
local gameObjectGroup, bgGroup, overlayGroup
local lettersUsed, boxesUsed, timesLost
local minigameLevel
local gridOptions
local isFirstTime
local tapsEnabled 
local rockBoard
----------------------------------------------- Constants
local GLOBAL_SCALE = display.contentHeight / 768
local TOTAL_ATTEMPTS = 3
----------------------------------------------- Caches
local mRandom = math.random
----------------------------------------------- Functions
	
local function loseCondition()
--	local correctGroup = display.newGroup()
--	correctGroup.isVisible = false
	
--	local textOptions = {
--		text = "a = 1, b = 2, c = 3",
--		x = 10,
--		y = 0,
--		width = 550,
--		font = FONT_NAME,
--		fontSize = 60,
--		align = "center",
--	}

--	local text = display.newText(textOptions)
----	text:setFillColor(unpack(COLOR_FONT_FEEDBACK))
--	correctGroup:insert(text)
	
--	local options = {delay = nil, skipWindow = false}
--	manager.wrong({id = "group", group = correctGroup}, options)
manager.wrong()
end

local function clearScreen()
	for cleaner = 1, #screenNumberTable do
		display.remove(screenNumberTable[cleaner])
		codeInput[cleaner] = nil
	end
end

local function loseAnimation()
	transition.pause("gameTimer")
	tapsEnabled = false
	for resetter = 1, #totalButtons do
		totalButtons[resetter].fill = totalButtons[resetter].offFill
		totalButtons[resetter].isFilled = false
	end
	clearScreen()
	
	for fillingIndex = 1, #correctCipher + 1 do
		timer.performWithDelay(500 * fillingIndex, function()
			if fillingIndex <= #correctCipher then
				totalButtons[correctCipher[fillingIndex]].fill = totalButtons[correctCipher[fillingIndex]].onFill
			else
				for unfillingIndex = 1, #correctCipher do
					timer.performWithDelay(500 * unfillingIndex, function()
						totalButtons[correctCipher[unfillingIndex]].fill = totalButtons[correctCipher[unfillingIndex]].offFill	
						totalButtons[correctCipher[unfillingIndex]].isFilled = false
						if unfillingIndex == #correctCipher then
							transition.resume("gameTimer")
							tapsEnabled = true
						end
					end)
				end
			end
		end)
	end
end

local function winCondition()
	local correctNums = 0
	for answerChecker = 1, #correctCipher do
		if correctCipher[answerChecker] == codeInput[answerChecker] then
			correctNums = correctNums + 1
		end
	end
	
	if correctNums == gridOptions[minigameLevel].codeSize then
		tapsEnabled = false
		manager.correct()
	else
		transition.to(gameObjectGroup, {time = 150, x = gameObjectGroup.x + 20, y = gameObjectGroup.y + 20, iterations = 2, onComplete = function()
			transition.to(gameObjectGroup, {time = 150, x = gameObjectGroup.x - 20, y = gameObjectGroup.y - 20})
		end})
		transition.to(rockBoard, {time = 150, x = rockBoard.x + 20, y = rockBoard.y + 20, iterations = 2, onComplete = function()
			transition.to(rockBoard, {time = 150, x = rockBoard.x - 20, y = rockBoard.y - 20})
		end})
		timesLost = timesLost + 1
		timer.performWithDelay(1000, loseAnimation)
		if timesLost == TOTAL_ATTEMPTS and minigameLevel == 1 then
			tapsEnabled = false
			timer.performWithDelay(2000, loseCondition())
		end
	end
end

local function createTimer()
	local timerGroup = display.newGroup()
	gameObjectGroup:insert(timerGroup)
	
	local whiteCircle = display.newImage(assetPath.."timer_w.png")
	whiteCircle.xScale, whiteCircle.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	whiteCircle.x, whiteCircle.y = rockBoard.x - (rockBoard.contentWidth * 0.4), rockBoard.y - (rockBoard.contentHeight * 0.3)
	timerGroup:insert(whiteCircle)
	
	local orangeCircle = display.newCircle(whiteCircle.x, whiteCircle.y, whiteCircle.contentWidth * 0.5)
	orangeCircle:setFillColor(1, 140/255, 0)
	orangeCircle.xScale, orangeCircle.yScale = -1, 1
	orangeCircle.fill.effect = "filter.radialWipe"
	orangeCircle.fill.effect.center = { 0.5, 0.5 }
	orangeCircle.fill.effect.smoothness = 0
	orangeCircle.fill.effect.axisOrientation = 0.25
	orangeCircle.fill.effect.progress = 1
	timerGroup:insert(orangeCircle)
	
	local timerFrame = display.newImage(assetPath.."timer.png")
	timerFrame.xScale, timerFrame.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	timerFrame.x, timerFrame.y = rockBoard.x - (rockBoard.contentWidth * 0.4), rockBoard.y - (rockBoard.contentHeight * 0.3)
	timerGroup.alpha = 0
	timerGroup:insert(timerFrame)
	
	
	transition.to(timerGroup, {time = 1000, alpha = 1, onComplete = function()
		transition.to(orangeCircle.fill.effect, {tag = "gameTimer", time = 15000, progress = 0, onComplete = function ()
			loseCondition()
		end})			
	end})
end

local function overlayTransitions(overlayMover)	
	
	transition.to(tutorialTextTable[overlayMover], {tag = "transitionTag",time = 1000, alpha = 1, onComplete = function ()
		transition.to(tutorialTextTable[overlayMover], {tag = "transitionTag",time = 1000, alpha = 0, onComplete = function () 
		overlayMover = overlayMover + 1
		if overlayMover == #tutorialTextTable + 1 then
			overlayMover = 1
		end
		overlayTransitions(overlayMover)
		end})
	end})	
end	

local function createOverlay()
	local fadedScreen = display.newRect(display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)
	fadedScreen:setFillColor(0)
	fadedScreen.alpha = 0.9
	overlayGroup:insert(fadedScreen)
	
	local fondoOverlay = display.newImage(assetPath.."ventana_overlay.png")
	fondoOverlay.x, fondoOverlay.y = display.contentCenterX, display.contentCenterY
	overlayGroup:insert(fondoOverlay)
	
	local overlayBoard = display.newImage(assetPath.."roca_overlay.png")
	overlayBoard.x, overlayBoard.y = display.contentCenterX, display.contentCenterY
	overlayGroup:insert(overlayBoard)
	
	local function handleButtonEvent(event)
		if ("ended" == event.phase) then
			transition.cancel("transitionTag")
			transition.to(overlayGroup, {alpha = 0, time = 500, onComplete = function ()
				display.remove(overlayGroup)	
				if minigameLevel > 1 then 
					createTimer()
				end
				tapsEnabled = true
			end})
		end
	end
	
	local textOptions = {
	[1] = {text = "a = 1"},
	[2] = {text = "b = 2"},
	[3] = {text = "c = 3"},
	[4] = {text = "d = 4"},
	[5] = {text = "e = 5"},
	[6] = {text = "f = 6"}
	}
	
	for i = 1, #textOptions do
		local tutorialText = display.newText(textOptions[i])
		tutorialText.x , tutorialText.y = display.contentCenterX, display.contentCenterY 
		tutorialText.font = native.systemFont
		tutorialText:setFillColor(102/255,0/255,99/255)
		tutorialText.alpha = 0
		tutorialText.size = 96
		overlayGroup:insert(tutorialText)
		tutorialTextTable[i] = tutorialText
	end
			
		local button1 = widget.newButton({
        defaultFile = assetPath.."botonOK-1.png",
        overFile = assetPath.."botonOK-2.png",
        onEvent = handleButtonEvent
    })

	button1.x, button1.y = display.contentCenterX, display.contentCenterY + button1.contentWidth * 0.8
	button1.xScale = 0.5
	button1.yScale = 0.5
	overlayGroup:insert(button1)
	
	overlayTransitions(1)
end

local function onButtonTap(event) 
		local button = event.target
		button.fill = button.onFill
		timer.performWithDelay(100, function ()
			button.fill = button.offFill
		end)
		if tapsEnabled then
			if button.name == "ok" then
				winCondition()
			elseif button.name == "back" then
				if #boxesUsed > 0 then
					boxesUsed[#boxesUsed].isFilled = false
					boxesUsed[#boxesUsed].fill = boxesUsed[#boxesUsed].offFill	
					display.remove(boxesUsed[#boxesUsed].screenNumber)
					table.remove(boxesUsed, #boxesUsed)
					codeInput[#codeInput] = nil
				end
			end
		end
		return true
	end

local function createBackOK()
	local returnUnpressedButton = {
		type = "image",
		filename = assetPath.."btn_r2.png"
	}
	local returnPressedButton = {
		type = "image",
		filename = assetPath.."btn_r1.png"
	}
	local okUnpressedButton = {
		type = "image",
		filename = assetPath.."botonOK-1.png"
	}
	local okPressedButton = {
		type = "image",
		filename = assetPath.."botonOK-2.png"
	}
	local btnSize = 150 * 0.8 * GLOBAL_SCALE
	local backBtn = display.newImageRect(assetPath.."btn_r2.png", btnSize, btnSize)
	backBtn.x, backBtn.y = rockBoard.x - (rockBoard.contentWidth * 0.4), rockBoard.contentHeight * 0.75
	backBtn.name = "back"
	backBtn.onFill = returnPressedButton 
	backBtn.offFill = returnUnpressedButton
	backBtn:addEventListener("tap", onButtonTap)
	gameObjectGroup:insert(backBtn)
	
	local okBtn = display.newImageRect(assetPath.."botonOK-1.png", btnSize, btnSize)
	okBtn.x, okBtn.y = rockBoard.x + (rockBoard.contentWidth * 0.4), rockBoard.contentHeight * 0.75
	okBtn.name = "ok"
	okBtn.onFill = okPressedButton
	okBtn.offFill = okUnpressedButton
	okBtn:addEventListener("tap",onButtonTap)
	gameObjectGroup:insert(okBtn)
end

local function onBoxTap(event)	
	local box = event.target
	if #boxesUsed < box.code and tapsEnabled then 
		if not box.isFilled then
			box.isFilled = true
			box.fill = box.onFill
			box.wasPressedLast = true
			
			local shownNumber = display.newText(box.number, display.contentCenterX - (box.width * 1.36) + (#codeInput * 60), rockBoard.contentHeight * 0.08, native.systemFont, 60 * GLOBAL_SCALE )
			gameObjectGroup:insert(shownNumber)
			
			box.screenNumber = shownNumber
			codeInput[#codeInput + 1] = box.number
			screenNumberTable[#screenNumberTable + 1] = shownNumber
			boxesUsed[#codeInput] = box
		end
	end
	return true
end
	
local function createGrid()
	local numberOnButton = 1 
	local pressedButton = {
		type = "image",
		filename = assetPath.."boton_2.png"
	}
	local unpressedButton = {
		type = "image",
		filename = assetPath.."boton_1.png"
	}
	local gridToUse = gridOptions[minigameLevel] 
	local boxScale = gridToUse.Scale
	for rowsUsed = 1, gridToUse.rows do 
		for columnsUsed = 1, gridToUse.columns do
			local btnSize = 150 * GLOBAL_SCALE
			local boxX = (rockBoard.x - rockBoard.contentWidth * 0.45) + columnsUsed * rockBoard.contentWidth / (gridToUse.columns + 1.5)
			
			local box = display.newImageRect(assetPath.."boton_1.png", btnSize, btnSize)
			local boxY = (rockBoard.contentHeight / (gridToUse.rows + 2) * rowsUsed) + box.contentHeight * 0.8
			box.xScale, box.yScale = boxScale, boxScale
			box.x, box.y = boxX, boxY
			box.isFilled = false	
			box.onFill = pressedButton 
			box.offFill = unpressedButton
			box.code = gridToUse.codeSize
			box.number = numberOnButton
			box:addEventListener("tap", onBoxTap)
			gameObjectGroup:insert(box)
			
			local numbers = display.newText(numberOnButton,0, 0, FONT_NAME, 26 * GLOBAL_SCALE)
			numbers.x, numbers.y = boxX, boxY 
			numbers:setFillColor(0)
			totalButtons[numberOnButton] = box
			numberOnButton = numberOnButton + 1
			gameObjectGroup:insert(numbers)
			
			if minigameLevel > 2 then
				boxX = (rockBoard.x - rockBoard.contentWidth * 0.45) + (columnsUsed + 0.8) * rockBoard.contentWidth / (gridToUse.columns + 1)
				if numberOnButton > 11 then
					box.alpha = 0
					numbers.alpha = 0
				elseif numberOnButton >= 10 then
					box.x = boxX
					numbers.x = boxX
				end
			end
		end
	end
end

local function createCodes()
	local alphabet = {
		[1] = {text = "a", wasUsed = false, cipher = 1},
		[2] = {text = "b", wasUsed = false, cipher = 2},
		[3] = {text = "c", wasUsed = false, cipher = 3},
		[4] = {text = "d", wasUsed = false, cipher = 4},
		[5] = {text = "e", wasUsed = false, cipher = 5},
		[6] = {text = "f", wasUsed = false, cipher = 6},
		[7] = {text = "g", wasUsed = false, cipher = 7},
		[8] = {text = "h", wasUsed = false, cipher = 8},
		[9] = {text = "i", wasUsed = false, cipher = 9},
		[10] = {text = "j", wasUsed = false, cipher = 0}
	}
	local code = display.newText("Code: ", rockBoard.x, rockBoard.contentHeight * 0.18, native.systemFont, 36 * GLOBAL_SCALE)
	gameObjectGroup:insert(code)
	
	while lettersUsed < gridOptions[minigameLevel].codeSize do
		local rng = mRandom(gridOptions[minigameLevel].codeSize)
		if alphabet[rng].wasUsed == false then
			local letter = alphabet[rng].text
			
			alphabet[rng].wasUsed = true
			lettersUsed = lettersUsed + 1
			code.text = code.text..letter
			correctCipher[lettersUsed] = alphabet[rng].cipher
			gameObjectGroup:insert(code)
		end
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
	display.remove(gameObjectGroup)
	gameObjectGroup = nil	
	
	display.remove(bgGroup)
	bgGroup = nil
	
	display.remove(overlayGroup)
	overlayGroup = nil
	
	transition.cancel(gameTimer)
end

local function initialize(event)
	event = event or {} 
	local params = event.params or {} 
	
	isFirstTime = params.isFirstTime
	
	manager = event.parent 
	
	tapsEnabled = false
	
	minigameLevel = 2
	lettersUsed = 0
	timesLost = 0

	screenNumberTable = {}
	tutorialTextTable = {}
	correctCipher = {}
	totalButtons = {}
	boxesUsed = {}
	codeInput = {}
	gridOptions = {
		[1] = {rows = 3, columns = 2, Scale = GLOBAL_SCALE , codeSize = 4}, 
		[2] = {rows = 3, columns = 3, Scale = GLOBAL_SCALE * 0.80, codeSize = 6},
		[3] = {rows = 3, columns = 4, Scale = GLOBAL_SCALE * 0.90, codeSize = 8},
	}
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
		createCodes()
		createBackOK()
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