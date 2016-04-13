----------------------------------------------- Test minigame
local scenePath = ... 
local folder = scenePath:match("(.-)[^%.]+$") 
local assetPath = string.gsub(folder,"[%.]","/") 
local localization = require( "libs.helpers.localization" )
local director = require( "libs.helpers.director" )
local settings = require( "settings" ) 

local game = director.newScene()

--Variables 
local selectedCandyButton, candiesGroup, candyNumberT, candyButtonT, questionCandy, candyNumber, candyButtons, rndNumber, sequence, candy, candyButtonsGroup
local secondScene
local candyButtonQuestion
local tubeEx, conveyor, converyotLineG, lineDistance,  barrelsGroup
local boxOptions, candyBox, box

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

--Caches

--Local functions

local function initialize()
    converyotLineG = {}
    lineDistance= - 20
    barrelsGroup = {}
    candyButtonsGroup = {}
    candyButtons = {}
    rndNumber = math.random(1,4)
    sequence = math.random(5, 30)
    candiesGroup = {}
    candyNumberT = {}
    candyButtonT = {}
    secondScene = display.newGroup()
    candyButtonQuestion = display.newGroup()
end

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

local function scenario()
    local ventilador = display.newImage(assetPath.."ventilador.png")
    ventilador.x = display.contentCenterX * 0.5
    ventilador.y = display.contentCenterY * 0.3
    director.to(scenePath, ventilador, { rotation= 360, time=1000, transition=easing.lineal, iterations= -1 } )
    
    local ventilador2 = display.newImage(assetPath.."ventilador.png")
    ventilador2.x = display.contentCenterX * 1.3
    ventilador2.y = display.contentCenterY * 0.3
    ventilador2:scale(1.2, 1.2)
    director.to(scenePath, ventilador2, { rotation= 360, time=1400, transition=easing.lineal, iterations= -1 } )
    
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

    local sequencesBox = { 
        name= "on",
        start = 1,
        count = 16,
        time = 800,
        loopCount = 1,
        loopDirection = "forward"
    }
    local boxSprite = graphics.newImageSheet(assetPath.."box.png", boxOptions )
    box = display.newSprite( boxSprite, sequencesBox )
    box.x = display.contentCenterX + 196
    box.y = display.contentCenterY + 13
    box: scale(0.47,0.47) 
    box.alpha = 0
    
    conveyor = display.newImage(assetPath.."conveyor.png")
    conveyor.x = display.screenOriginX + conveyor.width * 0.5
    conveyor.y = display.contentCenterY * 1.5

    local caja = display.newImage(assetPath.."cajavacia.png")
    caja.x = conveyor.x * 2.05
    caja.y = conveyor.y * 0.83
    conveyor:toFront()
end

local function moveLines()
    lineDistance = 0
    for linesIndex = 0, CONVEYOR_SIZE do
        director.to(scenePath,converyotLineG[i],{time = 500, tag = "BELT", x = converyotLineG[linesIndex].x + lineDistance, transition = easing.linear , iterations= -1 })
        lineDistance = lineDistance + converyotLineG[linesIndex].width * 0.2
    end
end

local function tube()
    tubeEx:play()
end

local function boxCandy()
    box:play()
end

local function packCandies()
    director.to(scenePath,box,{time= 300, alpha = 1})
    converyotLineG[40].alpha=0
    moveLines()
    director.performWithDelay(scenePath, 3000, boxCandy )
    
    local distance = 430
    candyButtonQuestion:insert(candiesGroup[rndNumber])
    candyButtonQuestion:insert(candyNumberT[rndNumber])

    for i=5, 1, -1 do
        director.to(scenePath,candyNumberT[i], {time= 500 + (i * 500), x = distance, transition=easing.linear})
        director.to(scenePath,candyNumberT[i], {time= 50 + (i * 50), delay = 500 + (i * 500), y = 160, alpha = 0, transition=easing.linear})

        if( i == rndNumber) then
            director.to(scenePath,candyButtonT[selectedCandyButton], {time= 500 + (i * 500), x = distance, transition=easing.linear})
            director.to(scenePath,candyButtonT[selectedCandyButton], {time= 50 + (i * 50), delay = 500 + (i * 500), y = 160, alpha = 0, transition=easing.linear})
        end
    end  
    
