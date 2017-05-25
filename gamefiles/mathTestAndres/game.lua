----------------------------------------------- Requires
local scenePath = ... 
local folder = scenePath:match("(.-)[^%.]+$") 
local assetPath = string.gsub(folder,"[%.]","/") 
local director = require("libs.helpers.director")

local game = director.newScene() 
----------------------------------------------- Variables
local backgroundLayer, attemptsLayer, targetsLayer
local boardGroup, targetsGroup, timerGroup, attemptsGroup
local boardImg, progressTable, naoPortrait, naoJumping
local missingImg, correctTxt, answersList
local currentAttempt, tapsEnabled, clockTimer
local manager, isFirstTime
local backIndex, middleIndex, frontIndex
----------------------------------------------- Constants
local TRANSITION_TAG = "gameAnimation"
local BANNER_SCALE = (display.contentWidth * 0.1) / 98
local GAME_TIME = 60
local TOTAL_ATTEMPTS = 5
local NUM_TARGETS = 3
local OPTIONS_LEFTPOS = {
	[1] = {
		[1] = {x = display.contentWidth * 0.45, y = display.contentHeight * 0.85, zIndex = 1},
		[2] = {x = display.contentWidth * 0.10, y = display.contentHeight * 0.65, zIndex = 3},
		[3] = {x = display.contentWidth * 0.30, y = display.contentHeight * 0.75, zIndex = 2}
	},
	[2] =  {
		[1] = {x = display.contentWidth * 0.15, y = display.contentHeight * 0.85, zIndex = 1},
		[2] = {x = display.contentWidth * 0.45, y = display.contentHeight * 0.80, zIndex = 2},
		[3] = {x = display.contentWidth * 0.30, y = display.contentHeight * 0.65, zIndex = 3}
	}
}
local OPTIONS_RIGHTPOS = {
	[1] = {
		[1] = {x = display.contentWidth * 0.60, y = display.contentHeight * 0.65, zIndex = 3},
		[2] = {x = display.contentWidth * 0.70, y = display.contentHeight * 0.80, zIndex = 2},
		[3] = {x = display.contentWidth * 0.90, y = display.contentHeight * 0.85, zIndex = 1}
	},
	[2] =  {
		[1] = {x = display.contentWidth * 0.90, y = display.contentHeight * 0.85, zIndex = 1},
		[2] = {x = display.contentWidth * 0.60, y = display.contentHeight * 0.75, zIndex = 2},
		[3] = {x = display.contentWidth * 0.75, y = display.contentHeight * 0.65, zIndex = 3}
	}
}
----------------------------------------------- Caches
local mathRandom = math.random
----------------------------------------------- Functions
local function animateRotation(self)
	director.to(scenePath, self, {tag = TRANSITION_TAG, time = 1000, rotation = self.rotation + 360, onComplete = function()
		animateRotation(self)
	end})
end

