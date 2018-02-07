----------------------------------------------- Requires
local scenePath = ... 
local folder = scenePath:match("(.-)[^%.]+$") 
local assetPath = string.gsub(folder,"[%.]","/") 
local director = require("libs.helpers.director")

local game = director.newScene() 
----------------------------------------------- Variables
local backgroundLayer, targetLayer, dynamicLayer
local manager, isFirstTime
local level, timeToSort
local counterObjects, randomObject, objectType, totalObjectsToSort
local van
local tabEnable
local leftBox, rightBox
local counterBox, randomBox
----------------------------------------------- Constants
local OBJECTS = {
  [11] = {image = assetPath.."calculadora.png", objectType = "computing"},
  [6] = {image = assetPath.."cellphone.png", objectType = "computing"},
  [10] = {image = assetPath.."consola.png", objectType = "computing"},
  [1] = {image = assetPath.."lampara.png", objectType = "home"},
  [7] = {image = assetPath.."laptop.png", objectType = "computing"},
  [2] = {image = assetPath.."licuadora.png", objectType = "home"},
  [3] = {image = assetPath.."maceta.png", objectType = "home"},
  [8] = {image = assetPath.."pc.png", objectType = "computing"},
  [4] = {image = assetPath.."plancha.png", objectType = "home"},
  [13] = {image = assetPath.."registradora.png", objectType = "computing"},
  [9] = {image = assetPath.."robot.png", objectType = "computing"},
  [5] = {image = assetPath.."tablet.png", objectType = "computing"},
  [12] = {image = assetPath.."z.png", objectType = "computing"},
  [14] = {image = assetPath.."atm.png", objectType = "computing"}
  }
----------------------------------------------- Caches

----------------------------------------------- Functions
local function endGame()
  manager.wrong()
end
local function startTimer()
  if level > 1 then
    timer.performWithDelay(timeToSort, endGame)
  end
end
local function shakeObject()
  transition.to(objectToSort, {time = 70, rotation = 10, onComplete = function()
    transition.to(objectToSort, {time = 70, rotation = -10, onComplete = function()
      transition.to(objectToSort, {time = 70, rotation = 10, onComplete = function()
        transition.to(objectToSort, {time = 70, rotation = -10, onComplete = function()
          transition.to(objectToSort, {time = 70, rotation = 0, onComplete = function()
          end})
        end})
      end})
    end})
  end})
end
local function sortBoxes()
  randomBox = math.random(1, 2)
  if randomBox == 1 then
    leftBox.fill = {type = "image", filename = assetPath.."caja1.png"}
    leftBox.boxType = "computing"
    rightBox.fill = {type = "image", filename = assetPath.."caja2.png"}
    rightBox.boxType = "home"
  else
    leftBox.fill = {type = "image", filename = assetPath.."caja2.png"}
    leftBox.boxType = "home"
    rightBox.fill = {type = "image", filename = assetPath.."caja1.png"}
    rightBox.boxType = "computing"
  end
end
local function turnValidation()
  
  counterObjects = counterObjects + 1
  counterBox = counterBox + 1
  
  objectToSort:removeSelf()
  
  if counterBox % 5 == 0 and counterBox ~= totalObjectsToSort then
    tabEnable = false
    transition.to(leftBox, {time = 500, xScale = 0.01, yScale = 0.01, alpha = 0, transition = easing.outBack})
    transition.to(rightBox, {time = 500, xScale = 0.01, yScale = 0.01, alpha = 0, transition = easing.outBack, onComplete = function()
      sortBoxes()
      transition.to(leftBox, {time = 500, xScale = 1, yScale = 1, alpha = 1, transition = easing.outBack})
      transition.to(rightBox, {time = 500, xScale = 1, yScale = 1, alpha = 1, transition = easing.outBack, onComplete = function()
        tabEnable = true
      end})
    end})
  end
  
  if counterObjects == totalObjectsToSort then
    manager.correct()
  else
    van:createObject()
  end
end
local function checkBox()
  if objectToSort.contentBounds.xMax >= leftBox.contentBounds.xMin 
  and objectToSort.contentBounds.xMin <= leftBox.contentBounds.xMax 
  and objectToSort.contentBounds.yMax >= leftBox.contentBounds.yMin
  and objectToSort.contentBounds.yMin <= leftBox.contentBounds.yMin then
    if objectToSort.objectType == leftBox.boxType then
      transition.to(objectToSort, {time = 200, x = leftBox.x, y = leftBox.y, onComplete = function()
        transition.to(objectToSort, {time = 300, xScale = 0.01, yScale = 0.01, y = leftBox.y - leftBox.height * 0.4, onComplete = function()
          turnValidation()
        end})
      end})
    else
      shakeObject()
      transition.to(objectToSort, {delay = 600, time = 1000, x = rightBox.x, y = rightBox.y, onComplete = function()
        transition.to(objectToSort, {time = 300, xScale = 0.01, yScale = 0.01, y = rightBox.y - rightBox.height * 0.4, onComplete = function()
          objectToSort:removeSelf();
          van:createObject()
        end})
      end})
    end
  elseif objectToSort.contentBounds.xMax >= rightBox.contentBounds.xMin 
  and objectToSort.contentBounds.xMin <= rightBox.contentBounds.xMax 
  and objectToSort.contentBounds.yMax >= rightBox.contentBounds.yMin
  and objectToSort.contentBounds.yMin <= rightBox.contentBounds.yMin then
    if objectToSort.objectType == rightBox.boxType then
      transition.to(objectToSort, {time = 200, x = rightBox.x, y = rightBox.y, onComplete = function()
        transition.to(objectToSort, {time = 300, xScale = 0.01, yScale = 0.01, y = rightBox.y - rightBox.contentHeight * 0.4, onComplete = function()
          turnValidation()
        end})
      end})
    else
      shakeObject()
      transition.to(objectToSort, {delay = 600, time = 1000, x = leftBox.x, y = leftBox.y, onComplete = function()
        transition.to(objectToSort, {time = 300, xScale = 0.01, yScale = 0.01, y = leftBox.y - leftBox.contentHeight * 0.4, onComplete = function()
          objectToSort:removeSelf()
          van:createObject()
        end})
      end})
    end
  else
    transition.to(objectToSort, {x = display.contentCenterX, y = display.contentHeight * 0.4, onComplete = function()
      tabEnable = true
    end})
  end
