-- LocalScript inside PlayerScripts or StarterPlayerScripts

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local doubleJumpEvent = ReplicatedStorage.Shared.BasicCombat:WaitForChild("DoubleJumpEvent")

-- Listen for jump input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.Gamepad1 then
		if input.KeyCode == Enum.KeyCode.Space then
			-- Only fire double jump if in the air
			doubleJumpEvent:FireServer()
		end
	end
end)