end

local function moveCandy()
    for i=5, 1, -1 do
    director.to(scenePath,candyNumberT[i], {time= 300 , x = math.random (100, 300), transition=easing.linear})
    --director.to(scenePath,candyNumberT[i], {time= 600 , x = math.random (100, 300), transition=easing.linear})
    end
end

local function createCandy()  
    local tubeOptions =
    {
        width = 190,
        height = 293.33,
        numFrames = 12
    }
    local sequencesTube = { 
        name= "on",
        start = 1,
        count = 12,
        time = 500,
        loopCount = 1,
        loopDirection = "forward"
    }
    local tubeSprite = graphics.newImageSheet(assetPath.. "Tubo.png", tubeOptions )
    
    tubeEx = display.newSprite( tubeSprite, sequencesTube )
    tubeEx:toFront()
    tubeEx.x = display.screenOriginX + tubeEx.width * 0.8
    tubeEx.y = display.screenOriginY + tubeEx.height * 0.4

    for linesIndex=0, CONVEYOR_SIZE do
        converyotLineG[linesIndex] = display.newImage(assetPath.."linea.png")
        converyotLineG[linesIndex].x = display.screenOriginX + lineDistance
        converyotLineG[linesIndex].y = conveyor.y * 0.69
        lineDistance = lineDistance + converyotLineG[linesIndex].width * 0.2
        converyotLineG[linesIndex]:scale(0.6, 0.6)
    end

    moveLines()

local sequenceCounter = sequence * 6
    for i=1, 5 do
        candy = math.random(1,4)
        candiesGroup[i] = display.newImage(assetPath..CANDIES[candy].path)
        candiesGroup[i].path = candy
        candiesGroup[i].value = sequenceCounter 

        sequenceCounter = sequenceCounter - sequence
        
        local number =  display.newText(candiesGroup[i].value, display.screenOriginX, display.screenOriginY, native.systemFont)
        number:setTextColor(0,0,0)
        
        candyNumber = display.newGroup()
        questionCandy =candiesGroup[i].value
        candyNumber: insert(candiesGroup[i])
        candyNumber: insert(number)
        candyNumber.anchorChildren = true
        candyNumber.x = display.screenOriginX + tubeEx.width * 0.75
        candyNumber.y = display.screenOriginY - tubeEx.width * 1
        
        candyNumberT[i] = candyNumber
        candyNumberT[i].path = (CANDY_BUTTONS[candy].path)
        candyNumberT[i].value = candiesGroup[i].value
        
    end
        
        questionCandy=candiesGroup[rndNumber].value
        candiesGroup[rndNumber] = display.newImage(assetPath..CANDIES[5].path)
        
        candyNumber = display.newGroup()
        candyNumber: insert(candiesGroup[rndNumber])
        candyNumber.x = display.screenOriginX + tubeEx.width * 0.75
        candyNumber.y = display.screenOriginY - tubeEx.width * 1
        candyNumber.anchorChildren = false
        candyNumberT[rndNumber] = candyNumber
    local distance = conveyor.height * 1.7       
    for candiesIndex = 1, 5 do
        
        director.to(scenePath,candyNumberT[candiesIndex], {time=1400, delay= candiesIndex * 1000, y = display.contentCenterY * 0.9, transition=easing.outBounce})
        director.to(scenePath,candyNumberT[candiesIndex], {time= 4500 - (candiesIndex * 1000), delay= (candiesIndex + 1) * 1000, x = distance, transition=easing.linear, onComplete = function() 
            if candiesIndex == 5 then transition.cancel("BELT") end
        end})

        director.performWithDelay(scenePath,  1020 * candiesIndex, tube )
        distance = distance - candyNumber.width * 1.2
        candiesGroup[rndNumber].pX = candiesGroup[rndNumber].x
        candiesGroup[rndNumber].pY = candiesGroup[rndNumber].y
        
    end
