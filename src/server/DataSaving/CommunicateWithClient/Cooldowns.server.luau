local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HeroManager = require(ServerScriptService.DataSaving.HeroManager)

local GetHeroFunction = Instance.new("RemoteFunction")
GetHeroFunction.Name = "GetHeroFunction"
GetHeroFunction.Parent = ReplicatedStorage.UIs:WaitForChild("RemoteEvents")

local GetSpecFunction = Instance.new("RemoteFunction")
GetSpecFunction.Name = "GetSpecFunction"
GetSpecFunction.Parent = ReplicatedStorage.UIs:WaitForChild("RemoteEvents")

local RequestAbilityUnlocks = Instance.new("RemoteEvent")
RequestAbilityUnlocks.Name = "RequestAbilityUnlocks"
RequestAbilityUnlocks.Parent = ReplicatedStorage.UIs:WaitForChild("RemoteEvents")

local AbilityUnlocksEvent = ReplicatedStorage.UIs:WaitForChild("RemoteEvents"):WaitForChild("AbilityUnlocksEvent")

RequestAbilityUnlocks.OnServerEvent:Connect(function(player)
	local unlockedTable = HeroManager.GetField(player, "UnlockedAbilities")
	AbilityUnlocksEvent:FireClient(player, unlockedTable)
end)

GetHeroFunction.OnServerInvoke = function(player)
	local heroValue = HeroManager.GetField(player, "Hero")
	if not heroValue then
		return nil
	end

	return heroValue -- return hero string
end

GetSpecFunction.OnServerInvoke = function(player)
	local specValue = HeroManager.GetField(player, "Specialty")
	if not specValue then
		return nil
	end

	return specValue -- return hero string
end
