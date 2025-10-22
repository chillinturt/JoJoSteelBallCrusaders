local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local summonEvent = replicatedStorage.Shared.BasicCombat:WaitForChild("SummonEvent")

-- Detect "Q" key press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Q then
		summonEvent:FireServer() -- Request summon from the server
		print("Summon Event fired from client")
	end
end)