end
local function onObjectTouch( event )
  if tabEnable then
    local touchedObject = event.target
    
    if ( event.phase == "began" ) then
        display.getCurrentStage():setFocus( touchedObject )
        touchedObject.isFocus = true
        
    elseif ( touchedObject.isFocus ) then
        if ( event.phase == "moved" ) then
            touchedObject.x = event.x
            touchedObject.y = event.y
 
        elseif ( event.phase == "ended" or event.phase == "cancelled" ) then
 
            display.getCurrentStage():setFocus( nil )
            touchedObject.isFocus = nil
            tabEnable=false
            checkBox()
        end
    end
  end
  return true
end
local function objectOutBack()
  transition.to(objectToSort, { time = 700, alpha = 1, xScale = 0.7, yScale = 0.7, transition = easing.outBack, onComplete = function()
  tabEnable=true
end})
end
local function cleanUp()
  backgroundGroup:removeSelf()
  backgroundGroup = nil
  
  dynamicGroup:removeSelf()
  dynamicGroup = nil
  
  targetGroup:removeSelf()
  targetGroup = nil
end
local function createBoxes()
  
  leftBox = display.newRect(display.contentWidth * 0.3, display.contentHeight * 0.8, 269, 200)
  rightBox = display.newRect(display.contentWidth * 0.7, display.contentHeight * 0.8, 269, 200)
  
  dynamicGroup:insert(leftBox)
  dynamicGroup:insert(rightBox)
  
  sortBoxes()
end
local function createVan()
  van = display.newRect(display.contentCenterX, display.contentCenterY, 1, 1)
  backgroundGroup:insert(van)
  
  function van:createObject()
    if level == 1 then
      randomObject = math.random(1, 8)
    elseif level == 2 then
      randomObject = math.random(1, 11)
    else
      randomObject = math.random(1, 14)
    end
  
    objectToSort = display.newImage(OBJECTS[randomObject].image)
    objectToSort.objectType = OBJECTS[randomObject].objectType
    objectToSort.alpha = 0
    objectToSort.x, objectToSort.y = display.contentCenterX, display.contentHeight * 0.4
    objectToSort:scale(0.01, 0.01)
  
    targetLayer:insert(objectToSort)
  
    objectToSort:addEventListener("touch", onObjectTouch)
  
    objectOutBack()
  end
  
end
local function initialize(event)
	event = event or {} 
	local params = event.params or {}
    local sceneParams = params.sceneParams

	isFirstTime = params.isFirstTime 
	manager = event.parent 
  
  math.randomseed(os.time())
  
  tabEnable=true
  
  level = 2
  counterBox = 0
  counterObjects = 0
  totalObjectsToSort = 20
  
  if level == 1 then
    totalObjectsToSort = 15
  elseif level == 2 then
    timeToSort = 60000
  else
    timeToSort = 45000
  end
  
  backgroundGroup = display.newGroup()
  backgroundLayer:insert(backgroundGroup)
  
  targetGroup = display.newGroup()
  targetLayer:insert(targetGroup)
  
  dynamicGroup = display.newGroup()
  dynamicLayer:insert(dynamicGroup)
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

function game:create(event) 
	local sceneView = self.view
	
	backgroundLayer = display.newGroup() 
	sceneView:insert(backgroundLayer)
  
  dynamicLayer = display.newGroup()
  sceneView:insert(dynamicLayer)
  
  targetLayer = display.newGroup() 
	sceneView:insert(targetLayer)
  
  local backGroundImage = display.newImageRect(assetPath..'background.png', display.contentWidth, display.contentHeight)
  backGroundImage.x = display.contentCenterX
  backGroundImage.y = display.contentCenterY
  backgroundLayer:insert(backGroundImage)
end  

function game:show(event) 
	local sceneView = self.view
	local phase = event.phase
	
	if phase == "will" then 
		initialize(event)
    createVan()
    startTimer()
    createBoxes()
    van:createObject()
	elseif phase == "did" then 
		
	end
end

function game:hide(event)
	local sceneView = self.view
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