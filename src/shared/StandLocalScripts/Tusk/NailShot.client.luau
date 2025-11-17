local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local NailShotEvent = replicatedStorage.Shared.BasicCombat.Tusk:FindFirstChild("NailShot")

-- Detect T press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.T then
		NailShotEvent:InvokeServer() -- Request summon from the server
	end
end)
