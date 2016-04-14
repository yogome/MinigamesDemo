----------------------------------------------- Test minigame
local scenePath = ... 
local folder = scenePath:match("(.-)[^%.]+$") 
local assetPath = string.gsub(folder,"[%.]","/") 
local localization = require( "libs.helpers.localization" )
local director = require( "libs.helpers.director" )
local settings = require( "settings" ) 

local game = director.newScene()

--Variables 
local answersLayer
local backgroundLayer
local candyButtonsTable, candyNumberTable, candyTable, candyConveyorTable
local selectedCandyButton, valueMissingCandy, candyNumber, randomCandy, candyPattern, candy
local secondScene
local tubeExecution, conveyor, converyotLineTable, lineDistance,  barrelsTable
local boxOptions, candyBox, box
local conveyorGroup

--Constants
local CANDIES = {
	[1] = {path = "candybarra1.png",}, 
	[2] = {path = "candybarra2.png"}, 
	[3] = {path = "candybarra3.png"},
	[4] = {path = "candybarra4.png"},
    [5] = {path = "container.png"}
}
local BARRELS = {
	[1] = {path = "barrel1.png"}, 
	[2] = {path = "barrel2.png"}, 
	[3] = {path = "barrel3.png"},
	[4] = {path = "barrel4.png"}
}
local CANDY_BUTTONS = {
	[1] = {path = "candybutton1.png", barrel = "barrel1.png"}, 
	[2] = {path = "candybutton2.png", barrel = "barrel2.png"}, 
	[3] = {path = "candybutton3.png", barrel = "barrel3.png"},
	[4] = {path = "candybutton4.png", barrel = "barrel4.png"}
}
local POSITIONS = {
    [1] = {x = 50, y = 200}, 
	[2] = {x = 110, y = 200},
    [3] = {x = 150, y = 200}, 
	[4] = {x = 200, y = 200},
    [5] = {x = 250, y = 200}	
}
local SCREEN_WIDTH = display.viewableContentWidth
local SCREEN_HEIGHT = display.viewableContentHeight

local CONVEYOR_SIZE = 35
local CANDY_NUMBER = 5
local BARREL_NUMBER = 3
local BOX_OPTION_NUMBER = 3

--Local functions

local function shuffle(tableS)
	local n, order, oTable = #tableS, {}, {}
	for i=1,n do 
        order[i] = { rnd = math.random(), idx = i } 
    end
	table.sort(order, function(a,b) return a.rnd < b.rnd end)
	for i=1,n do 
        oTable[i] = tableS[order[i].idx] end
	return oTable
end

local function createScenario()
    local fan = display.newImage(assetPath.."ventilador.png")
    fan.x = display.contentCenterX * 0.5
    fan.y = display.contentCenterY * 0.3
    director.to(scenePath, fan, { rotation= 360, time=1000, transition=easing.lineal, iterations= -1 } )
    backgroundLayer:insert(fan)
    
    local fan2 = display.newImage(assetPath.."ventilador.png")
    fan2.x = display.contentCenterX * 1.3
    fan2.y = display.contentCenterY * 0.3
    fan2:scale(1.2, 1.2)
    director.to(scenePath, fan2, { rotation= 360, time=1400, transition=easing.lineal, iterations= -1 } )
    backgroundLayer:insert(fan2)
    
    candyBox = display.newImage(assetPath.."candyBox.png")
    candyBox.x = display.contentCenterX + 196
    candyBox.y = display.contentCenterY + 30
    candyBox: scale(0.47,0.47)
    candyBox.alpha= 0   
    
    local boxOptions = {
        width = 375,
        height = 300,
        numFrames = 16
    }

    local candyPatternsBox = { 
        name= "on",
        start = 1,
        count = 16,
        time = 800,
        loopCount = 1,
        loopDirection = "forward"
    }
    
    conveyor = display.newImage(assetPath.."conveyor.png")
    conveyor.x = display.screenOriginX + conveyor.width * 0.5
    conveyor.y = display.contentCenterY * 1.5
    conveyorGroup:insert(conveyor)
    local boxSprite = graphics.newImageSheet(assetPath.."box.png", boxOptions )
    box = display.newSprite( boxSprite, candyPatternsBox )
    box.x = conveyor.x * 2.05
    box.y = conveyor.y * 0.75
    box.alpha = 0
    backgroundLayer:insert(box)
    box:toBack()

    local emptyBox = display.newImage(assetPath.."cajavacia.png")
    emptyBox.x = conveyor.x * 2.05
    emptyBox.y = conveyor.y * 0.83
    conveyorGroup:insert(emptyBox)
    emptyBox:toBack()
