----------------------------------------------- Requires
local scenePath = ... 
local folder = scenePath:match("(.-)[^%.]+$") 
local assetPath = string.gsub(folder,"[%.]","/") 
local director = require("libs.helpers.director")

local game = director.newScene() 
----------------------------------------------- Variables
local backgroundLayer, targetLayer, dynamicLayer
local backgroundGroup, targetGroup, dynamicGroup
local manager, isFirstTime
local van, storedDevicesCounter, totalDevicesToSort
local tapsEnabled, transitionsRunning
local counterSwitchBoxSides, boxes, randomizedBoxData
local currentLevel, elapsedGameTimer, currentLevelTime
----------------------------------------------- Constants
local TRANSITION_TAG = "transitionTag"

local DEVICES = {
	[1] = {image = assetPath.."lampara.png", deviceType = "home"},
	[2] = {image = assetPath.."licuadora.png", deviceType = "home"},
	[3] = {image = assetPath.."maceta.png", deviceType = "home"},
	[4] = {image = assetPath.."plancha.png", deviceType = "home"},
	[5] = {image = assetPath.."tablet.png", deviceType = "computing"},
	[6] = {image = assetPath.."cellphone.png", deviceType = "computing"},
	[7] = {image = assetPath.."laptop.png", deviceType = "computing"},
	[8] = {image = assetPath.."pc.png", deviceType = "computing"},
	[9] = {image = assetPath.."robot.png", deviceType = "computing"},
	[11] = {image = assetPath.."calculadora.png", deviceType = "computing"},
	[10] = {image = assetPath.."consola.png", deviceType = "computing"},
	[12] = {image = assetPath.."z.png", deviceType = "computing"},
	[13] = {image = assetPath.."registradora.png", deviceType = "computing"},
	[14] = {image = assetPath.."atm.png", deviceType = "computing"}
}

local CLOUD_DATA = {
	[1] = {image = assetPath..'nube.png', maxDelay = 1, minDelay = 0},
	[2] = {image = assetPath..'nube.png', maxDelay = 12000, minDelay = 8000},
	[3] = {image = assetPath..'nube.png', maxDelay = 22000, minDelay = 18000}
}

local LEVEL_DATA = {
	[1] = {availableTime = 0, devicesToSort = 15, devicesPoolSize = 8},
	[2] = {availableTime = 60000, devicesToSort = 20, devicesPoolSize = 11},
	[3] = {availableTime = 45000, devicesToSort = 20, devicesPoolSize = 14}
}


local BOX_DATA = {
	[1] = {id = "leftBox", x = display.contentWidth * 0.25, y = display.contentHeight * 0.8, width = 384, height = 285},
	[2] = {id = "rightBox", x = display.contentWidth * 0.75, y = display.contentHeight * 0.8, width = 384, height = 285}
}

local BOX_ATTRIBUTES = {
	[1] = {typeId = "computing", closedImageFill = {type = "image", filename = assetPath.."cajaPcClose.png"}, openedImageFill = {type = "image", filename = assetPath.."caja1.png"} },
	[2] = {typeId = "home", closedImageFill = {type = "image", filename = assetPath.."cajaCasaClose.png"}, openedImageFill = {type = "image", filename = assetPath.."caja2.png"}}
}
----------------------------------------------- Caches

----------------------------------------------- Functions
local function validateManager(wonGame)
	if wonGame then
		manager.correct()
	else
		manager.wrong()
	end
end

local function startGameTimer()
	elapsedGameTimer = currentLevel > 1 and timer.performWithDelay(currentLevelTime, function () 
		if storedDevicesCounter ~= totalDevicesToSort then
			validateManager(false) 
		end
	end)
end

