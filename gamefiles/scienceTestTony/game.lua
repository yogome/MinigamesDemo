----------------------------------------------- Requires
local scenePath = ... 
local folder = scenePath:match("(.-)[^%.]+$") 
local assetPath = string.gsub(folder,"[%.]","/") 
local localization = require( "libs.helpers.localization" )
local director = require( "libs.helpers.director" )

local game = director.newScene() 
----------------------------------------------- Variables
local backgroundLayer, productsLayer, interactiveLayer
local isFirstTime, manager
local lineDistance, circleDistance
local gameLoopTimer
local yogotarGroup, conveyorGroup
local filledProducts
----------------------------------------------- Constants
local SCREEN_WIDTH = display.viewableContentWidth
local SCREEN_HEIGHT = display.viewableContentHeight
local CONVEYOR_LINES_NUMBER = 41 
local CONVEYOR_SCREW_QUANTITY = 20
local PANEL_HEIGHT = 120
local NUMBER_MATERIALS = 4
local SCALE_MATERIAL = 0.9
local MATERIAL_TEXT_POSITION_OFFSTE_Y = 75
local CONVEYOR_LINE_SIZE = {8, 180}
local CONVEYOR_HEIGHT = 194

local FONT_NAME = native.systemFont --settings.fontName
local FONT_SIZE_NUMBER = 45
local FONT_SIZE_MATERIAL = 36

local CONVEYOR_ELEMENTS_COLOR = {110/255, 127/255, 192/255}
local NUMBER_QUANTITY_COLOR = {0, 0, 0}

local PRODUCTS_GENERATED = 10

local MATERIALS = {
    [1] = {image = "wood.png", text = "Wood", offSetX = -384, textPositionOffsteX = -400}, 
	[2] = {image = "mineral.png", text = "Mineral", offSetX = -128, textPositionOffsteX = -140},
	[3] = {image = "cotton.png", text = "Cotton", offSetX = 128, textPositionOffsteX = 145},
	[4] = {image = "petroleum.png", text = "Petroleum", offSetX = 384, textPositionOffsteX = 420}
}

local PRODUCTS = {
    [1] = {siluette = "ballSilhouette.png", image = "ball.png", material = "petroleum.png", requirment = 1}, 
	[2] = {siluette = "canSilhouette.png", image = "can.png", material = "mineral.png", requirment = 1},
	[3] = {siluette = "chairSilhouette.png", image = "chair.png", material = "wood.png", requirment = 2},
	[4] = {siluette = "coinSilhouette.png", image = "coin.png", material = "mineral.png", requirment = 1},
	[5] = {siluette = "notebookSilhouette.png", image = "notebook.png", material = "wood.png", requirment = 1},
	[6] = {siluette = "sweterSilhouette.png", image = "sweter.png", material = "cotton.png", requirment = 2},
	[7] = {siluette = "tableSilhouette.png", image = "table.png", material = "wood.png", requirment = 4}
}
----------------------------------------------- Caches
local mathRandom = math.random
----------------------------------------------- Functions
local function fillMask(quantity, imgMasked, quantityNeeded)
	local offSet = (256 - imgMasked.height) / 2 + (imgMasked.height) * (1 - (quantity / quantityNeeded))
	director.to(scenePath, imgMasked, {time = 200, maskY = offSet, transition = easing.lineal})
end

local function validateMaterial(self)
	local isAnswered = false
	
	for numProductsIndex = 1, productsLayer.numChildren  do
		local productInScreen = productsLayer[numProductsIndex]
		
		if self.x > productInScreen.contentBounds.xMin and self.x < productInScreen.contentBounds.xMax and
		self.y > productInScreen.contentBounds.yMin and self.y < productInScreen.contentBounds.yMax and
		productInScreen.currentQuantity < productInScreen.quantity then
			isAnswered = true
			self.x = self.xOrign
			self.y = self.yOrign
			
			if self.image == productInScreen.materialImage.image then
				productInScreen.quantityRequired.text = productInScreen.quantityRequired.text - 1
				productInScreen.currentQuantity = productInScreen.currentQuantity + 1
				
				fillMask(productInScreen.currentQuantity, productInScreen.productImage, productInScreen.quantity)
				
				if productInScreen.currentQuantity == productInScreen.quantity then
					filledProducts = filledProducts + 1
				end
			end	
		end
	end 
	
	if not isAnswered then
		director.to(scenePath, self, {time = 200, x = self.xOrign , y = self.yOrign, transition = easing.linear})  
	end
end

local function dragMaterial(event)
	local material = event.target
	local phase = event.phase
	
	if phase == "began" then
		material.isFocus = true
		display.currentStage:setFocus(material)
		material:toFront()
	elseif material.isFocus then 
		if phase == "moved" then
			material.x = event.x
			material.y = event.y 
		elseif "ended" == phase or "cancelled" == phase then
			display.currentStage:setFocus( nil )
			material.isFocus = false
			validateMaterial(material)
		end
	end
	return true