end

local function moveLines()
    for linesIndex = 0, CONVEYOR_SIZE do
        director.to(scenePath,converyotLineTable[linesIndex],{time = 500, tag = "BELT", x = converyotLineTable[linesIndex].x + 10.1 , transition = easing.linear , iterations= -1 })

    end
end

local function playTube()
    tubeExecution:play()
end

local function playBoxCandy()
    box:play()
end

local function packCandies()
    director.to(scenePath, box ,{time= 300, alpha = 1})
    moveLines()
    director.performWithDelay(scenePath, 3000, playBoxCandy )
    
    local distance = conveyor.height * 2
    for moveCandyIndex = CANDY_NUMBER, 1, -1 do
        director.to(scenePath,candyNumberTable[moveCandyIndex], {time= 500 + (moveCandyIndex * 500), x = distance, transition=easing.linear})
        director.to(scenePath,candyNumberTable[moveCandyIndex], {time= 50 + (moveCandyIndex * 50), delay = 500 + (moveCandyIndex * 500), y = display.contentCenterY + 20, alpha = 0, transition=easing.linear})

        if( moveCandyIndex == randomCandy) then
            director.to(scenePath,candyTable[selectedCandyButton], {time= 500 + (moveCandyIndex * 500), x = distance, transition=easing.linear})
            director.to(scenePath,candyTable[selectedCandyButton], {time= 50 + (moveCandyIndex * 50), delay = 500 + (moveCandyIndex * 500), y = display.contentCenterY + 20, alpha = 0, transition=easing.linear})
        end
    end  
    
end

local function moveCandy()
    for moveCandyIndex = CANDY_NUMBER, 1, -1 do
    director.to(scenePath,candyNumberTable[moveCandyIndex], {time= 300 , x = math.random (100, 300), transition=easing.linear})
    end
end

local function createCandy()  
    local tubeOptions = {
        width = 190,
        height = 293.33,
        numFrames = 12
    }
    local candyPatternsTube = { 
        name= "on",
        start = 1,
        count = 12,
        time = 500,
        loopCount = 1,
        loopDirection = "forward"
    }
    local tubeSprite = graphics.newImageSheet(assetPath.. "Tubo.png", tubeOptions )
    
    tubeExecution = display.newSprite( tubeSprite, candyPatternsTube )
    tubeExecution.x = display.screenOriginX + tubeExecution.width * 0.8
    tubeExecution.y = display.screenOriginY + tubeExecution.height * 0.4
    backgroundLayer:insert(tubeExecution)

    for linesIndex=0, CONVEYOR_SIZE do
        converyotLineTable[linesIndex] = display.newImage(assetPath.."linea.png")
        converyotLineTable[linesIndex].x = display.screenOriginX + lineDistance
        converyotLineTable[linesIndex].y = conveyor.y * 0.69
        lineDistance = lineDistance + converyotLineTable[linesIndex].width * 0.2
        converyotLineTable[linesIndex]:scale(0.6, 0.6)
        conveyorGroup:insert(converyotLineTable[linesIndex])
    end
    moveLines()

