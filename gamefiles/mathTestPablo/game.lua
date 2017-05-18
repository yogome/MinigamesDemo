----------------------------------------------- Requires
local scenePath = ... 
local folder = scenePath:match("(.-)[^%.]+$") 
local assetPath = string.gsub(folder,"[%.]","/") 
local localization = require( "libs.helpers.localization" )
local director = require( "libs.helpers.director" )

local game = director.newScene() 
----------------------------------------------- Variables
local backgroundLayer, boardLayer, dummyLayer, groundLayer
local star
local boardGroup, dummyGroup, clockGroup, progressBarGroup, naoJumps
local maxNumberOperation, minNumberOperation, resultOperation, alternativeNumberA, alternativeNumberB, dummyResults, dummyNumbers
local progressTable
local counterStage
local isFirstTime, manager
----------------------------------------------- Constants
local ATTEMPT_NUMBER = 5
local LEVEL_SELECT = {
	[1] = 10,
	[2] = 20,
	[3] = 30,
	[4] = 50,
	[5] = 99
}
local POSITIONS = {
	[1] = {x = display.contentWidth * 0.30},
	[2] = {x = display.contentWidth * 0.50},
	[3] = {x = display.contentWidth * 0.70},	
	[4] = {x = display.contentWidth * 0.90}
}
	
local boardElementsTable = {
	[1] = {path = "number.png", x = 0, y = 0},
	[2] = {path = "symbol2.png", x = 0, y = 0},
	[3] = {path = "number.png", x = 0, y = 0},
	[4] = {path = "symbol4.png", x = 0, y = 0},
	[5] = {path = "question.png", x = 0, y = 0}
}

----------------------------------------------- Caches
local mathRandom = math.random
local tableSort = table.sort
----------------------------------------------- Functions
local function cleanUp()
	display.remove(dummyGroup)
	dummyGroup = nil
	display.remove(boardGroup)
	boardGroup = nil
	display.remove(clockGroup)
	clockGroup = nil
	display.remove(progressBarGroup)	
	progressBarGroup = nil
--	timer.cancel(clockTimer)
--	display.remove(timerGroup)
--	timerGroup = nil
end

local function randomNumbers()
	if alternativeNumberA == maxNumberOperation and alternativeNumberA == minNumberOperation and alternativeNumberA == resultOperation and alternativeNumberA == alternativeNumberB then
		alternativeNumberA = math.random(LEVEL_SELECT[2])
		randomNumbers()
	elseif alternativeNumberB == maxNumberOperation and alternativeNumberB == minNumberOperation and alternativeNumberB == alternativeNumberA and alternativeNumberB == resultOperation then
		alternativeNumberB = math.random(LEVEL_SELECT[2])
		randomNumbers()
	end
	
	dummyResults = {
		[1] = {text = alternativeNumberA},
		[2] = {text = resultOperation},
		[3] = {text = alternativeNumberB}
	}

	dummyNumbers = {
		[1] = {text = maxNumberOperation},
		[2] = {text = minNumberOperation},
		[3] = {text = ""}
	}
end

