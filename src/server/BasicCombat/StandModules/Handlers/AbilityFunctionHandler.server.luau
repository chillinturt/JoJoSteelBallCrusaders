-- Handles RemoteFunction invocation and delegates to AbilityHandler

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local AbilityFunction = Instance.new("RemoteFunction")
AbilityFunction.Name = "StandAbilityFunction"
AbilityFunction.Parent = ReplicatedStorage.Shared:WaitForChild("BasicCombat")

local StandAbilityEvent = Instance.new("RemoteEvent")
StandAbilityEvent.Name = "StandAbilityEvent"
StandAbilityEvent.Parent = ReplicatedStorage.Shared:WaitForChild("BasicCombat")

local AbilityTypes = Instance.new("RemoteEvent")
AbilityTypes.Name = "StandAbilityTypes"
AbilityTypes.Parent = ReplicatedStorage.Shared:WaitForChild("BasicCombat")

-- Pulled by the client on join/respawn so it doesn't have to rely solely on a
-- server-pushed StandAbilityTypes event racing its own LocalScript startup.
local GetAbilityTypesFunction = Instance.new("RemoteFunction")
GetAbilityTypesFunction.Name = "GetAbilityTypesFunction"
GetAbilityTypesFunction.Parent = ReplicatedStorage.Shared:WaitForChild("BasicCombat")

local UnlockMessageEvent = ReplicatedStorage.UIs.RemoteEvents:FindFirstChild("UnlockMessageEvent")
if not UnlockMessageEvent then
	UnlockMessageEvent = Instance.new("RemoteEvent")
	UnlockMessageEvent.Name = "UnlockMessageEvent"
	UnlockMessageEvent.Parent = ReplicatedStorage:WaitForChild("UIs"):WaitForChild("RemoteEvents")
end

local AbilityHandler = require(ServerScriptService.BasicCombat.StandModules.Handlers:WaitForChild("AbilityHandler"))
local StandUtils = require(ServerScriptService.BasicCombat:WaitForChild("StandUtils"))

-- Client calls: AbilityFunction:InvokeServer(abilityId, state)
AbilityFunction.OnServerInvoke = function(player, abilityId, state)
	local character = player.Character
	local standModel = character and StandUtils.getStandModel(character)

	-- The unlock/level gate only applies to the on-stand ability set. The
	-- off-stand (bare-handed) kit is always available, so skip it there.
	if standModel then
		if not AbilityHandler.IsAbilityUnlocked(player, abilityId) then
			return AbilityHandler.TryUnlockAbility(player, abilityId)
		end
	end

	AbilityHandler.ExecuteAbility(player, abilityId, state)
	return true, "Used"
end

GetAbilityTypesFunction.OnServerInvoke = function(player)
	return AbilityHandler.GetCurrentAbilityTypes(player)
end
