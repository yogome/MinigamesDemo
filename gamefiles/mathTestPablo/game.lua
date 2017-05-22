----------------------------------------------- Requires
local scenePath = ... 
local folder = scenePath:match("(.-)[^%.]+$") 
local assetPath = string.gsub(folder,"[%.]","/") 
local director = require( "libs.helpers.director" )

local game = director.newScene() 
----------------------------------------------- Variables
local backgroundLayer, boardLayer, dummyLayer, groundLayer
local star, clockTimer, naoJumps
local boardGroup, dummyGroup, clockGroup, progressBarGroup, answerGroup
local progressTable, tableNumber, miniGameSelect, dummyResults, dummyNumbers
local counterStage, tapFlag, boardElement, storeBoardElementPosition
local isFirstTime, manager
----------------------------------------------- Constants
local ATTEMPT_NUMBER = 5
local TIME_REMAINING = 60
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
	[1] = {path = "number.png"},
	[2] = {path = "symbol2.png"},
	[3] = {path = "number.png"},
	[4] = {path = "symbol4.png"},
	[5] = {path = "question.png"},
}

----------------------------------------------- Caches
local mathRandom = math.random
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
	timer.cancel(clockTimer)
	display.remove(clockGroup)
	clockGroup = nil
end

local function showAnswer()
	display.remove(answerGroup)
	
	answerGroup = display.newGroup()
	boardGroup:insert(answerGroup)
	
	local answer = display.newImage(assetPath.. boardElementsTable[1].path)
	answer:scale(0.9, 0.9)
	answer.x = storeBoardElementPosition[5].x
	answer.y = storeBoardElementPosition[5].y
	answerGroup:insert(answer)
	
	local answerText = display.newText(tableNumber.resultOperation, 0, 0, native.systemFont, 40)
	answerText.x = answer.x
	answerText.y = answer.y
	answerGroup:insert(answerText)
	
end

