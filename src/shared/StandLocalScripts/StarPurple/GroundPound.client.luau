local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")

local groundPoundEvent = replicatedStorage.Shared.BasicCombat.StarPurple:WaitForChild("GroundPound")

-- Detect Z press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Z then
		groundPoundEvent:InvokeServer() -- Request summon from the server
	end
end)
