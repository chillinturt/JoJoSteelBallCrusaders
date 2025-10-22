local ReplicatedStorage = game:GetService("ReplicatedStorage")

local blockEvent = Instance.new("RemoteEvent")
blockEvent.Name = "BlockEvent"
blockEvent.Parent = ReplicatedStorage.Shared.BasicCombat

local BlockModule = require(game.ServerScriptService.BasicCombat:WaitForChild("BlockModule"))

blockEvent.OnServerEvent:Connect(function(player, isStarting)
	local character = player.Character
	local stun = character and character:FindFirstChild("Stun")

	-- Prevent blocking if stunned
	if stun then
		return
	end

	if isStarting then
		BlockModule.StartBlocking(character)
	else
		BlockModule.StopBlocking(character)
	end
end)
