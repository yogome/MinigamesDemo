----------------------------------------------- Main
local modulePath = ... 
local stringList = require("data.languages")

local localization = {}
----------------------------------------------- Variables
local language
local initialized
----------------------------------------------- Constants 

----------------------------------------------- Local functions
local function initialize()
	if not initialized then
		initialized = true
		language = "en"
	end
end
----------------------------------------------- Module functions
function localization.setLanguage(newLanguage)
	language = newLanguage
end

function localization.getLanguage()
	return language
end

function localization.getString(stringID)
	local languageList = stringList[language]
	if not languageList[stringID] then print(tostring(stringID).." is not on the dictionary") end
	return languageList[stringID] or "MISSING STRING"
end
----------------------------------------------- Execution
initialize()

return localization
