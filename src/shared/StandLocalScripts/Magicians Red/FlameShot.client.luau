local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local FlameShotEvent = replicatedStorage.Shared.BasicCombat.MagiciansRed:FindFirstChild("FlameShot")

-- Detect T press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.T then
		FlameShotEvent:InvokeServer() -- Request summon from the server
	end
end)