local candyPatternCounter = candyPattern * 6
    for moveCandyIndex = 1, CANDY_NUMBER do
        candy = math.random(1, 4)
        candyConveyorTable[moveCandyIndex] = display.newImage(assetPath..CANDIES[candy].path)
        candyConveyorTable[moveCandyIndex].path = candy
        candyConveyorTable[moveCandyIndex].value = candyPatternCounter 

        candyPatternCounter = candyPatternCounter - candyPattern
        
        local number =  display.newText(candyConveyorTable[moveCandyIndex].value, display.screenOriginX, display.screenOriginY, native.systemFont)
        number:setTextColor(0, 0, 0)
        
        candyNumber = display.newGroup()
        valueMissingCandy =candyConveyorTable[moveCandyIndex].value
        candyNumber: insert(candyConveyorTable[moveCandyIndex])
        candyNumber: insert(number)
        candyNumber.anchorChildren = true
        candyNumber.x = display.screenOriginX + tubeExecution.width * 0.75
        candyNumber.y = display.screenOriginY - tubeExecution.width * 1
        
        candyNumberTable[moveCandyIndex] = candyNumber
        candyNumberTable[moveCandyIndex].path = (CANDY_BUTTONS[candy].path)
        candyNumberTable[moveCandyIndex].value = candyConveyorTable[moveCandyIndex].value
        conveyorCandyGroup:insert(candyNumberTable[moveCandyIndex])
        
    end
        
        valueMissingCandy = candyConveyorTable[randomCandy].value
        candyConveyorTable[randomCandy] = display.newImage(assetPath..CANDIES[CANDY_NUMBER].path)
        
        candyNumber = display.newGroup()
        candyNumber: insert(candyConveyorTable[randomCandy])
        candyNumber.x = display.screenOriginX + tubeExecution.width * 0.75
        candyNumber.y = display.screenOriginY - tubeExecution.width * 1
        candyNumber.anchorChildren = false
        candyNumberTable[randomCandy] = candyNumber
        conveyorCandyGroup:insert(candyNumberTable[randomCandy])

    local distance = conveyor.height * 1.7       
    for candiesIndex = 1, CANDY_NUMBER do
        director.to(scenePath,candyNumberTable[candiesIndex], {time=1400, delay= candiesIndex * 1000, y = display.contentCenterY * 0.9, transition=easing.outBounce})
        director.to(scenePath,candyNumberTable[candiesIndex], {time= 4500 - (candiesIndex * 1000), delay= (candiesIndex + 1) * 1000, x = distance, transition=easing.linear, onComplete = function() 
            if candiesIndex == CANDY_NUMBER then transition.cancel("BELT") end
        end})

        director.performWithDelay(scenePath,  1020 * candiesIndex, playTube )
        distance = distance - candyNumber.width * 1.2
        candyConveyorTable[randomCandy].pX = candyConveyorTable[randomCandy].x
        candyConveyorTable[randomCandy].pY = candyConveyorTable[randomCandy].y
        

        
    end
end

local function touchBox(event)
    local currentBox= event.target
    if event.phase == "began" then
        display.getCurrentStage():setFocus( currentBox )
    elseif event.phase == "moved" then
    	
    elseif event.phase == "ended" then
        display.getCurrentStage():setFocus(nil)
        if currentBox.value == candyPattern then
            director.to(scenePath,secondScene, {time=500, alpha= 0})

            packCandies()
        else
            local red = { 1, 0.2, 0.2 }
            local green = { 0.72, 0.9, 0.16, 0.78 }
            currentBox:setFillColor(  1, 0.2, 0.2)

            for boxOptionIndex = 1, BOX_OPTION_NUMBER do
                if boxOptions[boxOptionIndex].value == candyPattern then
                boxOptions[boxOptionIndex]:setFillColor( 0.72, 0.9, 0.16 )
                transition.scaleTo( boxOptions[boxOptionIndex],{time=500, xScale= 0.7, yScale = 0.7, transition = easing.inOutBack })
                
                end
            end
        end
    end
    return true  
end

