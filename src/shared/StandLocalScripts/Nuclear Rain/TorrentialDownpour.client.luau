local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local TorrentialDownpourEvent =
	replicatedStorage.Shared.BasicCombat.NuclearRain:FindFirstChild("TorrentialDownpourToggle")

-- Detect T press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.T then
		TorrentialDownpourEvent:InvokeServer() -- Request summon from the server
		print("toggled downpout on client")
	end
end)
