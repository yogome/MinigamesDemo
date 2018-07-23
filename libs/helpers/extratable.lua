-------------------------------------------- Extra table functions
local extratable = {}
-------------------------------------------- Caches
local tableSort = table.sort
local mathRandom = math.random
-------------------------------------------- Functions

-------------------------------------------- Module functions
function extratable.deepcopy(originalTable)
	local typeOriginal = type(originalTable)
	local copyTable
	if typeOriginal == "table" and not (originalTable._proxy or originalTable._class) then
		copyTable = {}
		for key, value in next, originalTable, nil do
			copyTable[extratable.deepcopy(key)] = extratable.deepcopy(value)
		end
		setmetatable(copyTable, extratable.deepcopy(getmetatable(originalTable)))
	else
		copyTable = originalTable
	end
	return copyTable
end

function extratable.shuffle(tab)
	local numberElements, order, resultTable = #tab, {}, {}
	
	for index = 1,numberElements do
		order[index] = { rnd = mathRandom(), idx = index }
	end
	
	tableSort(order, function(a,b)
		return a.rnd < b.rnd 
	end)
	
	for index = 1,numberElements do
		resultTable[index] = tab[order[index].idx]
	end
	return resultTable
end

function extratable.getRandom(t1, count)
	local function permute(tab, n, count)
		n = n or #tab
		for i = 1, count or n do
			local j = mathRandom(i, n)
			tab[i], tab[j] = tab[j], tab[i]
		end
		return tab
	end

	local meta = {
		__index = function (self, key)
			return key
		end
	}
	local function getInfiniteTable() return setmetatable({}, meta) end

	local randomIndices = {unpack(permute(getInfiniteTable(), #t1, count), 1, count)}
	
	local randomNewTable = {}
	for index = 1, #randomIndices do
		randomNewTable[index] = extratable.deepcopy(t1[randomIndices[index]])
	end
	return randomNewTable
end

return extratable