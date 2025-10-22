local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local teleportEvent = replicatedStorage.Shared.BasicCombat.KingCarmine:FindFirstChild("Teleport")
local RequestTeleportTarget = replicatedStorage.Shared.BasicCombat.KingCarmine:FindFirstChild("RequestTeleportTarget")

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Detect T press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Z then
		teleportEvent:InvokeServer() -- Request summon from the server
	end
end)

RequestTeleportTarget.OnClientInvoke = function()
	return mouse.Hit.Position
end
