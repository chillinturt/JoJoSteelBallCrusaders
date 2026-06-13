local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local blockEvent = ReplicatedStorage.Shared.BasicCombat:WaitForChild("BlockEvent")

-- ===== CONFIG =====
local DOUBLE_TAP_WINDOW = 0.25 -- seconds
local lastBlockPress = 0

-- === Input Hooks ===
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.KeyCode ~= Enum.KeyCode.F then
		return
	end

	local now = os.clock()
	local isDoubleTap = (now - lastBlockPress) <= DOUBLE_TAP_WINDOW
	lastBlockPress = now

	-- ✅ Always express normal block intent
	blockEvent:FireServer("Start")

	-- 🚨 Emergency is ADDITIVE, not exclusive
	if isDoubleTap then
		blockEvent:FireServer("EmergencyStart")
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.F then
		blockEvent:FireServer("End")
	end
end)