end

local function touchBox(event)
    local currentBox= event.target
    if ( event.phase == "began" ) then
        display.getCurrentStage():setFocus( currentBox )
    elseif ( event.phase == "moved" ) then
    	
    elseif ( event.phase == "ended" ) then
        display.getCurrentStage():setFocus(nil)
        if(currentBox.value == sequence) then
            director.to(scenePath,secondScene, {time=500, alpha= 0})

            packCandies()
        else
            local red = { 1, 0.2, 0.2 }
            local green = { 0.72, 0.9, 0.16, 0.78 }
            currentBox:setFillColor(  1, 0.2, 0.2)

            for i = 1, 3 do
                if(boxOptions[i].value == sequence) then
                boxOptions[i]:setFillColor( 0.72, 0.9, 0.16 )
                transition.scaleTo( boxOptions[i],{time=500, xScale= 0.7, yScale = 0.7, transition = easing.inOutBack })
                
                end
            end
            
            moveCandy()

        end
       
    end
    return true  
end

local function confirmation(answer)
    local container = display.newRect( 0, 0, display.viewableContentWidth  ,display.viewableContentWidth )
    container.x = display.contentCenterX 
    container.y = display.contentCenterY -20
    container.alpha = 0
    container.fill= {0}
    director.to(scenePath,container,{time = 100, alpha = 0.5})
    secondScene: insert(container)
    boxOptions = {}
    local distance= 45
    for i = 1, 3 do
        boxOptions[i]= display.newImage(assetPath.."option.png")
        boxOptions[i].value = math.random(answer + sequence)
        while boxOptions[i].value == answer do
            for q = 1, 3 do
                if boxOptions[i].value == boxOptions[q].value then
                    boxOptions[i].value = math.random(answer + sequence)
                end
            end
        end
        secondScene: insert(boxOptions[i])
    end
    while boxOptions[2].value == boxOptions[1].value do
            for q = 1, 3 do
                if boxOptions[i].value == boxOptions[q].value then
                    boxOptions[i].value = math.random(answer + sequence)
                end
            end
        end
    boxOptions[3].value = answer
    boxOptions = shuffle(boxOptions)
    
    for i = 1, 3 do
        boxOptions[i].x = 100 + distance
        boxOptions[i].y = display.contentCenterY + 70
        local number =  display.newText("+"..boxOptions[i].value, 105 + distance, display.contentCenterY + 75, native.systemFont, 20)
        number:setTextColor(0,0,0)
        boxOptions[i]:scale(0.6, 0.6)
        distance = distance + 85
        boxOptions[i]:addEventListener( "touch", touchBox )
        secondScene: insert(number)
    end
    
    local candyConfirmation

    local distance = 70
    local candyConfirmation= {}
     for i=5, 1, -1 do
 
        candyConfirmation[i] = display.newImage(assetPath..candyNumberT[i].path)
        candyConfirmation[i]:scale(0.4, 0.4)
        local number = display.newText(candyNumberT[i].value, distance, 100 , native.systemFont, 20)
        number:setTextColor(0,0,0)
        candyConfirmation[i].x = distance
        candyConfirmation[i].y = 100
        distance = distance + 70
        secondScene: insert(candyConfirmation[i])
        secondScene: insert(number)
    end
    for i= 1, 5 do
        transition.scaleTo(candyConfirmation[i], {time=500, delay= 200, xScale= 0.5, yScale = 0.5, transition=easing.outBounce})
        transition.scaleTo(candyConfirmation[i], {time=500, delay= 300, xScale= 0.4, yScale = 0.4, transition=easing.outBounce})
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
        if(currentCandy.contentBounds.xMin - 30 < candiesGroup[rndNumber].contentBounds.xMin and
           currentCandy.contentBounds.xMax + 30 > candiesGroup[rndNumber].contentBounds.xMax and
           currentCandy.contentBounds.yMin - 30 < candiesGroup[rndNumber].contentBounds.yMin and
           currentCandy.contentBounds.yMax + 30 > candiesGroup[rndNumber].contentBounds.yMax and
           currentCandy.value == questionCandy) then
            confirmation(sequence)
            secondScene:toFront()
            
            candiesGroup[rndNumber].alpha = 0
            selectedCandyButton = currentCandy.position
            director.to(scenePath, currentCandy, { time=200, x= candyNumberT[rndNumber].x, y = candyNumberT[rndNumber].y, transition=easing.linear })
            currentCandy:removeEventListener( "touch", touchCandyButton )
        else
            director.to(scenePath, currentCandy, { time=200, x= currentCandy.pX , y = currentCandy.pY, transition=easing.linear })
            director.to(scenePath, currentCandy, { time=300, delay = 200,  x= currentCandy.pX + math.random(-30, 30), y = currentCandy.pY - 30, transition=easing.linear })            
            director.to(scenePath, currentCandy, { time=200, delay = 300,  x= currentCandy.pX + math.random(-30, 30),  transition=easing.linear })  
            director.to(scenePath, currentCandy, { time=500, delay = 300,  x= currentCandy.pX + math.random(-30, 30), y = currentCandy.pY + 150, transition=easing.inBounce })            


        end 
    end
    return true  
