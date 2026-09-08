local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local players = game:GetService("Players")
local summonEvent = replicatedStorage.Shared.BasicCombat:WaitForChild("SummonEvent")

local player = players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Detect "Q" key press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Q then
		if humanoid.SeatPart then
			return
		end
		summonEvent:FireServer() -- Request summon from the server
	end
end)
