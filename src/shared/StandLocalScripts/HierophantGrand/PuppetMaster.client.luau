local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local PuppetMasterEvent = replicatedStorage.Shared.BasicCombat.HierophantGrand:FindFirstChild("PuppetMaster")

-- Detect M1 (Left Mouse Button) press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.T then
		PuppetMasterEvent:InvokeServer() -- Request summon from the server
		print("Puppet master Event fired from client")
	end
end)
