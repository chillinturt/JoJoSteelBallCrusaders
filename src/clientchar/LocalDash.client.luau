-- client: LocalScript

local replicatedStorage = game:GetService("ReplicatedStorage")
local dashEvent = replicatedStorage.Shared.BasicCombat:WaitForChild("DashEvent")
local userInputService = game:GetService("UserInputService")

-- Track key states
local keysDown = { W = false, A = false, S = false, D = false }

local function getDashLabel()
	-- prefer left/right if held (since you asked for 'if holding D then dash right')
	if keysDown.A and not keysDown.D then
		return "Left"
	elseif keysDown.D and not keysDown.A then
		return "Right"
	elseif keysDown.W and not keysDown.S then
		return "Forward"
	elseif keysDown.S and not keysDown.W then
		return "Backward"
	else
		return "Forward" -- default
	end
end

-- Input handling
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.W then
		keysDown.W = true
	elseif input.KeyCode == Enum.KeyCode.A then
		keysDown.A = true
	elseif input.KeyCode == Enum.KeyCode.S then
		keysDown.S = true
	elseif input.KeyCode == Enum.KeyCode.D then
		keysDown.D = true
	elseif input.KeyCode == Enum.KeyCode.LeftShift then
		local label = getDashLabel()
		-- Fire to server: label and camera forward (flattened)
		dashEvent:FireServer(label)
	end
end)

userInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.W then
		keysDown.W = false
	elseif input.KeyCode == Enum.KeyCode.A then
		keysDown.A = false
	elseif input.KeyCode == Enum.KeyCode.S then
		keysDown.S = false
	elseif input.KeyCode == Enum.KeyCode.D then
		keysDown.D = false
	end
end)
