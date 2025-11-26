-- Handles RemoteFunction invocation and delegates to AbilityHandler

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local AbilityFunction = ReplicatedStorage.Shared.BasicCombat:WaitForChild("StandAbilityFunction")
local AbilityHandler = require(ServerScriptService.BasicCombat.StandModules.Handlers:WaitForChild("AbilityHandler"))

-- Client calls: AbilityFunction:InvokeServer(abilityId, state)
AbilityFunction.OnServerInvoke = function(player, abilityId, state)
	AbilityHandler.ExecuteAbility(player, abilityId, state)
	return true -- optional: success feedback
end
