local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")

local TimeStopEvent = replicatedStorage.Shared.BasicCombat.StarPurple:WaitForChild("TimeStop")

-- Detect X press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.X then
		TimeStopEvent:InvokeServer() -- Request summon from the server
	end
end)