local function showSecondScene(answer)
    local container = display.newRect( 0, 0, display.viewableContentWidth , display.viewableContentWidth )
    container.x = display.contentCenterX 
    container.y = display.contentCenterY -20
    container.alpha = 0
    container.fill= {0}
    director.to(scenePath,container,{time = 100, alpha = 0.5})
    secondScene: insert(container)
    boxOptions = {}

    for boxOptionIndex = 1, BOX_OPTION_NUMBER do
        boxOptions[boxOptionIndex]= display.newImage(assetPath.."option.png")
        boxOptions[boxOptionIndex]:scale(0.7, 0.7)
        boxOptions[boxOptionIndex].value = math.random(answer + candyPattern)
        while boxOptions[boxOptionIndex].value == answer do
            for q = 1, 3 do
                if boxOptions[boxOptionIndex].value == boxOptions[q].value then
                    boxOptions[boxOptionIndex].value = math.random(answer + candyPattern)
                end
            end
        end
        secondScene: insert(boxOptions[boxOptionIndex])
    end
    
    boxOptions[BOX_OPTION_NUMBER].value = answer
    boxOptions = shuffle(boxOptions)
    distance = 200
    for boxOptionIndex = 1, BOX_OPTION_NUMBER do

        boxOptions[boxOptionIndex].x = 105 + distance
        boxOptions[boxOptionIndex].y = display.contentCenterY + 100
        local number =  display.newText("+"..boxOptions[boxOptionIndex].value, 120 + distance, display.contentCenterY + 110, native.systemFont)
        number:setTextColor(0,0,0)
        distance = distance + boxOptions[boxOptionIndex].width
        boxOptions[boxOptionIndex]:addEventListener( "touch", touchBox )
        secondScene: insert(number)
    end
    
    local candyConfirmation

    local distance = 230
    local candyConfirmation= {}
     for candyIndex=CANDY_NUMBER, 1, -1 do
        candyConfirmation[candyIndex] = display.newImage(assetPath..candyNumberTable[candyIndex].path)
        local number = display.newText(candyNumberTable[candyIndex].value, distance, 130 , native.systemFont)
        number:setTextColor(0,0,0)
        candyConfirmation[candyIndex].x = distance
        candyConfirmation[candyIndex].y = 130
        distance = distance + candyConfirmation[candyIndex].height * 1.3
        secondScene: insert(candyConfirmation[candyIndex])
        secondScene: insert(number)
    end
    
    
end

local function touchCandyButton(event)
    local currentCandy= event.target

    if event.phase == "began" then
        display.getCurrentStage():setFocus( currentCandy )
    elseif event.phase == "moved" then
    	currentCandy.x = event.x
        currentCandy.y = event.y

    elseif event.phase == "ended" then
       
        display.getCurrentStage():setFocus(nil)
        if(currentCandy.contentBounds.xMin - 30 < candyConveyorTable[randomCandy].contentBounds.xMin and
           currentCandy.contentBounds.xMax + 30 > candyConveyorTable[randomCandy].contentBounds.xMax and
           currentCandy.contentBounds.yMin - 30 < candyConveyorTable[randomCandy].contentBounds.yMin and
           currentCandy.contentBounds.yMax + 30 > candyConveyorTable[randomCandy].contentBounds.yMax and
           currentCandy.value == valueMissingCandy) then
            showSecondScene(candyPattern)
            secondScene:toFront()
            
            candyConveyorTable[randomCandy].alpha = 0
            selectedCandyButton = currentCandy.position
            director.to(scenePath, currentCandy, { time=200, x= candyNumberTable[randomCandy].x, y = candyNumberTable[randomCandy].y, transition=easing.linear })
            currentCandy:removeEventListener( "touch", touchCandyButton )
        else
            director.to(scenePath, currentCandy, { time=200, x= currentCandy.pX , y = currentCandy.pY, transition=easing.linear })
        end 
    end
    return true  
end

