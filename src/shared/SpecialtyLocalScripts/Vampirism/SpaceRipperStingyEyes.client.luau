local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")

local SpaceRipperStingyEyesEvent = replicatedStorage.Shared.BasicCombat.Vampirism:WaitForChild("SpaceRipperStingyEyes")

-- Detect B press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.B then
		SpaceRipperStingyEyesEvent:InvokeServer() -- Request summon from the server
	end
end)
