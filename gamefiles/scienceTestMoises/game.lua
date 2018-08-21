----------------------------------------------- progDataOrder - Drag files to the same type folder
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require("libs.helpers.director")
local extratable = require("libs.helpers.extratable")
local widget = require("widget")

local game = director.newScene()
----------------------------------------------- Variables
local groupBackgroundContent, groupFolders, groupFiles, groupProgressBars
local timerTransitions, timerGameFinished
local countErrors
local backgroundLayer, dynamicLayer
local folderDataProgress
local finishTimeFlag
local speedFiles
local manager
local portal
local level
----------------------------------------------- Constants
local GLOBAL_SCALE = display.contentHeight / 765
local GAME_DURATION = 30000
local MAX_ERRORS = 3
local ROCK_SIZE = 279 * GLOBAL_SCALE
local PROGRESS_BARS_CONTAINERS = {"barra_verde1.png", "barra_rosa1.png", "barra_roja1.png", "barra_amarillo1.png"}
local PROGRESS_BARS = {"barra_verde2.png", "barra_rosa2.png", "barra_roja2.png", "barra_amarillo2.png"}
local FILES = {"archivo_audio.png", "archivo_video.png", "archivo_texto.png", "archivo_imagen.png"}
local FOLDERS_BACK = {"c_roja1.png", "c_amarilla1.png", "c_verde1.png", "c_rosa1.png"}
local FOLDERS = {"c_roja2.png", "c_amarilla2.png", "c_verde2.png", "c_rosa2.png"}
local DATA_TYPES = {1, 2, 3, 4}
----------------------------------------------- Caches
local mRandom = math.random
----------------------------------------------- Functions
local function detectCollision(object1, object2)
	if ((object1.contentBounds.xMin > object2.contentBounds.xMin and object1.contentBounds.xMin < object2.contentBounds.xMax)
	or (object1.contentBounds.xMax > object2.contentBounds.xMin and object1.contentBounds.xMax < object2.contentBounds.xMax))
	and ((object1.contentBounds.yMin > object2.contentBounds.yMin and object1.contentBounds.yMin < object2.contentBounds.yMax)
	or (object1.contentBounds.yMax > object2.contentBounds.yMin and object1.contentBounds.yMax < object2.contentBounds.yMax)) then
		return true
	end
	return false
end

local function haveUserWon()
	for indexFolders = 1, #FOLDERS do
		if not folderDataProgress[indexFolders] or folderDataProgress[indexFolders] < 3 then
			return false
		end
	end
	return true
end

local function gameFinished()
	finishTimeFlag = true
	for indexFolders = 1, #FOLDERS do
		if not folderDataProgress[indexFolders] then
			manager.wrong()
			return
		end
	end
	manager.correct()
end

local function moveFileOut(file, delay)
	if file then
		local moveTime = (display.contentWidth - file.x) / speedFiles
		local tag = "files"
		
		transition.to(file,{tag = tag, delay = delay, time = moveTime, x = display.contentWidth + file.contentWidth, onComplete = function()
			file.alpha = 0
			display.remove(file)
		end})
		transition.to(file,{tag = tag, delay = delay, time = 1000, y = display.contentCenterY, transition = easing.outCubic, onComplete = function()
			transition.to(file, {tag = tag, time = 2000, y = file.y - 200 * GLOBAL_SCALE, transition = easing.continuousLoop, iterations = 3})
		end})
	end
end

local function checkForFileInFolder(file)
	for indexFolders = 1, groupFolders.numChildren do
		folder = groupFolders[indexFolders]
		if detectCollision(folder, file) then
			if file.type == folder.type then
				file.fadingOut = true
				
				transition.fadeOut(file, {time = 1000})
				
				if folderDataProgress[file.type] then
					folderDataProgress[file.type] = folderDataProgress[file.type] + 1
				else
					folderDataProgress[file.type] = 1
				end
				if folderDataProgress[file.type] <= 3 then
					groupProgressBars[indexFolders].maskX = groupProgressBars[indexFolders].maskX + (groupProgressBars[indexFolders].width / 3 * GLOBAL_SCALE)
				end
				return
			else
				countErrors = countErrors + 1
				if countErrors == MAX_ERRORS then
					manager.wrong()
				end
			end
			break
		end
	end
	moveFileOut(file,0)
