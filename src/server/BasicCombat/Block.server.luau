local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BlockModule = require(game.ServerScriptService.BasicCombat:WaitForChild("BlockModule"))
local CanBlockFunction = Instance.new("RemoteFunction")
CanBlockFunction.Name = "CanBlockFunction"
CanBlockFunction.Parent = ReplicatedStorage.Shared:WaitForChild("BasicCombat")

local BlockEvent = Instance.new("RemoteEvent")
BlockEvent.Name = "BlockEvent"
BlockEvent.Parent = ReplicatedStorage.Shared:WaitForChild("BasicCombat")

BlockEvent.OnServerEvent:Connect(function(player, action)
	local character = player.Character

	if action == "Start" then
		BlockModule.SetBlockHeld(character, true)
		BlockModule.TryStartBlocking(character)
	elseif action == "EmergencyStart" then
		BlockModule.SetBlockHeld(character, true)
		BlockModule.TryStartEmergencyBlock(character)
	elseif action == "End" then
		BlockModule.SetBlockHeld(character, false)
		BlockModule.StopBlocking(character)
	end
end)
