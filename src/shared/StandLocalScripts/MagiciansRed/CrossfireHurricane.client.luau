local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local CrossfireHurricaneEvent = replicatedStorage.Shared.BasicCombat.MagiciansRed:FindFirstChild("CrossfireHurricane")

-- Detect T press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Z then
		CrossfireHurricaneEvent:InvokeServer() -- Request summon from the server
	end
end)
