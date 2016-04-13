--require "CiderDebugger";-----------------------------------------------------------------------------------------
--Scene

local composer = require("composer")
local game = composer.newScene()

--Variables 
local selectedCandyButton, boxOptions, candiesGroup, candyNumberT, candyButtonT,  questionCandy, candyNumber, candyButtons, tubeEx, conveyor, candyBox, box, rndNumber, sequence, candy, converyotLineG, lineDistance, barrelsGroup, candyButtonsGroup


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
local SCREEN_WIDTH = display.actualContentWidth
local SCREEN_HEIGHT = display.actualContentHeight
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
    local ventilador = display.newImage("ventilador.png")
    ventilador.x = display.contentCenterX - 120
    ventilador.y = display.contentCenterY - 130
    ventilador:scale(0.5, 0.5)
    transition.to( ventilador, { rotation= 360, time=1000, transition=easing.lineal, iterations= -1 } )
    
    local ventilador2 = display.newImage("ventilador.png")
    ventilador2.x = display.contentCenterX + 100
    ventilador2.y = display.contentCenterY - 130
    ventilador2:scale(0.6, 0.6)
    transition.to( ventilador2, { rotation= 360, time=1400, transition=easing.lineal, iterations= -1 } )
    local caja = display.newImage("cajavacia.png")
    caja.x = display.contentCenterX + 196
    caja.y = display.contentCenterY + 37
    caja: scale(0.47,0.47)
    
    candyBox = display.newImage("candyBox.png")
    candyBox.x = display.contentCenterX + 196
    candyBox.y = display.contentCenterY + 30
    candyBox: scale(0.47,0.47)
    candyBox.alpha= 0   
    
    local boxOptions =
    {
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
    local boxSprite = graphics.newImageSheet( "box.png", boxOptions )
    box = display.newSprite( boxSprite, sequencesBox )
    box.x = display.contentCenterX + 196
    box.y = display.contentCenterY + 13
    box: scale(0.47,0.47) 
    box.alpha = 0
    
    conveyor = display.newImage("conveyor.png")
    conveyor.x = display.contentCenterX - 30
    conveyor.y = display.contentCenterY + 80
    conveyor: scale(0.47,0.47)
    
end
local function moveLines()
        
    for i=0, 40 do
        transition.to(converyotLineG[i],{time = 500, tag = "BELT", x = converyotLineG[i].x + 10.1, transition = easing.linear , iterations= -1 })
    end
end

local function tube()
    tubeEx:play()
end
local function boxCandy()
    box:play()
end
local secondScene = display.newGroup()

local candyButtonQuestion = display.newGroup()
local function packCandies()
    transition.to(box,{time= 300, alpha = 1})
    converyotLineG[40].alpha=0
    moveLines()
    timer.performWithDelay( 3000, boxCandy )
    
    local distance = 430
    candyButtonQuestion:insert(candiesGroup[rndNumber])
    candyButtonQuestion:insert(candyNumberT[rndNumber])
    for i=5, 1, -1 do
    transition.to(candyNumberT[i], {time= 500 + (i * 500), x = distance, transition=easing.linear})
    transition.to(candyNumberT[i], {time= 50 + (i * 50), delay = 500 + (i * 500), y = 160, alpha = 0, transition=easing.linear})
    if( i == rndNumber) then
        transition.to(candyButtonT[selectedCandyButton], {time= 500 + (i * 500), x = distance, transition=easing.linear})
        transition.to(candyButtonT[selectedCandyButton], {time= 50 + (i * 50), delay = 500 + (i * 500), y = 160, alpha = 0, transition=easing.linear})
    
    end
    end  
    
end
local function createCandy()

    for i=0, 40 do
        converyotLineG[i] = display.newImage("linea.png")
        converyotLineG[i].x = lineDistance
        converyotLineG[i].y = 161
        converyotLineG[i]: scale(0.26,0.26)
        lineDistance = lineDistance + 10.1
    end     
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
    local tubeSprite = graphics.newImageSheet( "Tubo.png", tubeOptions )
    
    tubeEx = display.newSprite( tubeSprite, sequencesTube )
    tubeEx:toFront()
    tubeEx.x = display.contentCenterX - 180 
    tubeEx.y = display.contentCenterY - 130
    tubeEx:scale(0.5, 0.5)
    moveLines()
local sequenceCounter = sequence * 6
local distance = 340
    for i=1, 5 do
        candy = math.random(1,4)
        candiesGroup[i] = display.newImage(CANDIES[candy].path)
        candiesGroup[i].path = candy
        candiesGroup[i].x = display.contentCenterX - 177
        candiesGroup[i].y = display.contentCenterY - 210
        candiesGroup[i].value = sequenceCounter 
        candiesGroup[i]:scale(0.4, 0.4)
        sequenceCounter = sequenceCounter - sequence
        
        local number =  display.newText(candiesGroup[i].value, display.contentCenterX - 177, display.contentCenterY - 210, native.systemFont, 20)
        number:setTextColor(0,0,0)
        
        candyNumber = display.newGroup()
        questionCandy =candiesGroup[i].value
        candyNumber: insert(candiesGroup[i])
        candyNumber: insert(number)
        candyNumber.anchorChildren = true
        candyNumber.x = display.contentCenterX - 177
        candyNumber.y = display.contentCenterY - 210 --210
        
        candyNumberT[i] = candyNumber
        candyNumberT[i].path = (CANDY_BUTTONS[candy].path)
        candyNumberT[i].value = candiesGroup[i].value
        
    end
        
        questionCandy=candiesGroup[rndNumber].value
        print(questionCandy)
        candiesGroup[rndNumber] = display.newImage(CANDIES[5].path)
        
        candiesGroup[rndNumber]:scale(0.4, 0.4)
        candyNumber = display.newGroup()
        candyNumber: insert(candiesGroup[rndNumber])
        candyNumber.x = display.contentCenterX - 177
        candyNumber.y = display.contentCenterY - 210
        candyNumber.anchorChildren = true
        candyNumberT[rndNumber] = candyNumber
            
    for i=1, 5 do
        
        transition.to(candyNumberT[i], {time=1400, delay= i * 1000, y = 135, transition=easing.outBounce})
        transition.to(candyNumberT[i], {time= 4500 - (i * 1000), delay= (i + 1) * 1000, x = distance, transition=easing.linear, onComplete = function() 
            if i == 5 then transition.cancel("BELT") end
        end})

        timer.performWithDelay( 1020 * i, tube )
        distance = distance - 70
        candiesGroup[rndNumber].pX = candiesGroup[rndNumber].x
        candiesGroup[rndNumber].pY = candiesGroup[rndNumber].y
        
    end
end

local function touchBox(event)
    local currentBox= event.target
    if ( event.phase == "began" ) then
        display.getCurrentStage():setFocus( currentBox )
        print(questionCandy)
    elseif ( event.phase == "moved" ) then
    	
    elseif ( event.phase == "ended" ) then
        display.getCurrentStage():setFocus(nil)
        if(currentBox.value == sequence) then
            print("win!")
            transition.to(secondScene, {time=500, alpha= 0})

            packCandies()
        else
            print("looser!")
            local red = { 1, 0.2, 0.2 }
            local green = { 0.72, 0.9, 0.16, 0.78 }
            currentBox:setFillColor(  1, 0.2, 0.2)

            for i = 1, 3 do
                if(boxOptions[i].value == sequence) then
                boxOptions[i]:setFillColor( 0.72, 0.9, 0.16 )
                transition.scaleTo( boxOptions[i],{time=500, xScale= 0.7, yScale = 0.7, transition = easing.inOutBack })
                
                end
            end

        end
       
    end
    return true  
end

local function confirmation(answer)
    local container
    container = display.newRect( 0, 0, display.viewableContentWidth  ,display.viewableContentWidth )
    container.x = display.contentCenterX 
    container.y = display.contentCenterY -20
    container.alpha = 0
    container.fill= {0}
    transition.to(container,{time = 100, alpha = 0.5})
    secondScene: insert(container)
    boxOptions = {}
    local distance= 45
    for i = 1, 3 do
        boxOptions[i]= display.newImage("option.png")
        boxOptions[i].value = math.random(answer + sequence)
        while boxOptions[i].value == answer do
            boxOptions[i].value = math.random(answer + sequence)
            for q = 1, 3 do
                if boxOptions[i].value == boxOptions[q].value then
                    boxOptions[i].value = math.random(answer + sequence)
                end
            end
        end
        secondScene: insert(boxOptions[i])
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
 
        candyConfirmation[i] = display.newImage(candyNumberT[i].path)
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

    if ( event.phase == "began" ) then
        display.getCurrentStage():setFocus( currentCandy )
    elseif ( event.phase == "moved" ) then
    	currentCandy.x = event.x
        currentCandy.y = event.y

    elseif ( event.phase == "ended" ) then
       
        display.getCurrentStage():setFocus(nil)
        if(currentCandy.contentBounds.xMin - 30 < candiesGroup[rndNumber].contentBounds.xMin and
           currentCandy.contentBounds.xMax + 30 > candiesGroup[rndNumber].contentBounds.xMax and
           currentCandy.contentBounds.yMin - 30 < candiesGroup[rndNumber].contentBounds.yMin and
           currentCandy.contentBounds.yMax + 30 > candiesGroup[rndNumber].contentBounds.yMax and
           currentCandy.value == questionCandy) then
            print("match")
            confirmation(sequence)
            secondScene:toFront()
            
            candiesGroup[rndNumber].alpha = 0
            selectedCandyButton = currentCandy.position
            transition.to( currentCandy, { time=200, x= candyNumberT[rndNumber].x, y = candyNumberT[rndNumber].y, transition=easing.linear })
            currentCandy:removeEventListener( "touch", touchCandyButton )
        else
            print("no match")
            transition.to( currentCandy, { time=200, x= currentCandy.pX, y = currentCandy.pY, transition=easing.linear })
        end 
    end
    return true  
end
local function barrels()
    for i=1, 2 do
        candy = math.random(1,4)
        candyButtonsGroup[i] = display.newImage(CANDY_BUTTONS[candy].path)
        candyButtonsGroup[i].barrel = BARRELS[candy].path
        candyButtonsGroup[i].value = math.random(questionCandy - sequence ,questionCandy + sequence) 
        while sequence == candyButtonsGroup[i].value do
            candyButtonsGroup[i].value = math.random(questionCandy - sequence,questionCandy + sequence) 
            for q = 1, 3 do
                if candyButtonsGroup[i].value == candyButtonsGroup[q].value then
                    candyButtonsGroup[i].value = math.random(questionCandy - sequence,questionCandy + sequence)
                end
            end
        end
    end
    
    candyButtonsGroup[3] = display.newImage(CANDY_BUTTONS[rndNumber].path)
    candyButtonsGroup[3].barrel = BARRELS[rndNumber].path
    candyButtonsGroup[3].value = questionCandy
    candyNumberT[rndNumber].path = (CANDY_BUTTONS[rndNumber].path)
    candyNumberT[rndNumber].value = questionCandy
    local dis= 40
    candyButtonsGroup = shuffle(candyButtonsGroup)
    for i=1, 3 do
        local barrel = display.newImage(candyButtonsGroup[i].barrel)
        barrel.x = 45 + dis
        barrel.y = display.contentCenterY + 130
        barrel: scale(0.5, 0.5)
        
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
        candyButtonOption.x = 45 + dis
        candyButtonOption.y = display.contentCenterY + 75
        candyButtonOption.value = candyButtonsGroup[i].value
        candyButtonOption.pX = candyButtonOption.x
        candyButtonOption.pY = candyButtonOption.y
        candyButtonOption: scale(0.4, 0.4)
        dis = dis + 125
        candyButtonT[i] = candyButtonOption
    end
end

----------------------------------------------- Module functions
function game:create(event)
    local sceneView = self.view
    
    backgroundLayer = display.newGroup() 
    sceneView:insert(backgroundLayer)
    
    background = display.newImageRect("fondo.png", SCREEN_WIDTH + 1, SCREEN_HEIGHT)
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





