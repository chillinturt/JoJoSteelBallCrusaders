local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local HellfireEvent = replicatedStorage.Shared.BasicCombat.MagiciansRed:FindFirstChild("Hellfire")

-- Detect T press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.X then
		HellfireEvent:InvokeServer() -- Request summon from the server
	end
end)
