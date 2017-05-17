----------------------------------------------- Requires
local scenePath = ... 
local folder = scenePath:match("(.-)[^%.]+$") 
local assetPath = string.gsub(folder,"[%.]","/") 
local localization = require("libs.helpers.localization")
local director = require("libs.helpers.director")

local game = director.newScene() 
----------------------------------------------- Variables
local backgroundLayer, attemptsLayer, targetsLayer
local boardGroup, targetsGroup, timerGroup, attemptsGroup
local boardImg, timerTxt, progressTable, naoPortrait, naoJumping
local missingImg, correctTxt, answersList
local secondsRemaining, currentAttempt, tapsEnabled
local manager, isFirstTime
----------------------------------------------- Constants
local BANNER_DIMENSIONS = {x = 98, y = 220}
local TOTAL_ATTEMPTS = 5
local NUM_TARGETS = 3
local OPTIONS_LEFTPOS = {
	[1] = { 
		[1] = { x = display.contentWidth * 0.45, y = display.contentHeight * 0.90 },
		[2] = { x = display.contentWidth * 0.10, y = display.contentHeight * 0.70 },
		[3] = { x = display.contentWidth * 0.30, y = display.contentHeight * 0.85 }
	},
	[2] =  { 
		[1] = { x = display.contentWidth * 0.15, y = display.contentHeight * 0.85 },
		[2] = { x = display.contentWidth * 0.45, y = display.contentHeight * 0.75 },
		[3] = { x = display.contentWidth * 0.30, y = display.contentHeight * 0.65 }
	}
}
local OPTIONS_RIGHTPOS = {
	[1] = { 
		[1] = { x = display.contentWidth * 0.60, y = display.contentHeight * 0.70 },
		[2] = { x = display.contentWidth * 0.70, y = display.contentHeight * 0.85 },
		[3] = { x = display.contentWidth * 0.90, y = display.contentHeight * 0.90 }
	},
	[2] =  { 
		[1] = { x = display.contentWidth * 0.90, y = display.contentHeight * 0.85 },
		[2] = { x = display.contentWidth * 0.60, y = display.contentHeight * 0.75 },
		[3] = { x = display.contentWidth * 0.75, y = display.contentHeight * 0.65 }
	}
}
----------------------------------------------- Caches

----------------------------------------------- Functions
local function createAttempts()
	local attemptFill = { type = "image", filename = assetPath.."progress.png" }
	local attemptRight = { type = "image", filename = assetPath.."progress_right.png" }
	local attemptWrong = { type = "image", filename = assetPath.."progress_wrong.png" }
	progressTable = {}
	
	attemptsGroup = display.newGroup()
	attemptsLayer:insert(attemptsGroup)
	
	for attemptIndex = 1, TOTAL_ATTEMPTS do
		local attemptImg = display.newRect(0, 0, 50, 50)
		attemptImg:scale((display.contentWidth * 0.05) / attemptImg.width, (display.contentWidth * 0.05) / attemptImg.width)
		attemptImg.x = display.contentCenterX - ((TOTAL_ATTEMPTS/2) - 0.5) * attemptImg.contentWidth + attemptImg.contentWidth * (attemptIndex - 1)
		attemptImg.y = display.screenOriginY + display.contentHeight - 60
		attemptImg.fill = attemptFill
		attemptImg.rightFill = attemptRight
		attemptImg.wrongFill = attemptWrong
		attemptsGroup:insert(attemptImg)
		
		progressTable[attemptIndex] = attemptImg
	end
end

local function createNaoSprite()
	local options = { width = 45, height = 76, numFrames = 20, sheetContentWidth = 225, sheetContentHeight = 304 }
	local sequenceData = { name = "jumping", start = 1, count = 20, time = 1000, loopCount = 1 }
	local imageSheet = graphics.newImageSheet(assetPath.."Spritesheet/naojump.png", options)
	
	naoJumping = display.newSprite(imageSheet, sequenceData)
	attemptsGroup:insert(naoJumping)
	naoJumping.anchorY = 0.8
	naoJumping.x = progressTable[1].x
	naoJumping.y = progressTable[2].y
end

