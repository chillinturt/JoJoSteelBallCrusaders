-- RaycastIgnoreModule.lua
-- Centralized ignore list for all raycasts in your game.

local RaycastIgnoreModule = {}

local ignoreList = {}

-- Internal helper to clean up destroyed instances
local function connectAutoCleanup(instance)
	instance.Destroying:Connect(function()
		for i = #ignoreList, 1, -1 do
			if ignoreList[i] == instance then
				table.remove(ignoreList, i)
			end
		end
	end)
end

-- Returns a SAFE COPY of the ignore list
function RaycastIgnoreModule.GetIgnoreList()
	local copy = table.clone(ignoreList)
	return copy
end

-- Returns raycast params with optional extra exclusions
function RaycastIgnoreModule.GetParams(extraIgnore)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	local finalIgnore = table.clone(ignoreList)

	if extraIgnore then
		if typeof(extraIgnore) == "Instance" then
			table.insert(finalIgnore, extraIgnore)
		elseif typeof(extraIgnore) == "table" then
			for _, inst in ipairs(extraIgnore) do
				if typeof(inst) == "Instance" then
					table.insert(finalIgnore, inst)
				end
			end
		end
	end

	params.FilterDescendantsInstances = finalIgnore
	params.IgnoreWater = false

	return params
end

-- Adds one or more instances to ignore list
function RaycastIgnoreModule.AddToIgnore(instances)
	if typeof(instances) == "Instance" then
		if not table.find(ignoreList, instances) then
			table.insert(ignoreList, instances)
			connectAutoCleanup(instances)
		end
	elseif typeof(instances) == "table" then
		for _, inst in ipairs(instances) do
			if typeof(inst) == "Instance" and not table.find(ignoreList, inst) then
				table.insert(ignoreList, inst)
				connectAutoCleanup(inst)
			end
		end
	end
end

-- Manual removal
function RaycastIgnoreModule.RemoveFromIgnore(instance)
	for i = #ignoreList, 1, -1 do
		if ignoreList[i] == instance then
			table.remove(ignoreList, i)
		end
	end
end

return RaycastIgnoreModule
