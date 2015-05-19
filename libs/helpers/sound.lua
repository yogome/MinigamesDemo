---------------------------------------------- Sound
local sounds = require("data.sounds")
 
local sound = {}
--------------------------------------------- Variables
local enabled
local soundTable
local currentChannel
local initialized
--------------------------------------------- Constants
--------------------------------------------- Functions
local function playSound(sound)
	if audio.isChannelActive(currentChannel) then
		audio.stop(currentChannel)
	end
	audio.play(sound, { channel = currentChannel})
end

local function initialize()
	if not initialized then
		initialized = true
		currentChannel = 1
		
		soundTable = soundTable or {}
	
		for key, value in pairs(sounds) do
			soundTable[key] = audio.loadSound(value)
		end
	end
end

--------------------------------------------- Module functions
function sound.isEnabled()
	return enabled
end

function sound.setEnabled(value)
	enabled = value and value
end

function sound.play(soundID)
	if enabled then	
		if soundTable[soundID] then
			playSound(soundTable[soundID])
		else
			print("[Sound] "..tostring(soundID).." is nil.")
		end
	end
end

initialize()

return sound