end

local function moveConveyor(self)
    director.to(scenePath, self, {time = 200, x = self.x + 40 , transition = easing.linear, iterations = -1})
end

local function rotateObjects(self)
	director.to(scenePath, self, {rotation = 360, time = 800, transition = easing.lineal, iterations = -1})
end

local function createYogotar()
	local yogotar = display.newImage(assetPath.."eagle-01.png")
    yogotar.x = display.contentWidth - 182
    yogotar.y = display.contentCenterY - 85
	yogotar.xScale = - 1.3
	yogotar.yScale = 1.3
    yogotarGroup:insert(yogotar)
end
	
local function createConveyor()
	local conveyor = display.newImageRect(assetPath.."conveyor.png", SCREEN_WIDTH, CONVEYOR_HEIGHT)
    conveyorGroup:insert(conveyor)
	
	local linesGroup = display.newGroup()
	conveyorGroup:insert(linesGroup)
	
	for linesIndex = 1, CONVEYOR_LINES_NUMBER do
        local conveyorLine = display.newImageRect(assetPath.."panel.png", CONVEYOR_LINE_SIZE[1], CONVEYOR_LINE_SIZE[2])
        conveyorLine.x = display.screenOriginX + lineDistance - display.contentCenterX
        conveyorLine.y = conveyor.y - 25
		conveyorLine.rotation = - 30
		conveyorLine.alpha = 0.7
        conveyorLine:scale(0.8, 0.8)
        lineDistance = lineDistance + 40
        linesGroup:insert(conveyorLine)	
	end
	
	moveConveyor(linesGroup)
	
	for circlesIndex = 1, CONVEYOR_SCREW_QUANTITY do
		local conveyorCircle = display.newCircle(0, 0, 13) 
		conveyorCircle.x = circleDistance - display.contentCenterX
		conveyorCircle.y = conveyor.y + 68
		conveyorCircle.strokeWidth = 4
		conveyorCircle:setFillColor(unpack(CONVEYOR_ELEMENTS_COLOR), 0)
		conveyorCircle:setStrokeColor(unpack(CONVEYOR_ELEMENTS_COLOR))
		conveyorGroup:insert(conveyorCircle)
				
		local conveyorLittleCircle = display.newCircle(0, 0, 3) 
		conveyorLittleCircle.x = circleDistance - display.contentCenterX
		conveyorLittleCircle.y = conveyor.y + 68
		conveyorLittleCircle:setFillColor(unpack(CONVEYOR_ELEMENTS_COLOR))
		conveyorGroup:insert(conveyorLittleCircle)
			
		local conveyorInnerLine = display.newRect(0, 0, 2, 13)
		conveyorInnerLine.x = circleDistance - display.contentCenterX
		conveyorInnerLine.y = conveyor.y + 68
		conveyorInnerLine:setFillColor(unpack(CONVEYOR_ELEMENTS_COLOR))
		conveyorInnerLine:setStrokeColor(unpack(CONVEYOR_ELEMENTS_COLOR))	
		conveyorGroup:insert(conveyorInnerLine)
		
		circleDistance = circleDistance + 63
			
		rotateObjects(conveyorInnerLine)	
    end
end

local function createMaterials()
	local boxes = display.newGroup()
	boxes.x = display.contentCenterX
	boxes.y = display.contentHeight - 110
	interactiveLayer:insert(boxes)
	
	local materialsGroup = display.newGroup()
	materialsGroup.x = display.contentCenterX
	materialsGroup.y = display.contentHeight - 160
	interactiveLayer:insert(materialsGroup)
	
	local interactiveGroup = display.newGroup()
	interactiveLayer:insert(interactiveGroup)
	
	local box = display.newImage(boxes, assetPath.."boxes.png")
	boxes:insert(box)
	
	for materialIndex = 1, NUMBER_MATERIALS do
		local materialImage = display.newImage(assetPath..MATERIALS[materialIndex].image)
		materialImage.xScale = SCALE_MATERIAL
		materialImage.yScale = SCALE_MATERIAL
		materialImage.x = MATERIALS[materialIndex].offSetX
		materialsGroup:insert(materialImage)
		
		local materialText = display.newText(boxes, localization.getString("testMinigameTonyCommonMaterial"..MATERIALS[materialIndex].text), MATERIALS[materialIndex].textPositionOffsteX, MATERIAL_TEXT_POSITION_OFFSTE_Y, FONT_NAME, FONT_SIZE_MATERIAL)
		boxes:insert(materialText)
	
		local material = display.newImage(assetPath..MATERIALS[materialIndex].image)
		material.xScale = SCALE_MATERIAL
		material.yScale = SCALE_MATERIAL
		material.x = display.contentCenterX + MATERIALS[materialIndex].offSetX
		material.y = display.contentHeight - 160
		material.xOrign = material.x
		material.yOrign = material.y
		material.image = MATERIALS[materialIndex].image
		material:addEventListener("touch", dragMaterial)
		interactiveGroup: insert(material)
	end
