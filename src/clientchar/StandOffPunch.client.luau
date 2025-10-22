local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local standOffPunchEvent = replicatedStorage.Shared.BasicCombat:FindFirstChild("StandOffPunch")

-- Detect M1 (Left Mouse Button) press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		standOffPunchEvent:InvokeServer() -- Request summon from the server
	end
end)
