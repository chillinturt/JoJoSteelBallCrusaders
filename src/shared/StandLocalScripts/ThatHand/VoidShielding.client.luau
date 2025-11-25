local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local VoidShieldingEvent = replicatedStorage.Shared.BasicCombat.ThatHand:FindFirstChild("VoidShielding")

-- Detect T press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.R then
		VoidShieldingEvent:InvokeServer() -- Request summon from the server
	end
end)