local function showBoard()
	display.remove(boardGroup)
	
	boardGroup = display.newGroup()
	backgroundLayer:insert(boardGroup)
	boardGroup.x = display.contentCenterX
	boardGroup.y = display.contentHeight * 0.22
	
	local board = display.newImage(assetPath.."board.png")
	board:scale(display.contentWidth * 0.7 / board.width, display.contentWidth * 0.55 / board.width)
	boardGroup:insert(board)

	local textCounter = 0
	for index = 1, #boardElementsTable do
		local boardElement = display.newImage(assetPath.. boardElementsTable[index].path)
		boardElement:scale(0.8,0.8)
		boardElement.x = board.x - board.contentWidth * 0.5 + (board.contentWidth / (#boardElementsTable + 1) * index)
		boardElement.y = board.y + board.contentHeight * 0.1
		boardGroup:insert(boardElement)
		
		if index % 2 ~= 0 then
			textCounter = textCounter + 1
			
			local numberTextBoard = display.newText(dummyNumbers[textCounter].text, 0, 0, native.systemFont, 40)
			numberTextBoard.x = boardElement.x 
			numberTextBoard.y = boardElement.y 
			boardGroup:insert(numberTextBoard)
		end
	end
end

local function createProgressBar()
	progressBarGroup = display.newGroup()
	groundLayer:insert(progressBarGroup)
	
	local attemptFill = {type = "image", filename = assetPath.."progress.png"}
	local attemptRight = {type = "image", filename = assetPath.."progress_right.png"}
	local attempWrong = {type = "image", filename = assetPath.."progress_wrong.png"}
	progressTable = {}
	
	for attemptIndex = 1, ATTEMPT_NUMBER do
		local attemptImg = display.newRect(0, 0, 50, 50)
		attemptImg:scale((display.contentWidth * 0.05) / attemptImg.width, (display.contentWidth * 0.05) / attemptImg.width)
		attemptImg.x = display.contentCenterX - ((ATTEMPT_NUMBER/2) - 0.5) * attemptImg.contentWidth + attemptImg.contentWidth*(attemptIndex - 1)
		attemptImg.y = display.screenOriginY  + display.contentHeight - 40
		attemptImg.fill = attemptFill
		attemptImg.right = attemptRight
		attemptImg.wrong = attempWrong
		progressTable[attemptIndex] = attemptImg
		progressBarGroup:insert(attemptImg)
	end
end

local function createSpriteofnao()
	local options = { width = 45, height = 76, numFrames = 20, sheetContentWidth = 225, sheetContentHeight = 304 }
	local sequenceData = { name = "jumping", start = 1, count = 20, time = 1000, loopCount = 1 }
	local imageSheet = graphics.newImageSheet(assetPath.."Spritesheet/naojump.png", options)
	
	naoJumps = display.newSprite(imageSheet, sequenceData)
	progressBarGroup:insert(naoJumps)
	naoJumps.anchorY = 0.8
	naoJumps.x = progressTable[1].x
	naoJumps.y = progressTable[2].y
end

local function shuffleTable(tab)
	local numberElements, order, resultTable = #tab, {}, {}
	
	for index = 1, numberElements do
		order[index] = { rnd = mathRandom(), idx = index }
	end
	
	tableSort(order, function(a,b)
		return a.rnd < b.rnd 
	end)
	
	for index = 1, numberElements do
		resultTable[index] = tab[order[index].idx]
	end
	return resultTable
end

local function generateNumbers()
	maxNumberOperation = LEVEL_SELECT[2]
	minNumberOperation = math.random(LEVEL_SELECT[2])
	resultOperation = maxNumberOperation - minNumberOperation
	alternativeNumberA = math.random(LEVEL_SELECT[2])
	alternativeNumberB = math.random(LEVEL_SELECT[2])
	
	if alternativeNumberA == alternativeNumberB or alternativeNumberB == alternativeNumberA then 
		alternativeNumberA = math.random(LEVEL_SELECT[2])
		generateNumbers()
	end
	
	randomNumbers()
end

local function createTapDummy()
	display.remove(dummyGroup)
	
	local function tapDummy(event)
		local currentDummy = event.target 
		counterStage = counterStage + 1
			
			director.to(scenePath, star, { time=650, x = currentDummy.x, y = currentDummy.y, rotation = star.rotation + 1080, transition = easing.outInQuad, onComplete = function()
				
				if counterStage == ATTEMPT_NUMBER then 
					--manager.correct()
				end
				
				if resultOperation == currentDummy.number then
					star.x = star.xStart
					star.y = star.yStart
					director.to(scenePath, naoJumps, { time = 1000, x = progressTable[counterStage + 1].x, y = progressTable[counterStage + 1].y, onStart = function() naoJumps:play() end })
					progressTable[counterStage].fill = progressTable[counterStage].right
					director.to(scenePath, dummyGroup, {time = 1000, alpha = 0, onComplete = function()
						generateNumbers()
						createTapDummy()
						showBoard()
					end})
				elseif resultOperation ~= currentDummy.number then
					star.x = star.xStart
					star.y = star.yStart
					director.to(scenePath, naoJumps, { time = 1000, alpha = 0})
					progressTable[counterStage].fill = progressTable[counterStage].wrong
					director.to(scenePath, dummyGroup, {time = 1000, alpha = 0, onComplete = function()
						generateNumbers()
						createTapDummy()
						showBoard()
					end})
				end
			end})
		return true
	end
	
	local temporalTable = shuffleTable(POSITIONS)
	local numOfImages = 3
	
	dummyGroup = display.newGroup()
	dummyLayer:insert(dummyGroup)
	
	for index = 1, numOfImages do
		local newDummy = display.newGroup()
		newDummy.x = temporalTable[index].x
		newDummy.y = display.contentCenterY + 80
		dummyGroup:insert(newDummy)
		
		local boardElement = display.newImageRect(assetPath.."dummy.png", 200, 350)
		newDummy:insert(boardElement)
		
		local dummyText = display.newText(dummyResults[index].text, 0, 0, native.systemFont, 40)
		dummyText.x = boardElement.x + boardElement.contentWidth * 0.015
		dummyText.y = boardElement.y - boardElement.contentHeight * 0.23
		newDummy:insert(dummyText)
		
		newDummy.number = dummyResults[index].text
		
		newDummy:addEventListener("tap",tapDummy)
	end
end

local function clock(hand, seconds)
	director.to(scenePath, hand, {time = 1000, rotation = 360, onComplete = function()
		hand.rotation = 0
	end} )	

	if seconds == 0  then
		transition.cancel(hand)
	end
end

local function updateTime(tiempo, secondsLeft, clockHand)
	director.performWithDelay(scenePath, 1000, function() 
		secondsLeft = secondsLeft - 1
		local seconds = secondsLeft % 60
		tiempo.text = seconds
		
		clock(clockHand, secondsLeft)
	end, 60)
end
	
local function animatedClock()
	clockGroup = display.newGroup()
	groundLayer:insert(clockGroup)
	
	local timerClock = display.newImage(assetPath.."timer.png")
	timerClock.x = display.contentWidth - display.contentWidth + 70
	timerClock.y = display.contentHeight - 50
	clockGroup:insert(timerClock)
	
	local clockHand = display.newImage(assetPath.."hand.png")
	clockHand.x = timerClock.x - 34
	clockHand.y = timerClock.y + 3
	clockHand.anchorY = 1
	clockGroup:insert(clockHand)
	
	local secondsLeft = 60
	local tiempo = display.newText("60",0, 0, native.systemFont, 35)
	tiempo:setFillColor(0, 0, 0)
	tiempo.x = timerClock.x + 20
	tiempo.y = timerClock.y + 4
	clockGroup:insert(tiempo)
	
	updateTime(tiempo, secondsLeft, clockHand)
end

local function initialize(event)
	event = event or {} 
	local params = event.params or {}
    local sceneParams = params.sceneParams
	
	isFirstTime = params.isFirstTime 
	manager = event.parent 
	
	dummyResults = {}
	
	counterStage = 0
	
end
----------------------------------------------- Module functions
function game.getInfo() 
	return {
		correctDelay = 500, 
		wrongDelay = 500, 
		name = "MinigamePablo", 
		category = "math", 
		subcategories = {"subtraction"}, 
		age = {min = 0, max = 99}, 
		grade = {min = 0, max = 99}, 
		gamemode = "findAnswer", 
		requires = { 
			{id = "operation", topic = "subtraction", operands = 2, maxAnswer = 10, minAnswer = 1, maxOperand = 10, minOperand = 1, tag = "level1"},
		}
	}
end 

function game:create( event ) 
	local sceneView = self.view
	
	backgroundLayer = display.newGroup() 
	sceneView:insert(backgroundLayer)
	
	boardLayer = display.newGroup() 
	sceneView:insert(boardLayer)
	
	dummyLayer = display.newGroup() 
	sceneView:insert(dummyLayer)
	
	groundLayer = display.newGroup() 
	sceneView:insert(groundLayer)
	
	local background = display.newImageRect(assetPath.."background.png", display.contentWidth + 2, display.contentHeight + 2)
	background.x = display.contentCenterX
    background.y = display.contentCenterY
    backgroundLayer:insert(background)
	
	local temple = display.newImage(assetPath.."temple.png")
	temple.x = display.contentCenterX
    temple.y = display.contentCenterY
	temple.height = display.contentHeight
    backgroundLayer:insert(temple)
	
	local bambu = display.newImage(assetPath.."bambu.png")
	bambu.x = display.contentCenterX
    bambu.y = display.contentCenterY + 180
	bambu.width = display.contentWidth
    backgroundLayer:insert(bambu)
	
	local road = display.newImage(assetPath.."road.png")
	road.x = display.contentCenterX
	road.y = display.screenOriginY + display.contentHeight
	road.anchorY = 1
	road.width = display.contentWidth
    groundLayer:insert(road)
	
	local nao = display.newImage(assetPath.."nao01.png")
	nao.x = road.x - road.contentWidth * 0.33
    nao.y = road.y - road.contentHeight * 0.25
	nao.anchorY = 1
    groundLayer:insert(nao)
	
	star = display.newImage(assetPath.."star.png")
	star.x = nao.x
	star.y = nao.y
	star.xStart = star.x
	star.yStart = star.y
	groundLayer:insert(star)
end

function game:show( event ) 
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then 
		initialize( event )
		animatedClock()
		generateNumbers()
		createTapDummy()
		showBoard()
		createProgressBar()
		createSpriteofnao()
	elseif phase == "did" then 
		
	end
end

function game:hide( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then 
		
	elseif phase == "did" then 
		cleanUp()
	end
end

----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "hide" )
game:addEventListener( "show" )


return game