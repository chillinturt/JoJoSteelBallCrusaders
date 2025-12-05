local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local punchEvent = replicatedStorage.Shared.BasicCombat:FindFirstChild("PunchEvent")

-- Detect M1 (Left Mouse Button) press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		punchEvent:FireServer() -- Request summon from the server
	end
end)
