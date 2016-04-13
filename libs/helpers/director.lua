local composer = require("composer")

local oldNewScene = composer.newScene

local tableRemove = table.remove

local function removeItem(tab, item)
	if tab and "table" == type(tab) then
		for index = #tab, 1, -1 do
			if item == tab[index] then
				tableRemove(tab, index)
				return true
			end
		end
	end
	return false
end

local function didHideSceneHook(scene, event)
	if event.phase == "did" then
		
	end
end

function composer.newScene(...)
	local newScene = oldNewScene(...)
	
	newScene._timers = {}
	newScene._transitions = {}
	newScene:addEventListener("hide", didHideSceneHook)
	
	return newScene
end

function composer.performWithDelay(sceneName, delay, listener, iterations)
	local scene = director.sceneDictionary[sceneName]
	if scene and scene._timers then
		local timerHandle = timer.performWithDelay(delay, function(event)
			listener(event)
			removeItem(scene._timers, event.source)
		end, iterations)
		scene._timers[#scene._timers + 1] = timerHandle
		return timerHandle
	end
end

function composer.to(sceneName, target, params)
	local scene = director.sceneDictionary[sceneName]
	if scene and scene._transitions and params then
		local onComplete = params.onComplete
		
		local transitionHandle
		params.onComplete = function(event)
			removeItem(scene._transitions, transitionHandle)
			if onComplete and "function" == type(onComplete) then
				onComplete(event)
			end
		end
		
		transitionHandle = transition.to(target, params)
		scene._transitions[#scene._transitions + 1] = transitionHandle
		return transitionHandle
	else
		error("Could not find scene or missing params to director.to", 3)
	end
end

return composer