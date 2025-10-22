-- ServerScriptService.BasicCOmbat.StandRegistry

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Path to stand modules
local StandModules = ReplicatedStorage:WaitForChild("BasicCombat"):WaitForChild("StandModules")

local registry = {
	["Hierophant Grand"] = StandModules:WaitForChild("HierophantGrandModule"),
	["Star Purple"] = StandModules:WaitForChild("StarPurpleModule"),
	["King Carmine"] = StandModules:WaitForChild("KingCarmineModule"),
}

local StandRegistry = {}

-- Get the stand module based on a stand tag string
function StandRegistry.GetStandModuleByTag(tag: string)
	return registry[tag]
end

-- Get the stand module given a stand model
function StandRegistry.GetStandModuleFromModel(standModel: Model)
	if not standModel then
		return nil
	end

	local tagValue = standModel:FindFirstChild("StandTag")
	if not tagValue or not tagValue:IsA("StringValue") then
		warn("⚠️ No valid StandTag found in stand model: " .. standModel.Name)
		return nil
	end

	local tag = tagValue.Value
	return registry[tag]
end

return StandRegistry
