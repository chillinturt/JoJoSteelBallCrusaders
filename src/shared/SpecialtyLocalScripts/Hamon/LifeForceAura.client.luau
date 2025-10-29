local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")

local LifeForceAuraEvent = replicatedStorage.Shared.BasicCombat.Hamon:WaitForChild("LifeForceAura")

-- Detect T press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.N then
		LifeForceAuraEvent:InvokeServer() -- Request summon from the server
	end
end)
