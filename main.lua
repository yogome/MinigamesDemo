----------------------------------------------- Main
local launchArgs = ... 
local localization = require("libs.helpers.localization")
local director = require("libs.helpers.director")
----------------------------------------------- Constants
----------------------------------------------- Local functions
local function start()
	display.setStatusBar( display.HiddenStatusBar )
	director.gotoScene("scenes.menu")
end
----------------------------------------------- Execution
start() 
