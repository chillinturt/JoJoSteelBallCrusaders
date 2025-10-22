-- LocalScript in StarterPlayerScripts
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local AirMovementEvent = ReplicatedStorage.BasicCombat:WaitForChild("AirMovementInput")

local inputState = { Left = false, Right = false, Forward = false, Backward = false }

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.A then
		inputState.Left = true
	end
	if input.KeyCode == Enum.KeyCode.D then
		inputState.Right = true
	end
	if input.KeyCode == Enum.KeyCode.W then
		inputState.Forward = true
	end
	if input.KeyCode == Enum.KeyCode.S then
		inputState.Backward = true
	end
	AirMovementEvent:FireServer(inputState)
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.A then
		inputState.Left = false
	end
	if input.KeyCode == Enum.KeyCode.D then
		inputState.Right = false
	end
	if input.KeyCode == Enum.KeyCode.W then
		inputState.Forward = false
	end
	if input.KeyCode == Enum.KeyCode.S then
		inputState.Backward = false
	end
	AirMovementEvent:FireServer(inputState)
end)