end

local function barrels()
    for i=1, 2 do
        candy = math.random(1,4)
        candyButtonsGroup[i] = display.newImage(assetPath..CANDY_BUTTONS[candy].path)
        candyButtonsGroup[i].barrel = BARRELS[candy].path
        candyButtonsGroup[i].value = math.random(questionCandy - sequence ,questionCandy + sequence) 
        while sequence == candyButtonsGroup[i].value do
            candyButtonsGroup[i].value = math.random(questionCandy - sequence,questionCandy + sequence) 
        end
    end
    
    candyButtonsGroup[3] = display.newImage(assetPath..CANDY_BUTTONS[rndNumber].path)
    candyButtonsGroup[3].barrel = BARRELS[rndNumber].path
    candyButtonsGroup[3].value = questionCandy
    candyNumberT[rndNumber].path = (CANDY_BUTTONS[rndNumber].path)
    candyNumberT[rndNumber].value = questionCandy
    local dis= 40
    candyButtonsGroup = shuffle(candyButtonsGroup)
    for i=1, 3 do
        local barrel = display.newImage(assetPath..candyButtonsGroup[i].barrel)
        barrel.x = barrel.height + dis
        barrel.y = display.contentHeight - barrel.height * 0.5
        
        
        local candyButtonOption = display.newGroup()
        local number =  display.newText(candyButtonsGroup[i].value, display.contentCenterX , display.contentCenterY , native.systemFont, 55)
    
        number.y = 3
        number.x = 0
        number:setTextColor(0,0,0)
        
        candyButtonOption: insert(candyButtonsGroup[i])
        candyButtonOption: insert(number)
        candyButtonOption.anchorChildren = true
        candyButtonOption.position = i
        candyButtonOption: addEventListener( "touch", touchCandyButton )
        candyButtonOption.x = barrel.x
        candyButtonOption.y = barrel.y - barrel.height * 0.5 - 20
        candyButtonOption.value = candyButtonsGroup[i].value
        candyButtonOption.pX = candyButtonOption.x
        candyButtonOption.pY = candyButtonOption.y
        dis = dis + barrel.height * 1.5
        candyButtonT[i] = candyButtonOption
    end
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
    
    local background = display.newImageRect(assetPath.."fondo.png", SCREEN_WIDTH + 1, SCREEN_HEIGHT)
    background.x = display.contentCenterX
    background.y = display.contentCenterY
    backgroundLayer:insert(background)
end

function game:show(event)
	local phase = event.phase

	if phase == "will" then
        scenario()
        initialize()
		createCandy()
        barrels()
        
	elseif phase == "did" then
	
	end
end

function game:hide( event )
	local phase = event.phase

	if phase == "will" then
		
	elseif phase == "did" then
		
	end
end

----------------------------------------------- Execution
game:addEventListener( "create", game )
game:addEventListener( "show" )
game:addEventListener( "hide" )

return game





