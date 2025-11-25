local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local ChopEvent = replicatedStorage.Shared.BasicCombat.KingCarmine:FindFirstChild("Chop")

-- Detect T press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.T then
		ChopEvent:InvokeServer() -- Request summon from the server
	end
end)
