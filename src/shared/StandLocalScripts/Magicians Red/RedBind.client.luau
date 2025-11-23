local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local RedBindEvent = replicatedStorage.Shared.BasicCombat.MagiciansRed:FindFirstChild("RedBind")

-- Detect T press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.R then
		RedBindEvent:InvokeServer() -- Request summon from the server
	end
end)