local function createBarrels()
    for barrelIndex = 1, BARREL_NUMBER - 1 do
        candy = math.random(1,4)
        candyButtonsTable[barrelIndex] = display.newImage(assetPath..CANDY_BUTTONS[candy].path)
        candyButtonsTable[barrelIndex].barrel = BARRELS[candy].path
        candyButtonsTable[barrelIndex].value = math.random(valueMissingCandy - candyPattern ,valueMissingCandy + candyPattern) 
        while candyPattern == candyButtonsTable[barrelIndex].value do
            candyButtonsTable[barrelIndex].value = math.random(valueMissingCandy - candyPattern,valueMissingCandy + candyPattern) 
            
        end
    end
    
    candyButtonsTable[BARREL_NUMBER] = display.newImage(assetPath..CANDY_BUTTONS[randomCandy].path)
    barrelsGroup:insert(candyButtonsTable[3])
    candyButtonsTable[BARREL_NUMBER].barrel = BARRELS[randomCandy].path
    candyButtonsTable[BARREL_NUMBER].value = valueMissingCandy
    candyNumberTable[randomCandy].path = (CANDY_BUTTONS[randomCandy].path)
    candyNumberTable[randomCandy].value = valueMissingCandy

    local dis= 40
    candyButtonsTable = shuffle(candyButtonsTable)
    for barrelIndex = 1, BARREL_NUMBER do
        local barrel = display.newImage(assetPath..candyButtonsTable[barrelIndex].barrel)
        barrel.x = barrel.height + dis
        barrel.y = display.contentHeight - barrel.height * 0.5
        barrelsGroup:insert(barrel)
        
        local candyButtonOption = display.newGroup()
        local number =  display.newText(candyButtonsTable[barrelIndex].value, display.contentCenterX , display.contentCenterY , native.systemFont)
    
        number.y = 3
        number.x = 0
        number:setTextColor(0,0,0)
        
        candyButtonOption: insert(candyButtonsTable[barrelIndex])
        candyButtonOption: insert(number)
        candyButtonOption.anchorChildren = true
        candyButtonOption.position = barrelIndex
        candyButtonOption: addEventListener( "touch", touchCandyButton )
        candyButtonOption.x = barrel.x
        candyButtonOption.y = barrel.y - barrel.height * 0.5 - 20
        candyButtonOption.value = candyButtonsTable[barrelIndex].value
        candyButtonOption.pX = candyButtonOption.x
        candyButtonOption.pY = candyButtonOption.y
        dis = dis + barrel.height * 1.5
        candyTable[barrelIndex] = candyButtonOption
        barrelsGroup:insert(candyButtonOption)
    end
end

local function initialize()
    converyotLineTable = {}
    lineDistance= - 20
    barrelsTable = {}
    candyButtonsTable = {}
    candyButtons = {}
    randomCandy = math.random(1, 4)
    candyPattern = math.random(5, 30)
    candyConveyorTable = {}
    candyNumberTable = {}
    candyTable = {}

    conveyorGroup = display.newGroup()
    backgroundLayer:insert(conveyorGroup)

    conveyorCandyGroup = display.newGroup()
    answersLayer:insert(conveyorCandyGroup)

    barrelsGroup = display.newGroup()
    answersLayer:insert(barrelsGroup)

    secondScene = display.newGroup()
    answersLayer:insert(secondScene)

end
----------------------------------------------- Module functions

function game.getInfo() 
    return {
        available = false, 
        correctDelay = 500, 
        wrongDelay = 500, 
        name = "Minigame tester", 
        category = "math", 
        subcategories = {"addition", "subtraction"}, 
        age = {min = 0, max = 99}, 
        grade = {min = 0, max = 99}, 
        gamemode = "findAnswer", 
        requires = { 
            {id = "operation", operands = 2, maxAnswer = 10, minAnswer = 1, maxOperand = 10, minOperand = 1},
            {id = "wrongAnswer", amount = 5},
        },
    }
end  

function game:create(event)
    local sceneView = self.view
    
    backgroundLayer = display.newGroup() 
    sceneView:insert(backgroundLayer)

    answersLayer = display.newGroup() 
    sceneView:insert(answersLayer)

    local background = display.newImageRect(assetPath.."fondo.png", SCREEN_WIDTH + 1, SCREEN_HEIGHT)
    background.x = display.contentCenterX
    background.y = display.contentCenterY
    backgroundLayer:insert(background)

end

function game:show(event)
	local phase = event.phase

	if phase == "will" then
        initialize()
        createScenario()
		createCandy()
        createBarrels()
        
	elseif phase == "did" then
	
	end
end

function game:hide( event )
	local phase = event.phase

	if phase == "will" then
		
	elseif phase == "did" then
		display.remove(conveyorGroup)
        display.remove(conveyorCandyGroup)
        display.remove(barrelsGroup)
        display.remove(secondScene)
	end
end

----------------------------------------------- Execution
game:addEventListener( "create", game )
game:addEventListener( "show" )
game:addEventListener( "hide" )

return game





