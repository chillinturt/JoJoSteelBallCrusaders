local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")

local starFingerEvent = replicatedStorage.Shared.BasicCombat.StarPurple:WaitForChild("StarFinger")

-- Detect T press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.T then
		starFingerEvent:InvokeServer() -- Request summon from the server
	end
end)
