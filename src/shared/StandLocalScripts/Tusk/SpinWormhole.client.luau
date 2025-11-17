local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local SpinWormholeEvent = replicatedStorage.Shared.BasicCombat.Tusk:FindFirstChild("SpinWormhole")

-- Detect T press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Z then
		SpinWormholeEvent:InvokeServer() -- Request summon from the server
	end
end)
