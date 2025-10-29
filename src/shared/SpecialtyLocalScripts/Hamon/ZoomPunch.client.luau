local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")

local ZoomPunchEvent = replicatedStorage.Shared.BasicCombat.Hamon:WaitForChild("ZoomPunch")

-- Detect T press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.V then
		ZoomPunchEvent:InvokeServer() -- Request summon from the server
	end
end)
