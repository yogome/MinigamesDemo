----------------------------------------------- Director - Scene management mock
local composer = require("composer")

----------------------------------------------- Caches
local oldNewScene = composer.newScene
local tableRemove = table.remove
----------------------------------------------- Local functions
local function cancelSceneTimers(scene)
	if scene and scene._timers and "table" == type(scene._timers) then
		for index = #scene._timers, 1, -1 do
			if scene._timers[index] then
				timer.cancel(scene._timers[index])
			end
		end
		scene._timers = {}
	end
end

local function cancelSceneTransitions(scene)
	if scene and scene._transitions and "table" == type(scene._transitions) then
		for index = #scene._transitions, 1, -1 do
			if scene._transitions[index] then
				transition.cancel(scene._transitions[index])
			end
		end
		scene._transitions = {}
	end
end

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
----------------------------------------------- Module functions
function composer.newScene(...)
	local newScene = oldNewScene(...)
	
	newScene._timers = {}
	newScene._transitions = {}
	newScene:addEventListener("hide", function(event)
		if event.phase == "did" then
			cancelSceneTimers(newScene)
			cancelSceneTransitions(newScene)
		end
	end)
	
	return newScene
end

function composer.performWithDelay(sceneName, delay, listener, iterations)
	local scene = composer.loadedScenes[sceneName]
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
	local scene = composer.loadedScenes[sceneName]
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