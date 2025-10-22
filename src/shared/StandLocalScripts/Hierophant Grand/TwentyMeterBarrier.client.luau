local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local twentyMeterBarrierEvent =
	replicatedStorage.Shared.BasicCombat.HierophantGrand:FindFirstChild("TwentyMeterBarrier")

-- detect x press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.X then
		twentyMeterBarrierEvent:InvokeServer() -- Request summon from the server
		print("20 meter barrier Event fired from client")
	end
end)
