-- RaycastIgnoreModule.lua
-- Centralized ignore list for all raycasts in your game.

local RaycastIgnoreModule = {}

-- Holds all objects excluded from raycasts
local ignoreList = {}

-- Internal helper to clean up destroyed instances
local function connectAutoCleanup(instance)
	-- Roblox provides a Destroying event (works for all Instances)
	instance.Destroying:Connect(function()
		for i = #ignoreList, 1, -1 do
			if ignoreList[i] == instance then
				table.remove(ignoreList, i)
			end
		end
	end)
end

-- Returns the current ignore list (read-only usage)
function RaycastIgnoreModule.GetIgnoreList()
	return ignoreList
end

-- Returns a new RaycastParams object based on the current ignore list
function RaycastIgnoreModule.GetParams()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignoreList
	return params
end

-- Adds one or more instances to the ignore list and hooks up cleanup
function RaycastIgnoreModule.AddToIgnore(instances)
	if typeof(instances) == "Instance" then
		table.insert(ignoreList, instances)
		connectAutoCleanup(instances)
	elseif typeof(instances) == "table" then
		for _, inst in ipairs(instances) do
			if typeof(inst) == "Instance" then
				table.insert(ignoreList, inst)
				connectAutoCleanup(inst)
			end
		end
	end
end

-- Optional manual removal (you rarely need this now)
function RaycastIgnoreModule.RemoveFromIgnore(instance)
	for i = #ignoreList, 1, -1 do
		if ignoreList[i] == instance then
			table.remove(ignoreList, i)
		end
	end
end

return RaycastIgnoreModule
