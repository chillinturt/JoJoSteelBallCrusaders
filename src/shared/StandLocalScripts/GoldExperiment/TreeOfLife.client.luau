local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local TreeOfLifeEvent = replicatedStorage.Shared.BasicCombat.GoldExperiment:FindFirstChild("TreeOfLife")

-- Detect T press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.R then
		TreeOfLifeEvent:InvokeServer() -- Request summon from the server
	end
end)
