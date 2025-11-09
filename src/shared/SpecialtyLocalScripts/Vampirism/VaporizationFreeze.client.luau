local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")

local VaporizationFreezeEvent = replicatedStorage.Shared.BasicCombat.Vampirism:WaitForChild("VaporizationFreeze")

-- Detect T press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.C then
		VaporizationFreezeEvent:InvokeServer() -- Request summon from the server
	end
end)
