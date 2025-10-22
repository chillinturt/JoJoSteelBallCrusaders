local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local LastStandEvent = replicatedStorage.Shared.BasicCombat.ThatHand:FindFirstChild("LastStand")

-- Detect T press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.X then
		LastStandEvent:InvokeServer() -- Request summon from the server
	end
end)