local function createQuestion()
	local firstNumber = math.random(1, 9)
	local secondNumber = math.random(1, 9)
	local correctAnswer = firstNumber + secondNumber
	missingImg = display.newImage(assetPath.."missing.png")
	
	local answersList = {
		[1] = {number = correctAnswer},
		[2] = {number = correctAnswer - math.random(1, 4)},
		[3] = {number = correctAnswer + math.random(1, 4)}
	}
	
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
			missingImg.x = display.contentCenterX - ((#boardList / 2) - 0.5) * 75 + 75 * (boardIndex - 1)
			missingImg.y = display.screenOriginY + 90
			boardGroup:insert(missingImg)
			correctTxt = display.newText(correctAnswer, 0, 0, 75, 0, native.systemFont, 70)
			correctTxt.x = missingImg.x
			correctTxt.y = missingImg.y
			correctTxt.alpha = 0
			boardGroup:insert(correctTxt)
		else
			local boardTxt = display.newText(boardList[boardIndex].text, 0, 0, 75, 0, native.systemFont, 70)
			boardTxt.x = display.contentCenterX - ((#boardList / 2) - 0.5) * 75 + 75 * (boardIndex - 1)
			boardTxt.y = display.screenOriginY + 90
			boardGroup:insert(boardTxt)
		end
	end
	return answersList
end

local function createNao()
	naoPortrait = display.newImage(assetPath.."nao.png")
	naoPortrait:scale((display.contentWidth * 0.10) / naoPortrait.width, (display.contentWidth * 0.10) / naoPortrait.width)
	naoPortrait.anchorY = 1
	naoPortrait.x = display.contentWidth * 0.20
	naoPortrait.y = display.contentHeight * 0.85
	backgroundLayer:insert(naoPortrait)
end
	
local function moveNao(targetX, targetY)
	director.to(scenePath, naoPortrait, { time = 800, x = targetX, y = targetY })
	
	if currentAttempt % 2 == 0 then
		director.performWithDelay(scenePath, 1500,
			function()
				director.to(scenePath, naoPortrait, { time = 500, x = display.contentWidth * 0.20, y = display.contentHeight * 0.85 })
				naoPortrait.xScale = (display.contentWidth * 0.10) / naoPortrait.width
			end
		)
	else
		director.performWithDelay(scenePath, 1500,
			function()
				director.to(scenePath, naoPortrait, { time = 500, x = display.contentWidth * 0.80, y = display.contentHeight * 0.85 })
				naoPortrait.xScale = -(display.contentWidth * 0.10) / naoPortrait.width
			end
		)
	end
end	

local function onSignTap(event)
	if tapsEnabled then
		tapsEnabled = false
		local powerCubeImg = display.newImage(assetPath.."powercube.png")
		powerCubeImg.alpha = 0
		powerCubeImg.anchorY = 1
		powerCubeImg.x = event.target.realX
		powerCubeImg.y = event.target.realY - event.target.contentHeight
		
		moveNao(event.target.realX, event.target.realY)
		
		if event.target.isCorrect and currentAttempt <= 5 then
			director.performWithDelay(scenePath, 1000,
				function()
					director.to(scenePath, powerCubeImg, { 
						time = 500, 
						alpha = 1, 
						y = powerCubeImg.y - 20,
						onComplete = function()
							director.to(scenePath, targetsGroup, { time = 500, alpha = 0, onComplete = function() display.remove(targetsGroup) end })
						end
					})
				end
			)
			progressTable[currentAttempt].fill = progressTable[currentAttempt].rightFill
		elseif currentAttempt <= 5 then
			progressTable[currentAttempt].fill = progressTable[currentAttempt].wrongFill
			director.to(scenePath, targetsGroup, { time = 1000, alpha = 0, onComplete = function() display.remove(targetsGroup) end })
		end
		
		currentAttempt = currentAttempt + 1
		
		director.to(scenePath, missingImg, { time = 300, alpha = 0})
		director.to(scenePath, correctTxt, { time = 500, alpha = 1})
		director.to(scenePath, naoJumping, { time = 1000, x = progressTable[currentAttempt].x, y = progressTable[currentAttempt].y, onStart = function() naoJumping:play() end })
		
		director.performWithDelay(scenePath, 2500, 
			function()		
				director.to(scenePath, powerCubeImg, { time = 500, alpha = 0, onComplete = function() display.remove(powerCubeImg) end  })
				if currentAttempt <= TOTAL_ATTEMPTS then
					local answersList = createQuestion()
					event.target:callCreateTarget(answersList)
				else
					manager.correct()
				end
			end
		)
		
	end
end

local function createTargets(answersList)
	targetsGroup = display.newGroup()
	targetsGroup.alpha = 0
	targetsLayer:insert(targetsGroup)
	local targetPos = math.random(1,2)
	
	for targetIndex = 1, NUM_TARGETS do	
		local targetBoxGroup = display.newGroup()
		targetBoxGroup.anchorChildren = true
		targetBoxGroup.anchorY = 1
		if currentAttempt % 2 == 0 then
			targetBoxGroup.x = OPTIONS_LEFTPOS[targetPos][targetIndex].x
			targetBoxGroup.y = OPTIONS_LEFTPOS[targetPos][targetIndex].y
		else
			targetBoxGroup.x = OPTIONS_RIGHTPOS[targetPos][targetIndex].x
			targetBoxGroup.y = OPTIONS_RIGHTPOS[targetPos][targetIndex].y
		end
		targetsGroup:insert(targetBoxGroup)
		
		local targetImg = display.newImage(assetPath.."answers.png")
		targetImg:scale((display.contentWidth * 0.13) / targetImg.width, (display.contentWidth * 0.13) / targetImg.width)
		targetImg:addEventListener("tap", onSignTap)
		targetImg.realX = targetBoxGroup.x
		targetImg.realY = targetBoxGroup.y
		tapsEnabled = true
		if targetIndex == 1 then
			targetImg.isCorrect = true
		else
			targetImg.isCorrect = false
		end
		targetBoxGroup:insert(targetImg)
		
		local targetTxt = display.newText(answersList[targetIndex].number, 0, -targetBoxGroup.contentHeight * 0.16, native.systemFont, 60)
		targetBoxGroup:insert(targetTxt)
		
		function targetImg:callCreateTarget(answersList)
			createTargets(answersList)
		end
	end       
	director.to(scenePath, targetsGroup, { time = 500, alpha = 1 })
end

local function createTimer()
	timerGroup = display.newGroup()
	backgroundLayer:insert(timerGroup)
	
	local timerImg = display.newImage(assetPath.."timer.png")
	timerImg:scale((display.contentWidth * 0.15) / timerImg.width, (display.contentWidth * 0.15) / timerImg.width)
	timerImg.x = display.screenOriginX + timerImg.width
	timerImg.y = display.screenOriginY + display.contentHeight - timerImg.height
	timerGroup:insert(timerImg)
	
	local timerHand = display.newImage(assetPath.."hand.png")
	timerHand:scale((display.contentWidth * 0.008) / timerHand.width, (display.contentWidth * 0.008) / timerHand.width)
	timerHand.anchorY = 0.8
	timerHand.x = timerImg.x - timerImg.contentWidth * 0.25
	timerHand.y = timerImg.y + timerImg.contentWidth * 0.03
	director.to(scenePath, timerHand, { time = 1000, rotation = 360, iterations = 60 })
	timerGroup:insert(timerHand)
	
	timerTxt = display.newText(secondsRemaining, 0, 0, native.systemFont, 35)
	timerTxt:setFillColor(0, 0, 0)
	timerTxt.x = timerImg.x + timerImg.contentWidth * 0.15
	timerTxt.y = timerImg.y + timerImg.contentHeight * 0.05
	timerGroup:insert(timerTxt)
	
	if secondsRemaining > 0 then
		director.performWithDelay(scenePath, 1000, 
			function()
				secondsRemaining = secondsRemaining - 1
				timerTxt.text = secondsRemaining
				if secondsRemaining == 10 then
					timerTxt:setFillColor(1, 0, 0)
				elseif secondsRemaining == 0 then
					manager.wrong()
				end
			end
		, secondsRemaining)
	end
end

local function cleanVariables()
		display.remove(targetsGroup)
		targetsGroup = nil
		
		display.remove(boardGroup)
		boardGroup = nil
		
		display.remove(timerGroup)
		timerGroup = nil
		
		display.remove(attemptsGroup)
		attemptsGroup = nil
end

local function initialize(event)
	event = event or {} 
	local params = event.params or {}
    local sceneParams = params.sceneParams

	isFirstTime = params.isFirstTime 
	manager = event.parent 
	
	currentAttempt = 1
	secondsRemaining = 60
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

	local backgroundImg = display.newImage(assetPath.."bgd.png", display.contentCenterX,display.contentCenterY)
	backgroundImg.height = display.contentHeight
	backgroundImg.width = display.contentWidth
	backgroundLayer:insert(backgroundImg)

	local bannerTable = {
		[1] = {x = display.contentWidth * 0.9, xScale = (display.contentWidth * 0.1) / BANNER_DIMENSIONS.x},
		[2] = {x = display.contentWidth * 0.1, xScale = -(display.contentWidth * 0.1) / BANNER_DIMENSIONS.x}
	}
	
	for bannerIndex = 1, #bannerTable do
		local bannerImg = display.newImage(assetPath.."flag.png")
		bannerImg.xScale = bannerTable[bannerIndex].xScale
		bannerImg.yScale = (display.contentWidth * 0.1) / BANNER_DIMENSIONS.x
		bannerImg.anchorY = 1
		bannerImg.x = bannerTable[bannerIndex].x
		bannerImg.y = display.contentHeight * 0.54
		backgroundLayer:insert(bannerImg)
	end
	
	boardImg = display.newImage(assetPath.."board.png")
	boardImg:scale((display.contentWidth * 0.45) / boardImg.width, (display.contentWidth * 0.45) / boardImg.width)
	boardImg.x = display.contentCenterX
	boardImg.y = display.screenOriginY + 100
	backgroundLayer:insert(boardImg)
end

function game:show(event) 
	local sceneView = self.view
	local phase = event.phase
	
	if phase == "will" then 
		initialize(event)		
		createAttempts()
		createNao()
		createNaoSprite()
		createTargets(answersList)
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