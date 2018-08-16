------------------------------------------------ Test Menu
local scenePath = ...
local localization = require( "libs.helpers.localization" )
local director = require( "libs.helpers.director" )
local widget = require( "widget" )

local scene = director.newScene("testMenu")
----------------------------------------------- Variables
local backButton
local buttonList
local menuView
local language
local languageIndex
local addedButtons
----------------------------------------------- Constants
local BUTTON_SHOW_WIDTH = 100
local BUTTON_SHOW_HEIGHT = 35
local BUTTON_SHOW_ALPHA = 0.15
local BUTTON_SHOW_SIZE_TEXT = 25
local BUTTON_WIDTH = 400 
local BUTTON_HEIGHT = 90
local BUTTON_MARGIN = 5
local SIZE_TEXT = 45
local SIZE_FONT_MIN = 16
local COLOR_DEFAULT = {0.3,0.3,0.8}

local LANGUAGES = {"en","es","pt"}
----------------------------------------------- Functions
local function goLuis()
	director.gotoScene("scenes.manager", {params = {minigames = {"gamefiles.scienceTestLuis.game"}}})
end

local function goJully()
	director.gotoScene("scenes.manager", {params = {minigames = {"gamefiles.scienceTestJully.game"}}})
end

local function goArturo()
	director.gotoScene("scenes.manager", {params = {minigames = {"gamefiles.progTestArturo.game"}}})
end

local function toggleLanguage(event)
	languageIndex = languageIndex + 1
	languageIndex = languageIndex <= #LANGUAGES and languageIndex or 1
	language = LANGUAGES[languageIndex]
	localization.setLanguage(language)
	event.target.text.text = "Lang:"..language
end

local function createBackButton()
	local backButton = display.newGroup()
	backButton.anchorChildren = true
	backButton.alpha = BUTTON_SHOW_ALPHA
	
	local buttonBG = display.newRect(0,0,BUTTON_SHOW_WIDTH, BUTTON_SHOW_HEIGHT)
	buttonBG:setFillColor(0.5)
	backButton:insert(buttonBG)
	
	local buttonText = display.newText("BACK", 0, 0, native.systemFont, BUTTON_SHOW_SIZE_TEXT)
	backButton:insert(buttonText)
		
	buttonBG:addEventListener("tap", function()
		director.gotoScene( "testMenu", { effect = "fade", time = 400} )
		return true
	end)
	
	return backButton
end

local function createMenuView()
	local viewOptions = {
		x = display.contentCenterX,
		y = display.contentCenterY,
		width = display.viewableContentWidth,
		height = display.viewableContentHeight,
		scrollWidth = 100,
		scrollHeight = 100,
		hideBackground = true,
	}
	
	local targetX, targetY = 0, 0
	
	local menuView = widget.newScrollView(viewOptions)
	menuView:scrollToPosition({x = -800, y = -800, time = 0, onComplete = function()
		menuView:scrollToPosition({x = targetX, y = targetY, time = 600})
	end})
	return menuView
end

----------------------------------------------- Class functions
function scene.addButton(textString, listener, rectColor, column, strokeColor)
	if textString and listener then
		rectColor = rectColor or {0.1,0.1,0.1}
		column = column or 1
		strokeColor = strokeColor or {0,0,0}
		
		local button = display.newGroup()
		button.listener = listener
		button.defaultColor = rectColor
		menuView:insert(button)
		
		local background = display.newRect(0,0,BUTTON_WIDTH,BUTTON_HEIGHT)
		background.strokeWidth = BUTTON_MARGIN
		background.stroke = strokeColor
		button:insert(background)
		background:setFillColor(unpack(rectColor))
		
		local textOptions = {
			x = 0,
			y = 0,
			fontSize = SIZE_TEXT,
			font = native.systemFont,
			align = "center",
			text = textString,
		}
		
		local text = nil
		local currentSize = SIZE_TEXT
		repeat
			textOptions.fontSize = currentSize
			display.remove(text)
			text = display.newText(textOptions)
			button:insert(text)
			if text.width < BUTTON_WIDTH then
				textOptions.width = text.width
				display.remove(text)
				text = display.newText(textOptions)
				button:insert(text)
			else
				currentSize = currentSize - 1
			end
		until currentSize <= SIZE_FONT_MIN or text.width < BUTTON_WIDTH
		
		button.text = text
		button.background = background
		
		button:addEventListener("tap", function()
			transition.cancel(background)
			button.listener({target = button})
			return true
		end)
		buttonList[column] = buttonList[column] or {}
		local row = #buttonList[column]
		button.x = display.screenOriginX + (BUTTON_WIDTH + BUTTON_MARGIN) * 0.5 + ((BUTTON_WIDTH + BUTTON_MARGIN) * (column - 1))
		button.y = display.screenOriginY + (BUTTON_HEIGHT + BUTTON_MARGIN) * 0.5 + ((BUTTON_HEIGHT + BUTTON_MARGIN) * row)
		
		buttonList[column][#buttonList[column] + 1] = button
		
		return button
	end
end

function scene:create(event)
	buttonList = {}

	backButton = createBackButton()
	backButton.anchorX = 0
	backButton.anchorY = 0
	backButton.x = display.screenOriginX
	backButton.y = display.screenOriginY
	display.getCurrentStage():insert(backButton)
	backButton.isVisible = false
	
	scene.backButton = backButton
	languageIndex = 1
	language = LANGUAGES[languageIndex]
	addedButtons = false
	
	menuView = createMenuView()
	self.view:insert(menuView)
	
	self.addButton("Go Luis", goLuis, COLOR_DEFAULT, 1)
	self.addButton("Go Jully", goJully, COLOR_DEFAULT, 1)
	self.addButton("Go Arturo", goArturo, COLOR_DEFAULT, 1)

	self.addButton("Lang:"..language, toggleLanguage, COLOR_DEFAULT, 1)
end

function scene:destroy()
	addedButtons = false
end

function scene:show( event )
	if "will" == event.phase then
		display.setDefault("background",0,0,0)
	elseif "did" == event.phase then
		backButton.isVisible = true
	end
end

function scene:hide( event )
	if "did" == event.phase then

	end
end

scene:addEventListener( "create" )
scene:addEventListener( "destroy" )
scene:addEventListener( "hide" )
scene:addEventListener( "show" )

return scene
