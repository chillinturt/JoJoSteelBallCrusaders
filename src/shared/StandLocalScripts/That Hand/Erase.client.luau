local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local EraseEvent = replicatedStorage.Shared.BasicCombat.ThatHand:FindFirstChild("Erase")

-- Detect T press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.T then
		EraseEvent:InvokeServer() -- Request summon from the server
	end
end)
