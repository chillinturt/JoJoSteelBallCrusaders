local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")

local BloodRushEvent = replicatedStorage.Shared.BasicCombat.Vampirism:WaitForChild("BloodRush")

-- Detect B press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.N then
		BloodRushEvent:InvokeServer() -- Request summon from the server
	end
end)
