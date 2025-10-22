local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local machOraEvent = replicatedStorage.Shared.BasicCombat.StarPurple:WaitForChild("MachOra")
local machOraEvent2 = replicatedStorage.Shared.BasicCombat.StarPurple:WaitForChild("MachOra2")

-- Detect "R" key press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.R then
		machOraEvent:InvokeServer() -- Request summon from the server
		machOraEvent2:InvokeServer() -- Request summon from the server
	end
end)
