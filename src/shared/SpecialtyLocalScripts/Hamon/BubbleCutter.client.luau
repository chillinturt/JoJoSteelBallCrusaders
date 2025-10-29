local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")

local BubbleCutterEvent = replicatedStorage.Shared.BasicCombat.Hamon:WaitForChild("BubbleCutter")

-- Detect T press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.B then
		BubbleCutterEvent:InvokeServer() -- Request summon from the server
	end
end)
