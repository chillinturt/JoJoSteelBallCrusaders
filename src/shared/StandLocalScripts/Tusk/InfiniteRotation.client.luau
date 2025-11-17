local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local InfiniteRotationEvent = replicatedStorage.Shared.BasicCombat.Tusk:FindFirstChild("InfiniteRotation")

-- Detect T press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.X then
		InfiniteRotationEvent:InvokeServer() -- Request summon from the server
	end
end)
