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

local AbilityHandler = require(ServerScriptService.BasicCombat.StandModules.Handlers:WaitForChild("AbilityHandler"))

-- Client calls: AbilityFunction:InvokeServer(abilityId, state)
AbilityFunction.OnServerInvoke = function(player, abilityId, state)
	AbilityHandler.ExecuteAbility(player, abilityId, state)
	return true -- optional: success feedback
end
