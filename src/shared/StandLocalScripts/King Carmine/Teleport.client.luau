local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local teleportEvent = replicatedStorage.Shared.BasicCombat.KingCarmine:FindFirstChild("Teleport")
local RequestTeleportTarget = replicatedStorage.Shared.BasicCombat.KingCarmine:FindFirstChild("RequestTeleportTarget")

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
	local camera = workspace.CurrentCamera
	if not camera then
		warn("No camera found on client")
		return Vector3.new(0, 0, 0)
	end

	-- Just return the camera's facing direction
	return camera.CFrame.LookVector
end
