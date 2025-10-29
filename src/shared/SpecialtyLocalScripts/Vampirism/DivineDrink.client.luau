local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")

local DivineDrinkEvent = replicatedStorage.Shared.BasicCombat.Vampirism:WaitForChild("DivineDrink")

-- Detect T press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.V then
		DivineDrinkEvent:InvokeServer() -- Request summon from the server
	end
end)
