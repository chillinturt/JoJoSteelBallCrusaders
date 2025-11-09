local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local EagleStrikeEvent = replicatedStorage.Shared.BasicCombat.GoldExperiment:WaitForChild("EagleStrike")

-- Detect T press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Z then
		EagleStrikeEvent:InvokeServer() -- Request summon from the server
	end
end)
