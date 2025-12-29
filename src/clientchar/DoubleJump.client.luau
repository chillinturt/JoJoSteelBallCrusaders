-- LocalScript inside StarterPlayerScripts

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local doubleJumpEvent = ReplicatedStorage.Shared.BasicCombat:WaitForChild("DoubleJumpEvent")

-- Tracks whether the jump input is currently held down
local jumpPressed = false

-- Fires when jump is requested (Space, mobile button, gamepad)
UserInputService.JumpRequest:Connect(function()
	if not jumpPressed then
		jumpPressed = true
		doubleJumpEvent:FireServer()
	end
end)

-- Reset jumpPressed when the jump button is released
UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Space then
		jumpPressed = false
	elseif input.UserInputType == Enum.UserInputType.Touch then
		jumpPressed = false
	elseif input.UserInputType == Enum.UserInputType.Gamepad1 then
		-- Optional: reset for gamepad jump buttons
		jumpPressed = false
	end
end)
