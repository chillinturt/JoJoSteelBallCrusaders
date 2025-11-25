local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local barrierEvent = replicatedStorage.Shared.BasicCombat.HierophantGrand:FindFirstChild("EmeraldBarrier")

-- Detect M1 (Left Mouse Button) press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Z then
		barrierEvent:InvokeServer() -- Request summon from the server
		print("Barrier Event fired from client")
	end
end)
