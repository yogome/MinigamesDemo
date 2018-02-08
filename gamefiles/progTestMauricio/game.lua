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
local van, storedDevicesCounter, totalDevicesToSort, deviceToSort
local tapsEnable
local counterSwitchBoxSides, boxes
local currentLevel, elapsedGameTimer, currentLevelTime
----------------------------------------------- Constants
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
	[10] = {image = assetPath.."consola.png", deviceType = "computing"},
	[11] = {image = assetPath.."calculadora.png", deviceType = "computing"},
	[12] = {image = assetPath.."z.png", deviceType = "computing"},
	[13] = {image = assetPath.."registradora.png", deviceType = "computing"},
	[14] = {image = assetPath.."atm.png", deviceType = "computing"}
}

local LEVEL_DATA = {
	[1] = {availableTime = 0, devicesToSort = 15, devicesPoolSize = 8},
	[2] = {availableTime = 60000, devicesToSort = 20, devicesPoolSize = 11},
	[3] = {availableTime = 45000, devicesToSort = 20, devicesPoolSize = 14}
}

local BOX_DATA = {
	[1] = {id = "leftBox", x = display.contentWidth * 0.3, y = display.contentHeight * 0.8, width = 269, height = 200},
	[2] = {id = "rightBox", x = display.contentWidth * 0.7, y = display.contentHeight * 0.8, width = 269, height = 200}
}
----------------------------------------------- Caches

----------------------------------------------- Functions
local function validateManager(wonGame)
	if wonGame then
		manager.correct()
	else
		manager.wrong()
	end
  
	timer.cancel(elapsedGameTimer)
	elapsedGameTimer = nil
end

local function startTimer()
	if currentLevel > 1 then
		elapsedGameTimer = timer.performWithDelay(currentLevelTime, function () validateManager(false) end)
	end
end

local function shakeObject(touchedObject)
	transition.to(touchedObject, {time = 70, rotation = 10, onComplete = function()
		transition.to(touchedObject, {time = 70, rotation = -10, onComplete = function()
			transition.to(touchedObject, {time = 70, rotation = 10, onComplete = function()
				transition.to(touchedObject, {time = 70, rotation = -10, onComplete = function()
					transition.to(touchedObject, {time = 70, rotation = 0})
				end})
			end})
		end})
	end})
end

local function sortBoxes()
	local randomBox = math.random(1, 2)
	local computingFill = {type = "image", filename = assetPath.."caja1.png"}
	local homeFill = {type = "image", filename = assetPath.."caja2.png"}

	boxes[1].boxType = randomBox == 1 and "computing" or "home"
	boxes[2].boxType = randomBox == 1 and "home" or "computing"

	boxes[1].fill = randomBox == 1 and computingFill or homeFill
	boxes[2].fill = randomBox == 1 and homeFill or computingFill
end