local function shakeObject(self)
	transition.to(self, {tag = TRANSITION_TAG, time = 70, rotation = 10, onComplete = function()
		transition.to(self, {tag = TRANSITION_TAG, time = 70, rotation = -10, onComplete = function()
			transition.to(self, {tag = TRANSITION_TAG, time = 70, rotation = 10, onComplete = function()
				transition.to(self, {tag = TRANSITION_TAG, time = 70, rotation = -10, onComplete = function()
					transition.to(self, {tag = TRANSITION_TAG, time = 70, rotation = 0})
				end})
			end})
		end})
	end})
end

local function randomizeDataTable()
	randomizedBoxData = BOX_ATTRIBUTES
	
	for dataTableId = 1, #BOX_ATTRIBUTES do
		local randomId = math.random(#BOX_ATTRIBUTES)
		randomizedBoxData[dataTableId], randomizedBoxData[randomId] = randomizedBoxData[randomId], randomizedBoxData[dataTableId]
	end
end

local function sortBoxes()
	local randomBox = math.random(1, 2)
	local computingFill = {type = "image", filename = assetPath.."caja1.png"}
	local homeFill = {type = "image", filename = assetPath.."caja2.png"}
	randomizeDataTable()
	
	for totalBoxes = 1, #boxes do
		boxes[totalBoxes].boxType, boxes[totalBoxes].fill = randomizedBoxData[totalBoxes].typeId, randomizedBoxData[totalBoxes].openedImageFill
	end
end

local function boxesToVan(gameFinished)
	local closedHomeBoxFill = {type = "image", filename = assetPath.."cajaCasaClose.png"}
	local closedComputingBoxFill = {type = "image", filename = assetPath.."cajaPcClose.png"}
	
	if elapsedGameTimer then timer.pause(elapsedGameTimer) end
	
	for totalBoxes = 1, #boxes do
		boxes[totalBoxes].fill = randomizedBoxData[totalBoxes].closedImageFill
		
		if totalBoxes ~= #boxes then 
			transition.to(boxes[totalBoxes], {delay = 1000, tag = TRANSITION_TAG, time = 1000, xScale = 0.01, yScale = 0.01, alpha = 0, x = van.x, y = van.y, transition = easing.outBack})
		else
			transition.to(boxes[totalBoxes], {delay = 1000, tag = TRANSITION_TAG, time = 1000, xScale = 0.01, yScale = 0.01, alpha = 0, x = van.x, y = van.y, transition = easing.outBack, onComplete = function()
		if not gameFinished then
			sortBoxes()
			
			for boxesPositions = 1, #boxes do
				boxes[boxesPositions].x, boxes[boxesPositions].y = BOX_DATA[boxesPositions].x, BOX_DATA[boxesPositions].y
				
				if boxesPositions ~= #boxes then
					transition.to(boxes[boxesPositions], {tag = TRANSITION_TAG, time = 500, xScale = 1, yScale = 1, alpha = 1, transition = easing.outBack})
				else
					transition.to(boxes[boxesPositions], {tag = TRANSITION_TAG, time = 500, xScale = 1, yScale = 1, alpha = 1, transition = easing.outBack, onComplete = function()
						van:generateNewDevice()
					end})
				end
			end
		else
			van:removeSelf()
			van = display.newImage(assetPath.."camionetaCerrada.png", display.contentCenterX, display.contentCenterY)
			backgroundGroup:insert(van)
			transition.to(van, {tag = TRANSITION_TAG, delay = 1000, time = 1000, xScale = 0.1, yScale = 0.1, alpha = 1, y = display.contentHeight * 0.45, onComplete = function()
				validateManager(true)		
			end})
		end
	end})
		end
	end

	if elapsedGameTimer then timer.resume(elapsedGameTimer) end

	return true
end

local function turnValidation(touchedObject)
	storedDevicesCounter = storedDevicesCounter + 1
	counterSwitchBoxSides = counterSwitchBoxSides + 1
	
	if storedDevicesCounter == totalDevicesToSort then
		boxesToVan(true)
	else
		touchedObject:removeSelf()
		if counterSwitchBoxSides == 5 and counterSwitchBoxSides ~= totalDevicesToSort then
			tapsEnabled = false
			counterSwitchBoxSides = 0
			boxesToVan(false)
		else
			van:generateNewDevice()
		end
	end
end

local function searchCorrectBoxIndex(touchedObject)
	local correctBoxIndex = 0
  
	for boxIndex = 1, #boxes do
		if touchedObject.deviceType == boxes[boxIndex].boxType then
			correctBoxIndex = boxIndex
			break
		end
	end
	return correctBoxIndex
end

local function checkBox(touchedObject)
	local deviceTouchedBox = false
	local correctBoxIndex = 0

	for boxIndex = 1, #boxes do
		if touchedObject.x >= boxes[boxIndex].contentBounds.xMin
		and touchedObject.x <= boxes[boxIndex].contentBounds.xMax
		and touchedObject.y >= boxes[boxIndex].contentBounds.yMin
		and touchedObject.y <= boxes[boxIndex].contentBounds.yMax then
			deviceTouchedBox = true
			if touchedObject.deviceType == boxes[boxIndex].boxType then
				transition.to(touchedObject, {tag = TRANSITION_TAG, time = 200, x = boxes[boxIndex].x, y = boxes[boxIndex].y, onComplete = function()
					transition.to(touchedObject, {tag = TRANSITION_TAG, time = 300, xScale = 0.01, yScale = 0.01, y = boxes[boxIndex].y - boxes[boxIndex].contentHeight * 0.4, onComplete = function()
						turnValidation(touchedObject)
					end})
				end})
				break
			else
				correctBoxIndex = searchCorrectBoxIndex(touchedObject)
        
				if correctBoxIndex > 0 then
					shakeObject(touchedObject)
					transition.to(touchedObject, {tag = TRANSITION_TAG, delay = 600, time = 1000, x = boxes[correctBoxIndex].x, y = boxes[correctBoxIndex].y, onComplete = function()
						transition.to(touchedObject, {tag = TRANSITION_TAG, time = 300, xScale = 0.01, yScale = 0.01, y = boxes[correctBoxIndex].y - boxes[correctBoxIndex].contentHeight * 0.4, onComplete = function()
							touchedObject:removeSelf()
							van:generateNewDevice()
						end})
					end})
					break
				else
					deviceTouchedBox = false
				end
			end
		end
	end
  
	if deviceTouchedBox == false then
		transition.to(touchedObject, {tag = TRANSITION_TAG, x = display.contentCenterX, y = display.contentHeight * 0.4, onComplete = function()
			tapsEnabled = true
		end})
	end
end

local function onObjectTouch(event)
	if tapsEnabled then
		local touchedObject = event.target
    
		if event.phase == "began" then
			display.getCurrentStage():setFocus(touchedObject)
			touchedObject.isFocus = true
		elseif touchedObject.isFocus then
			if event.phase == "moved" then
				touchedObject.x = event.x
				touchedObject.y = event.y
			elseif event.phase == "ended" or event.phase == "cancelled" then
				display.getCurrentStage():setFocus(nil)
				touchedObject.isFocus = nil
				tapsEnabled = false
				checkBox(touchedObject)
			end
		end
	end
	return true
end

local function cleanUp()
	if elapsedGameTimer then 
		timer.cancel(elapsedGameTimer)
		elapsedGameTimer = nil
	end
	
	if transitionsRunning then
		transition.cancel(TRANSITION_TAG)
		transitionsRunning = false
	end
  
	backgroundGroup:removeSelf()
	backgroundGroup = nil

	dynamicGroup:removeSelf()
	dynamicGroup = nil

	targetGroup:removeSelf()
	targetGroup = nil
end

local function createBoxes()
	for boxIndex = 1, #BOX_DATA do
		local creatingBox = display.newRect(BOX_DATA[boxIndex].x, BOX_DATA[boxIndex].y, BOX_DATA[boxIndex].width, BOX_DATA[boxIndex].height)
		creatingBox.id = BOX_DATA[boxIndex].id
		dynamicGroup:insert(creatingBox)
		boxes[boxIndex] = creatingBox
	end
  
	sortBoxes()
end

local function generateNewDevice()
	local randomDevice = math.random(LEVEL_DATA[currentLevel].devicesPoolSize)
  
	local deviceToSort = display.newImage(DEVICES[randomDevice].image)
    deviceToSort.deviceType = DEVICES[randomDevice].deviceType
    deviceToSort.alpha = 0
    deviceToSort.x, deviceToSort.y = display.contentCenterX, display.contentHeight * 1.1
    deviceToSort:scale(0.01, 0.01)
    targetLayer:insert(deviceToSort)
  
    deviceToSort:addEventListener("touch", onObjectTouch)
  
    transition.to(deviceToSort, {tag = TRANSITION_TAG, time = 800, alpha = 1, xScale = 0.7, yScale = 0.7, y = display.contentHeight * 0.4, transition = easing.outBack, onComplete = function()
		tapsEnabled = true
    end})
end

local function createVan()
	van = display.newImage(assetPath.."camionetaAbiertaBlur.png", display.contentCenterX, display.contentCenterY)
	backgroundGroup:insert(van)

	van.generateNewDevice = generateNewDevice
end

local function animateCloud(cloud)
	transition.to(cloud, {tag = TRANSITION_TAG, delay = math.random(cloud.minDelay, cloud.maxDelay), time = math.random(28, 32) * 1000, x = display.contentWidth * 1.1, onComplete = function()
		cloud.x, cloud.y = display.contentWidth * -0.15 , display.contentHeight * 0.15
		animateCloud(cloud)
	end})
end

local function createClouds()	
	for cloudId = 1, #CLOUD_DATA do
		local cloudIndex = CLOUD_DATA[cloudId]
		local cloud = display.newImage(cloudIndex.image, display.contentWidth * -0.15 , display.contentHeight * 0.15)
		cloud.minDelay, cloud.maxDelay = cloudIndex.minDelay, cloudIndex.maxDelay
		backgroundGroup:insert(cloud)
		animateCloud(cloud)
	end
end

local function createGroups()
	backgroundGroup = display.newGroup()
	backgroundLayer:insert(backgroundGroup)

	targetGroup = display.newGroup()
	targetLayer:insert(targetGroup)

	dynamicGroup = display.newGroup()
	dynamicLayer:insert(dynamicGroup)
end

local function initialize(event)
	event = event or {} 
	local params = event.params or {}
	local sceneParams = params.sceneParams or {}
  
	isFirstTime = params.isFirstTime 
	manager = event.parent 
  
	math.randomseed(os.time())
  
	tapsEnabled = true
	transitionsRunning = true
	
	boxes = {}
  
	currentLevel = 1 --TODO: Replace with actual scenParams level.
	storedDevicesCounter = 0
	counterSwitchBoxSides = 0
	currentLevelTime = LEVEL_DATA[currentLevel].availableTime
	totalDevicesToSort = LEVEL_DATA[currentLevel].devicesToSort
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

function game:create() 
	local sceneView = self.view

	backgroundLayer = display.newGroup() 
	sceneView:insert(backgroundLayer)

	dynamicLayer = display.newGroup()
	sceneView:insert(dynamicLayer)

	targetLayer = display.newGroup() 
	sceneView:insert(targetLayer)

	local backgroundImage = display.newImageRect(assetPath..'background.png', display.contentWidth, display.contentHeight)
	backgroundImage.x, backgroundImage.y = display.contentCenterX, display.contentCenterY
	backgroundLayer:insert(backgroundImage)
end  

function game:show(event) 
	local phase = event.phase
	
	if phase == "will" then 
		initialize(event)
		createGroups()
		createClouds()
		createVan()
		startGameTimer()
		createBoxes()
		van:generateNewDevice()
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