local function createNao()
	local nao = display.newImage(assetPath.."nao01.png")
	nao.x, nao.y = display.contentWidth * 0.15, display.contentHeight * 0.75
    groundLayer:insert(nao)
	
	star = display.newImage(assetPath.."star.png")
	star:scale(0.8, 0.8)
	star.x, star.y = nao.x - 5, nao.y + 65
	star.xStart, star.yStart = star.x, star.y
	groundLayer:insert(star)
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
	
	storeBoardElementPosition = {}
	
	local textCounter = 0
	for index = 1, #boardElementsTable do
		local boardElement = display.newImage(assetPath.. boardElementsTable[index].path)
		boardElement:scale(0.8,0.8)
		boardElement.x = board.x - board.contentWidth * 0.5 + (board.contentWidth / (#boardElementsTable + 1) * index)
		boardElement.y = board.y + board.contentHeight * 0.1
		storeBoardElementPosition[index] = boardElement
		boardGroup:insert(boardElement)
		
		if index % 2 ~= 0 then
			textCounter = textCounter + 1
			
			local numberTextBoard = display.newText(dummyNumbers[textCounter].text, 0, 0, native.systemFont, 40)
			numberTextBoard.x, numberTextBoard.y = boardElement.x, boardElement.y
			boardGroup:insert(numberTextBoard)
		end
		
	end
	tapFlag = true
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
  local size = #tab
  for i = size, 1, -1 do
    local rand = mathRandom(size)
    tab[i], tab[rand] = tab[rand], tab[i]
  end
  return tab
end

local function generateNumbers()
	local maxNumberOperation = LEVEL_SELECT[miniGameSelect]
	local minNumberOperation = mathRandom(LEVEL_SELECT[miniGameSelect])
	local resultOperation = maxNumberOperation - minNumberOperation
	local alternativeNumberA = resultOperation + mathRandom(7)
	local alternativeNumberB = resultOperation - mathRandom(7)
	
	tableNumber = {
		maxNumberOperation = maxNumberOperation,
		minNumberOperation = minNumberOperation, 
		resultOperation = resultOperation, 
		alternativeNumberA = alternativeNumberA,
		alternativeNumberB = alternativeNumberB
	}

	dummyResults = {
		[1] = {text = tableNumber.alternativeNumberA},
		[2] = {text = tableNumber.resultOperation},
		[3] = {text = tableNumber.alternativeNumberB}
	}

	dummyNumbers = {
		[1] = {text = tableNumber.maxNumberOperation},
		[2] = {text = tableNumber.minNumberOperation},
		[3] = {text = ""}
	}
end

local function createTapDummy()
	display.remove(dummyGroup)
	
	local function tapDummy(event)
		local currentDummy = event.target 
		if tapFlag then
			showAnswer()
		counterStage = counterStage + 1
		tapFlag = false
		director.to(scenePath, star, { time=1000, x = currentDummy.x, y = currentDummy.y, rotation = star.rotation + 1080, transition = easing.outInQuad, onComplete = function()
			
		
				if counterStage == ATTEMPT_NUMBER then 
					manager.correct()
				end
				if tableNumber.resultOperation == currentDummy.number then
					star.x = star.xStart
					star.y = star.yStart
					director.to(scenePath, naoJumps, { time = 1000, x = progressTable[counterStage + 1].x, y = progressTable[counterStage + 1].y, onStart = function() naoJumps:play() end })
					progressTable[counterStage].fill = progressTable[counterStage].right
					director.to(scenePath, dummyGroup, {time = 1000, alpha = 0, onComplete = function()
						generateNumbers()
						createTapDummy()
						showBoard()
					end})
				elseif tableNumber.resultOperation ~= currentDummy.number then
					star.x = star.xStart
					star.y = star.yStart
					progressTable[counterStage].fill = progressTable[counterStage].wrong
					director.to(scenePath, naoJumps, { time = 1000, x = progressTable[counterStage + 1].x, y = progressTable[counterStage + 1].y, onStart = function() naoJumps:play() end })
					director.to(scenePath, naoJumps, { time = 1000, alpha = 1})
					director.to(scenePath, dummyGroup, {time = 1000, alpha = 0, onComplete = function()
						generateNumbers()
						createTapDummy()
						showBoard()
					end})
				end
		end})
	end
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
		newDummy.number = dummyResults[index].text
		newDummy:insert(boardElement)
		
		local dummyText = display.newText(newDummy.number, 0, 0, native.systemFont, 40)
		dummyText.x = boardElement.x + boardElement.contentWidth * 0.015
		dummyText.y = boardElement.y - boardElement.contentHeight * 0.23
		newDummy:insert(dummyText)
		
		newDummy:addEventListener("tap",tapDummy)
		
	end
end

local function animationClock(clockHand)
	director.to(scenePath, clockHand, {time = 1000, rotation = clockHand.rotation + 360, onComplete = function()
	end})	
end

local function updateTime(tiempo, TIME_REMAINING, clockHand)
clockTimer = director.performWithDelay(scenePath, 1000, function() 
	TIME_REMAINING = TIME_REMAINING - 1
	tiempo.text = TIME_REMAINING
		if TIME_REMAINING == 0 then
			manager.wrong()
		end
	animationClock(clockHand)
	end, TIME_REMAINING)
end

local function displayClock()
	clockGroup = display.newGroup()
	groundLayer:insert(clockGroup)
	
	local timerClock = display.newImage(assetPath.."timer.png")
	timerClock.x, timerClock.y = display.contentWidth - display.contentWidth + 70, display.contentHeight - 50
	clockGroup:insert(timerClock)
	
	local clockHand = display.newImage(assetPath.."hand.png")
	clockHand.x, clockHand.y = timerClock.x - 34, timerClock.y + 3
	clockHand.anchorY = 1
	clockGroup:insert(clockHand)
	
	local tiempo = display.newText(TIME_REMAINING,0, 0, native.systemFont, 35)
	tiempo:setFillColor(0, 0, 0)
	tiempo.x, tiempo.y = timerClock.x + 20, timerClock.y + 4
	clockGroup:insert(tiempo)
	
	updateTime(tiempo, TIME_REMAINING, clockHand)
end

local function initialize(event)
	event = event or {} 
	local params = event.params or {}
    local sceneParams = params.sceneParams
	
	isFirstTime = params.isFirstTime 
	manager = event.parent 
	
	miniGameSelect = math.random(#LEVEL_SELECT)
	
	counterStage = 0
	
	tapFlag = true
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
	background.x, background.y = display.contentCenterX, display.contentCenterY
    backgroundLayer:insert(background)
	
	local temple = display.newImage(assetPath.."temple.png")
	temple.x, temple.y = display.contentCenterX, display.contentCenterY
	temple.height = display.contentHeight
    backgroundLayer:insert(temple)
	
	local bambu = display.newImage(assetPath.."bambu.png")
	bambu.x, bambu.y = display.contentCenterX, display.contentCenterY + 180
	bambu.width = display.contentWidth
    backgroundLayer:insert(bambu)
	
	local road = display.newImage(assetPath.."road.png")
	road.x, road.y = display.contentCenterX, display.screenOriginY + display.contentHeight
	road.anchorY = 1
	road.width = display.contentWidth
    groundLayer:insert(road)

end

function game:show( event ) 
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then 
		initialize( event )
		createNao()
		generateNumbers()
		displayClock()
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