local function turnValidation(touchedObject)
	storedDevicesCounter = storedDevicesCounter + 1
	counterSwitchBoxSides = counterSwitchBoxSides + 1
	
	if storedDevicesCounter == totalDevicesToSort then
		validateManager(true)
	else
		touchedObject:removeSelf()
		if counterSwitchBoxSides == 5 and counterSwitchBoxSides ~= totalDevicesToSort then
			counterSwitchBoxSides = 0
			tapsEnable = false
			transition.to(boxes[1], {time = 500, xScale = 0.01, yScale = 0.01, alpha = 0, transition = easing.outBack})
			transition.to(boxes[2], {time = 500, xScale = 0.01, yScale = 0.01, alpha = 0, transition = easing.outBack, onComplete = function()
				sortBoxes()
				transition.to(boxes[1], {time = 500, xScale = 1, yScale = 1, alpha = 1, transition = easing.outBack})
				transition.to(boxes[2], {time = 500, xScale = 1, yScale = 1, alpha = 1, transition = easing.outBack, onComplete = function()
					tapsEnable = true
				end})
			end})
		end
		van:generateNewDevice()
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
				transition.to(touchedObject, {time = 200, x = boxes[boxIndex].x, y = boxes[boxIndex].y, onComplete = function()
					transition.to(touchedObject, {time = 300, xScale = 0.01, yScale = 0.01, y = boxes[boxIndex].y - boxes[boxIndex].contentHeight * 0.4, onComplete = function()
						turnValidation(touchedObject)
					end})
				end})
				break
			else
				correctBoxIndex = searchCorrectBoxIndex(touchedObject)
        
				if correctBoxIndex > 0 then
					shakeObject(touchedObject)
					transition.to(touchedObject, {delay = 600, time = 1000, x = boxes[correctBoxIndex].x, y = boxes[correctBoxIndex].y, onComplete = function()
						transition.to(touchedObject, {time = 300, xScale = 0.01, yScale = 0.01, y = boxes[correctBoxIndex].y - boxes[correctBoxIndex].contentHeight * 0.4, onComplete = function()
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
		transition.to(deviceToSort, {x = display.contentCenterX, y = display.contentHeight * 0.4, onComplete = function()
			tapsEnable = true
		end})
	end
end

local function onObjectTouch(event)
	if tapsEnable then
		local touchedObject = event.target
    
		if (event.phase == "began") then
			display.getCurrentStage():setFocus(touchedObject)
			touchedObject.isFocus = true
        
		elseif (touchedObject.isFocus) then
			if (event.phase == "moved") then
				touchedObject.x = event.x
				touchedObject.y = event.y
 
			elseif (event.phase == "ended" or event.phase == "cancelled") then
 
				display.getCurrentStage():setFocus(nil)
				touchedObject.isFocus = nil
				tapsEnable = false
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
  
	backgroundGroup:removeSelf()
	backgroundGroup = nil

	dynamicGroup:removeSelf()
	dynamicGroup = nil

	targetGroup:removeSelf()
	targetGroup = nil
end

local function createBoxes()
	local creatingBox
	for boxIndex = 1, #BOX_DATA do
		creatingBox = display.newRect(BOX_DATA[boxIndex].x, BOX_DATA[boxIndex].y, BOX_DATA[boxIndex].width, BOX_DATA[boxIndex].height)
		creatingBox.id = BOX_DATA[boxIndex].id
		dynamicGroup:insert(creatingBox)
		boxes[boxIndex] = creatingBox
	end
  
	sortBoxes()
end

local function generateNewDevice()
	local randomDevice = math.random(LEVEL_DATA[currentLevel].devicesPoolSize)
  
	deviceToSort = display.newImage(DEVICES[randomDevice].image)
    deviceToSort.deviceType = DEVICES[randomDevice].deviceType
    deviceToSort.alpha = 0
    deviceToSort.x, deviceToSort.y = display.contentCenterX, display.contentHeight * 0.4
    deviceToSort:scale(0.01, 0.01)
  
    targetLayer:insert(deviceToSort)
  
    deviceToSort:addEventListener("touch", onObjectTouch)
  
    transition.to(deviceToSort, { time = 700, alpha = 1, xScale = 0.7, yScale = 0.7, transition = easing.outBack, onComplete = function()
		tapsEnable = true
    end})
end

local function createVan()
	van = display.newRect(display.contentCenterX, display.contentCenterY, 1, 1)
	van.alpha = 0
	backgroundGroup:insert(van)

	van.generateNewDevice = generateNewDevice
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
  
	isFirstTime = params.isFirstTime 
	manager = event.parent 
  
	math.randomseed(os.time())
  
	tapsEnable = true
  
	currentLevel = 3
	boxes = {}
	counterSwitchBoxSides = 0
	storedDevicesCounter = 0
	totalDevicesToSort = LEVEL_DATA[currentLevel].devicesToSort
	currentLevelTime = LEVEL_DATA[currentLevel].availableTime
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
		createVan()
		startTimer()
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