end

local function endGame()
	if filledProducts == PRODUCTS_GENERATED then
		manager.correct()
	else
		manager.wrong()
	end
end

local function createProducts(event)
	local randomProductIndex = mathRandom(#PRODUCTS)
	
	local productGroup = display.newGroup() 
	productGroup.x = -300
	productGroup.y = SCREEN_HEIGHT / 2 + 80
	productGroup.anchorY = 1
	productGroup.anchorChildren = true
	productsLayer:insert(productGroup)
	
	local siluette = display.newImage(assetPath..PRODUCTS[randomProductIndex].siluette)
	productGroup:insert(siluette)
	
	local mask = graphics.newMask(assetPath.."mask.png")
	
	local productImage = display.newImage(assetPath..PRODUCTS[randomProductIndex].image)
	productImage:setMask(mask)
	productImage.maskY = (256 - productImage.height) / 2 + (productImage.height)
	productGroup:insert(productImage)
	
	local productBox = display.newGroup()
	productBox.y = -180
	productGroup:insert(productBox)
	
	local info = display.newImage(assetPath.."info.png")
	productBox:insert(info)
	
	local materialImage = display.newImage(assetPath..PRODUCTS[randomProductIndex].material)
	materialImage.xScale = .3
	materialImage.yScale = .3
	materialImage.x = - 60
	materialImage.image = PRODUCTS[randomProductIndex].material
	productBox:insert(materialImage)
	
	local quantityRequired = display.newText(PRODUCTS[randomProductIndex].requirment, display.screenOriginX, display.screenOriginY, FONT_NAME, FONT_SIZE_NUMBER)
	quantityRequired.x = 60
	quantityRequired:setFillColor(unpack(NUMBER_QUANTITY_COLOR))
	productBox:insert(quantityRequired)
	
	productGroup.currentQuantity = 0
	productGroup.quantity = PRODUCTS[randomProductIndex].requirment
	
	productGroup.quantityRequired = quantityRequired
	productGroup.productImage = productImage
	productGroup.materialImage = materialImage
	
	director.to(scenePath, productGroup, {time = 8000, x = SCREEN_WIDTH + 300 , transition = easing.linear, onComplete = function() 
		display.remove(productGroup)
		if event.count == PRODUCTS_GENERATED - 1 then
			endGame()
		end
	end})
end

local function cleanUp()
	display.remove(yogotarGroup)
	yogotarGroup = nil
	display.remove(conveyorGroup)
	conveyorGroup = nil
	display.remove(interactiveLayer)
	interactiveLayer = nil
end
	
local function initialize(event)
	event = event or {} 
	local params = event.params or {}
	
	isFirstTime = params.isFirstTime 
	manager = event.parent 
	
    lineDistance = -40
	circleDistance = 40
	filledProducts = 0
	
	yogotarGroup = display.newGroup() 
	backgroundLayer:insert(yogotarGroup)
	
	conveyorGroup = display.newGroup() 
	conveyorGroup.x = display.contentCenterX
    conveyorGroup.y = display.contentCenterY + 80
	backgroundLayer:insert(conveyorGroup)
end
----------------------------------------------- Module functions


function game:create(event) 
	local sceneView = self.view
	
	backgroundLayer = display.newGroup() 
	sceneView:insert(backgroundLayer)
	
	productsLayer = display.newGroup() 
	sceneView:insert(productsLayer)
	
	interactiveLayer = display.newGroup() 
	sceneView:insert(interactiveLayer)
	
	local background = display.newImageRect(assetPath.."bgd.png", SCREEN_WIDTH + 2, SCREEN_HEIGHT +  2)
    background.x = display.contentCenterX
    background.y = display.contentCenterY
    backgroundLayer:insert(background)
	
	local panel = display.newImageRect(assetPath.."panel.png", SCREEN_WIDTH + 2, PANEL_HEIGHT)
    panel.x = display.contentCenterX
    panel.y = display.contentHeight - 60
    interactiveLayer:insert(panel)	
end

function game:show(event) 
	local phase = event.phase

	if phase == "will" then 
		initialize(event)
		createYogotar()
		createConveyor()
		createMaterials()
		createProducts(event)
		gameLoopTimer = timer.performWithDelay(3000, createProducts, PRODUCTS_GENERATED - 1)
	elseif phase == "did" then 
		
	end
end

function game:hide(event)
	local phase = event.phase

	if phase == "will" then 
		
	elseif phase == "did" then 
		timer.cancel(gameLoopTimer)
		cleanUp()
	end
end
----------------------------------------------- Execution
game:addEventListener("create")
game:addEventListener("hide")
game:addEventListener("show")

return game