pcall(function() require("mobdebug").start(debugIP) end) -- ZeroBrane debugger
pcall(function() require("mobdebug").coro() end) -- Enable coroutine debug
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
