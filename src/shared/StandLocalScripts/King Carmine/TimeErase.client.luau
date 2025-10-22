local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local TimeEraseEvent = replicatedStorage.Shared.BasicCombat.KingCarmine:FindFirstChild("TimeErase")

-- Detect T press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.X then
		TimeEraseEvent:InvokeServer() -- Request summon from the server
	end
end)
