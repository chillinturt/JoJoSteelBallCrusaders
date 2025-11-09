local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local HeavyRaindropEvent = replicatedStorage.Shared.BasicCombat.NuclearRain:FindFirstChild("HeavyRaindrop")

-- Detect T press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.R then
		HeavyRaindropEvent:InvokeServer() -- Request summon from the server
		print("toggled downpout on client")
	end
end)