end

local function onDrag(event)
	local selectedFile = event.target
	if not selectedFile.fadingOut then
		if event.phase == "began" then
			transition.cancel(selectedFile)
			
			selectedFile.markX = selectedFile.x
			selectedFile.markY = selectedFile.y
			
			display.getCurrentStage():setFocus(selectedFile)
			selectedFile.isFocus = true
			selectedFile:toFront()
			
		elseif selectedFile.isFocus then
			if event.phase == "moved" then
				
				if not selectedFile.markX then
					selectedFile.markX = 0
				elseif selectedFile.markY == nil then
					selectedFile.markY = 0
				end
				selectedFile.x = event.x - event.xStart + selectedFile.markX
				selectedFile.y = event.y - event.yStart + selectedFile.markY
				 
			elseif event.phase == "ended" then
				display.getCurrentStage():setFocus(nil)
				selectedFile.isFocus = false
				checkForFileInFolder(selectedFile)
			end
		end
	end	
	return true
end

local function doTransitionFile()
	math.randomseed(os.time())
	local indexFile = mRandom(1, #FILES)
	local countFoldersFilled = 0
	
	if haveUserWon() then
		manager.correct()
		return
	end
	
	while folderDataProgress[indexFile] and folderDataProgress[indexFile] >= 3 and not finishTimeFlag do
		indexFile = mRandom(1, #FILES)
		countFoldersFilled = countFoldersFilled + 1
	end
	
	local file = display.newImage(assetPath..FILES[indexFile])
	file.alpha = 0
	file.xScale, file.yScale = (display.contentHeight * 0.15) / file.height, (display.contentHeight * 0.15) / file.height
	file.x, file.y = portal.x, portal.y
	file.type = indexFile
	file:addEventListener("touch", onDrag)
	groupFiles:insert(file)
	
	transition.fadeIn(file, {time = 500})
	moveFileOut(file, 500)
end

local function startTransitionFiles()
	groupFiles = display.newGroup()
	dynamicLayer:insert(groupFiles)
	
	local filesInScreen = 2
	local moveTime = 5000
	
	if level == 2 then
		filesInScreen = 3
	elseif level == 3 then
		filesInScreen = 3
		moveTime = 4000
	end
	
	speedFiles = display.contentWidth / moveTime
	local delay = moveTime / (filesInScreen + 1)
	
	doTransitionFile()
	timerTransitions = timer.performWithDelay(delay, doTransitionFile, -1)
	timerGameFinished = timer.performWithDelay(GAME_DURATION, gameFinished)
end	

local function createPortal()
	local portalData = {width = 105, height = 170, numFrames = 12, sheetContentWidth = 420, sheetContentHeight = 512}
	local portalSheet = graphics.newImageSheet(assetPath.."spritesheet/portal.png", portalData)
	local portalSequence = {time = 2000, loopCount = 0, start = 1, count = 12}
	
	portal = display.newSprite(portalSheet, portalSequence)
	portal.xScale, portal.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	portal.x, portal.y = display.screenOriginX + ROCK_SIZE - portal.contentWidth * 0.5, display.screenOriginY + portal.contentHeight * 0.5 - 10 * GLOBAL_SCALE
	portal.rotation = -90
	portal:play()
	groupBackgroundContent:insert(portal)
end

local function createFolder(startpointX, posY, indexFolders)
	local barContainer = display.newImage(assetPath..PROGRESS_BARS_CONTAINERS[indexFolders])
	barContainer.xScale, barContainer.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	barContainer.x, barContainer.y = startpointX, posY + barContainer.contentHeight + 30 * GLOBAL_SCALE
	groupBackgroundContent:insert(barContainer)
	
	local progressMask = graphics.newMask(assetPath.."mascara.png")
	
	local progressBar = display.newImage(assetPath..PROGRESS_BARS[indexFolders])
	progressBar.anchorX = 0
	progressBar.xScale, progressBar.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	progressBar.x, progressBar.y = startpointX - barContainer.contentWidth * 0.5 + 3 * GLOBAL_SCALE, barContainer.y
	groupProgressBars:insert(progressBar)
	
	progressBar:setMask(progressMask)
	progressBar.maskX = -progressBar.contentWidth * 0.99
	progressBar.maskScaleX = GLOBAL_SCALE * 1.1
	
	local folderBack = display.newImage(assetPath..FOLDERS_BACK[indexFolders])
	folderBack.xScale, folderBack.yScale = (display.contentHeight * 0.15) / folderBack.height, (display.contentHeight * 0.15) / folderBack.height
	folderBack.x, folderBack.y = startpointX, posY - 30 * GLOBAL_SCALE - barContainer.contentHeight
	groupBackgroundContent:insert(folderBack)
	
	local folder = display.newImage(assetPath..FOLDERS[indexFolders])
	folder.xScale, folder.yScale = (display.contentHeight * 0.15) / folder.height, (display.contentHeight * 0.15) / folder.height
	folder.x, folder.y = startpointX, posY - barContainer.contentHeight
	folder.type = DATA_TYPES[indexFolders]
	groupFolders:insert(folder)
end

local function createFolders()
	local spacingX = display.contentWidth / #FOLDERS
	local startpointX = 150 * GLOBAL_SCALE
	local posY = display.contentHeight - 110 * GLOBAL_SCALE
	
	groupFolders = display.newGroup()
	dynamicLayer:insert(groupFolders)
	
	groupProgressBars = display.newGroup()
	dynamicLayer:insert(groupProgressBars)
	
	for indexFolders = 1, #FOLDERS_BACK do
		createFolder(startpointX, posY, indexFolders)
		startpointX = startpointX + spacingX
	end
end

local function createBackgroundComponents()
	local topRock = display.newImage(assetPath.."roca_superior.png")
	topRock.anchorX, topRock.anchorY = 0, 0
	topRock.xScale, topRock.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	topRock.x, topRock.y = display.screenOriginX - 10 * GLOBAL_SCALE, display.screenOriginY - 30 * GLOBAL_SCALE
	groupBackgroundContent:insert(topRock)
	
	local blueBar = display.newImage(assetPath.."barra.png")
	local heightForScale = display.contentWidth / blueBar.width * blueBar.height
	blueBar.anchorY = 1
	blueBar.width, blueBar.height = display.contentWidth, heightForScale
	blueBar.x, blueBar.y = display.contentCenterX, display.contentHeight
	groupBackgroundContent:insert(blueBar)
	
	local bottomRock = display.newImage(assetPath.."roca_inferior.png")
	bottomRock.anchorX, bottomRock.anchorY = 1, 1
	bottomRock.xScale, bottomRock.yScale = GLOBAL_SCALE, GLOBAL_SCALE
	bottomRock.x, bottomRock.y = display.contentWidth, display.contentHeight - blueBar.contentHeight
	groupBackgroundContent:insert(bottomRock)
end

local function cleanUp()
	display.remove(groupFolders)
	groupFolders = nil
	display.remove(groupBackgroundContent)
	groupBackgroundContent = nil
	display.remove(groupFiles)
	groupFiles = nil
	display.remove(groupProgressBars)
	groupProgressBars = nil
	
	transition.cancel("files")

	if timerGameFinished then
		timer.cancel(timerGameFinished)
	end
	
	if timerTransitions then
		timer.cancel(timerTransitions)
	end
end

local function initialize(event)
	event = event or {}
	local params = event.params or {}
	manager = event.parent
	
	finishTimeFlag = false
	
	countErrors = 0
	level = 2
	
	folderDataProgress = {}
	
	groupBackgroundContent = display.newGroup()
	backgroundLayer:insert(groupBackgroundContent)
	--minigameLevel = sceneParams.level or 1
end
----------------------------------------------- Module functions
function game.getInfo() 
	return {
		correctDelay = 500,
		wrongDelay = 500,
		name = "testMinigame",
		category = "science",
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
	
	local imageBackground = display.newImageRect(assetPath.."fondo.png", display.contentWidth, display.contentHeight)
	imageBackground.x, imageBackground.y = display.contentCenterX, display.contentCenterY
	backgroundLayer:insert(imageBackground)
end

function game:show(event) 
	local sceneView = self.view
	local phase = event.phase
	
	if phase == "will" then
		initialize(event)
		createPortal()
		createBackgroundComponents()
		createFolders()
		startTransitionFiles()
	end
end

function game:hide(event)
	local sceneView = self.view
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