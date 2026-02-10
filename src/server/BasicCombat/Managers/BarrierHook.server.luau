local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local CombatUtils = require(ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))

local function onCharacterAdded(character)
	CombatUtils.AttachBarrierDamageHook(character)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(onCharacterAdded)
	print("Barrier hooked!")
end)