local function shuffleTable(table)
	for tableIndex = 1, #table do
        local randomizer = mathRandom(#table)
        table[tableIndex], table[randomizer] = table[randomizer], table[tableIndex]
	end
	
	return table
end

local function arrangeZIndex(selectedLayer, objectToInsert)
	if selectedLayer.zIndex == 1 then
		frontIndex:insert(objectToInsert)
	elseif selectedLayer.zIndex == 2 then
		middleIndex:insert(objectToInsert)
	elseif selectedLayer.zIndex == 3 then
		backIndex:insert(objectToInsert)
	end
end

local function createQuestion()
	local firstNumber = mathRandom(1, 9)
	local secondNumber = mathRandom(1, 9)
	local correctAnswer = firstNumber + secondNumber
	
	missingImg = display.newImage(assetPath.."missing.png")
	
	local answersList = {
		[1] = {number = correctAnswer, isCorrect = true},
		[2] = {number = correctAnswer - mathRandom(1, 4), isCorrect = false},
		[3] = {number = correctAnswer + mathRandom(1, 4), isCorrect = false}
	}
	
	answersList = shuffleTable(answersList)
	
	local boardList = {
		[1] = {text = firstNumber},
		[2] = {text = "+"},
		[3] = {text = secondNumber},
		[4] = {text = "="},
		[5] = {text = missingImg}
	}
	
	display.remove(boardGroup)
	boardGroup = display.newGroup()
	backgroundLayer:insert(boardGroup)
	
	for boardIndex = 1, #boardList do
		if boardIndex == #boardList then
			missingImg:scale((display.contentWidth * 0.08) / missingImg.width, (display.contentWidth * 0.08) / missingImg.width)
			missingImg.x, missingImg.y = display.contentCenterX - ((#boardList / 2) - 0.5) * 75 + 75 * (boardIndex - 1), display.screenOriginY + 90
			boardGroup:insert(missingImg)
			
			correctTxt = display.newText(correctAnswer, 0, 0, 75, 0, native.systemFont, 70)
			correctTxt.alpha = 0
			correctTxt.x, correctTxt.y = missingImg.x, missingImg.y
			boardGroup:insert(correctTxt)
		else
			local boardTxt = display.newText(boardList[boardIndex].text, 0, 0, 75, 0, native.systemFont, 70)
			boardTxt.x, boardTxt.y = display.contentCenterX - ((#boardList / 2) - 0.5) * 75 + 75 * (boardIndex - 1), display.screenOriginY + 90
			boardGroup:insert(boardTxt)
		end
	end
	
	return answersList
end

local function createAttempts()
	local attemptFill = {type = "image", filename = assetPath.."progress.png"}
	local attemptRight = {type = "image", filename = assetPath.."progress_right.png"}
	local attemptWrong = {type = "image", filename = assetPath.."progress_wrong.png"}
	progressTable = {}
	
	attemptsGroup = display.newGroup()
	attemptsLayer:insert(attemptsGroup)
	
	for attemptIndex = 1, TOTAL_ATTEMPTS do
		local attemptImg = display.newRect(0, 0, 50, 50)
		attemptImg:scale((display.contentWidth * 0.05) / attemptImg.width, (display.contentWidth * 0.05) / attemptImg.width)
		attemptImg.x, attemptImg.y = display.contentCenterX - ((TOTAL_ATTEMPTS/2) - 0.5) * attemptImg.contentWidth + attemptImg.contentWidth * (attemptIndex - 1), display.screenOriginY + display.contentHeight - 40
		attemptImg.fill = attemptFill
		attemptImg.rightFill = attemptRight
		attemptImg.wrongFill = attemptWrong
		attemptsGroup:insert(attemptImg)
		
		progressTable[attemptIndex] = attemptImg
	end
end

local function createAttemptsSprite()
	local options = {width = 45, height = 76, numFrames = 20, sheetContentWidth = 225, sheetContentHeight = 304}
	local sequenceData = {name = "jumping", start = 1, count = 20, time = 1000, loopCount = 1}
	local imageSheet = graphics.newImageSheet(assetPath.."Spritesheet/naojump.png", options)
	
	naoJumping = display.newSprite(imageSheet, sequenceData)
	naoJumping.anchorY = 0.8
	naoJumping.x, naoJumping.y = progressTable[1].x, progressTable[1].y
	attemptsGroup:insert(naoJumping)
end

local function createNao()
	naoPortrait = display.newImage(assetPath.."nao.png")
	naoPortrait:scale((display.contentWidth * 0.10) / naoPortrait.width, (display.contentWidth * 0.10) / naoPortrait.width)
	naoPortrait.anchorY = 1
	naoPortrait.x, naoPortrait.y = display.contentWidth * 0.20, display.contentHeight * 0.85
	targetsLayer:insert(naoPortrait)
end
	
local function moveNao()
	local naoXScale = (display.contentWidth * 0.10) / naoPortrait.width
	
	if currentAttempt % 2 == 0 then
		director.to(scenePath, naoPortrait, {delay = 1500, time = 500, x = display.contentWidth * 0.80, y = display.contentHeight * 0.85})
		naoPortrait.xScale = -naoXScale
		targetsLayer:insert(naoPortrait)
	else
		director.to(scenePath, naoPortrait, {delay = 1500, time = 500, x = display.contentWidth * 0.20, y = display.contentHeight * 0.85})
		naoPortrait.xScale = naoXScale
		targetsLayer:insert(naoPortrait)
	end
end	

local function removeTargets()
	director.to(scenePath, targetsGroup, {delay = 1500, time = 500, alpha = 0, onComplete = function() 
		display.remove(targetsGroup) 
	end})
end

local function onSignTap(event)
	local selectedTarget = event.target
	
	if tapsEnabled then
		tapsEnabled = false
		local powerCubeImg = display.newImage(assetPath.."powercube.png")
		powerCubeImg.alpha = 0
		powerCubeImg.anchorY = 1
		powerCubeImg.x, powerCubeImg.y = selectedTarget.x, selectedTarget.y - selectedTarget.contentHeight
		targetsGroup:insert(powerCubeImg)
		
		arrangeZIndex(selectedTarget, naoPortrait)
		director.to(scenePath, naoPortrait, {time = 800, x = selectedTarget.x, y = selectedTarget.y, onComplete = function() moveNao() end})
		
		if selectedTarget.isCorrect and currentAttempt <= 5 then
			director.to(scenePath, powerCubeImg, {time = 500, alpha = 1, y = powerCubeImg.y - 20, onComplete = function()
				removeTargets()
			end})
			progressTable[currentAttempt].fill = progressTable[currentAttempt].rightFill
		elseif currentAttempt <= 5 then
			removeTargets()
			progressTable[currentAttempt].fill = progressTable[currentAttempt].wrongFill
		end
		
		currentAttempt = currentAttempt + 1
		
		if currentAttempt <= TOTAL_ATTEMPTS then
			director.to(scenePath, naoJumping, {time = 1000, x = progressTable[currentAttempt].x, y = progressTable[currentAttempt].y, onStart = function() naoJumping:play() end})
		else
			director.to(scenePath, naoJumping, {time = 1000, alpha = 0})
		end
		
		director.to(scenePath, missingImg, {time = 300, alpha = 0})
		director.to(scenePath, correctTxt, {time = 500, alpha = 1})
		

		director.to(scenePath, powerCubeImg, {delay = 3100, time = 500, alpha = 0, onComplete = function()					
			if currentAttempt <= TOTAL_ATTEMPTS then
				answersList = createQuestion()
				selectedTarget:callCreateTargets()
			else
				manager.correct()
			end
		end})
	end
	
	return true
end

local function createTargets()
	display.remove(targetsGroup) 
	targetsGroup = display.newGroup()
	targetsLayer:insert(targetsGroup)
	
	backIndex = display.newGroup()
	targetsGroup:insert(backIndex)
	
	middleIndex = display.newGroup()
	targetsGroup:insert(middleIndex)
	
	frontIndex = display.newGroup()
	targetsGroup:insert(frontIndex)
	
	targetsGroup.alpha = 0
	local targetPos = mathRandom(1,2)
	
	for targetIndex = 1, NUM_TARGETS do	
		local targetBoxGroup = display.newGroup()
		targetBoxGroup.anchorChildren = true
		targetBoxGroup.anchorY = 2
		
		if currentAttempt % 2 == 0 then
			targetBoxGroup.x, targetBoxGroup.y = OPTIONS_LEFTPOS[targetPos][targetIndex].x, OPTIONS_LEFTPOS[targetPos][targetIndex].y
			targetBoxGroup.zIndex = OPTIONS_LEFTPOS[targetPos][targetIndex].zIndex
		else
			targetBoxGroup.x, targetBoxGroup.y = OPTIONS_RIGHTPOS[targetPos][targetIndex].x, OPTIONS_RIGHTPOS[targetPos][targetIndex].y
			targetBoxGroup.zIndex = OPTIONS_RIGHTPOS[targetPos][targetIndex].zIndex
		end
		
		arrangeZIndex(targetBoxGroup, targetBoxGroup)

		local targetImg = display.newImage(assetPath.."answers.png")
		targetImg:scale((display.contentWidth * 0.13) / targetImg.width, (display.contentWidth * 0.13) / targetImg.width)
		targetBoxGroup:insert(targetImg)
		
		local targetTxt = display.newText(answersList[targetIndex].number, 0, -targetBoxGroup.contentHeight * 0.16, native.systemFont, 60)
		targetBoxGroup.isCorrect = answersList[targetIndex].isCorrect
		targetBoxGroup:insert(targetTxt)
		
		tapsEnabled = true
		targetBoxGroup:addEventListener("tap", onSignTap)
		
		function targetBoxGroup:callCreateTargets()
			createTargets()
		end
	end   
    
	director.to(scenePath, targetsGroup, {time = 500, alpha = 1})
end

local function createTimer()
	timerGroup = display.newGroup()
	backgroundLayer:insert(timerGroup)
	
	local timerImg = display.newImage(assetPath.."timer.png")
	timerImg:scale((display.contentWidth * 0.15) / timerImg.width, (display.contentWidth * 0.15) / timerImg.width)
	timerImg.x, timerImg.y = display.screenOriginX + timerImg.width, display.screenOriginY + display.contentHeight - timerImg.height
	timerGroup:insert(timerImg)
	
	local timerHand = display.newImage(assetPath.."hand.png")
	timerHand:scale((display.contentWidth * 0.008) / timerHand.width, (display.contentWidth * 0.008) / timerHand.width)
	timerHand.anchorY = 0.8
	timerHand.x, timerHand.y = timerImg.x - timerImg.contentWidth * 0.25, timerImg.y + timerImg.contentWidth * 0.03
	timerGroup:insert(timerHand)
	
	animateRotation(timerHand)
	
	local secondsRemaining = GAME_TIME
	local timerTxt = display.newText(secondsRemaining, 0, 0, native.systemFont, 35)
	timerTxt.x, timerTxt.y = timerImg.x + timerImg.contentWidth * 0.15, timerImg.y + timerImg.contentHeight * 0.05
	timerTxt:setFillColor(0, 0, 0)
	timerGroup:insert(timerTxt)
	
	clockTimer = director.performWithDelay(scenePath, 1000, function()
		secondsRemaining = secondsRemaining - 1
		timerTxt.text = secondsRemaining
		if secondsRemaining == 0 then
			transition.cancel(TRANSITION_TAG)
			timer.cancel(clockTimer)
			manager.wrong()
		end
	end, secondsRemaining)
end

local function cleanVariables()
		timer.cancel(clockTimer)
		
		transition.cancel(TRANSITION_TAG)
	
		display.remove(targetsGroup)
		targetsGroup = nil
		
		display.remove(boardGroup)
		boardGroup = nil
		
		display.remove(timerGroup)
		timerGroup = nil
		
		display.remove(attemptsGroup)
		attemptsGroup = nil
		
		display.remove(frontIndex)
		frontIndex = nil
		
		display.remove(middleIndex)
		middleIndex = nil
		
		display.remove(backIndex)
		backIndex = nil
end

local function initialize(event)
	event = event or {} 
	local params = event.params or {}
    local sceneParams = params.sceneParams

	isFirstTime = params.isFirstTime 
	manager = event.parent 
	
	currentAttempt = 1
	tapsEnabled = true
	
	answersList = createQuestion()
end
----------------------------------------------- Module functions
function game.getInfo() 
	return {
		correctDelay = 500, 
		wrongDelay = 500, 
		name = "MinigameAndres", 
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
	
	attemptsLayer = display.newGroup() 
	sceneView:insert(attemptsLayer)
	
	targetsLayer = display.newGroup() 
	sceneView:insert(targetsLayer)
	
	local backgroundImg = display.newImage(assetPath.."bgd.png", display.contentCenterX, display.contentCenterY)
	backgroundImg.width, backgroundImg.height = display.viewableContentWidth + 2, display.viewableContentHeight + 2
	backgroundLayer:insert(backgroundImg)

	local bannerTable = {
		[1] = {x = display.contentWidth * 0.9, xScale = BANNER_SCALE},
		[2] = {x = display.contentWidth * 0.1, xScale = -BANNER_SCALE}
	}
	
	for bannerIndex = 1, #bannerTable do
		local bannerImg = display.newImage(assetPath.."flag.png")
		bannerImg:scale(bannerTable[bannerIndex].xScale, BANNER_SCALE)
		bannerImg.anchorY = 1
		bannerImg.x, bannerImg.y = bannerTable[bannerIndex].x, display.contentHeight * 0.54
		backgroundLayer:insert(bannerImg)
	end
	
	boardImg = display.newImage(assetPath.."board.png")
	boardImg:scale((display.contentWidth * 0.45) / boardImg.width, (display.contentWidth * 0.45) / boardImg.width)
	boardImg.x, boardImg.y = display.contentCenterX, display.screenOriginY + 100
	backgroundLayer:insert(boardImg)
end

function game:show(event) 
	local sceneView = self.view
	local phase = event.phase
	
	if phase == "will" then 
		initialize(event)		
		createAttempts()
		createAttemptsSprite()
		createNao()
		createTargets()
		createTimer()
	elseif phase == "did" then 
		
	end
end

function game:hide(event)
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then 
		
	elseif phase == "did" then 
		cleanVariables()
	end
end

----------------------------------------------- Execution
game:addEventListener("create")
game:addEventListener("hide")
game:addEventListener("show")

return game